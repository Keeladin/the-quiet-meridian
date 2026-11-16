#!/usr/bin/env python3
"""Audit material Foley provenance, decoded masters and runtime references.

These objective checks do not claim human listening approval.
"""
from pathlib import Path
import array
import hashlib
import json
import math
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / 'assets/audio/foley/manifest.json').read_text())
catalog = json.loads((ROOT / 'content/audio-score.json').read_text())
failures = []
checks = 0


def check(ok, label):
    global checks
    checks += 1
    if not ok:
        failures.append(label)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def local(path):
    relative = Path(path.removeprefix('res://'))
    check(not relative.is_absolute() and '..' not in relative.parts,
          f'local project path: {path}')
    return ROOT / relative


check((ROOT / 'assets/audio/foley/LICENSES.txt').is_file(), 'packaged Foley attribution')
sources = {source['id']: source for source in manifest['sources']}
assets = {asset['path']: asset for asset in manifest['assets']}
check(len(sources) >= 18, 'substantive material source library')
check(len(assets) >= 36, 'material effects have distinct alternatives')
check(len(manifest['cues']) >= 18, 'material cue identities')
for pack in manifest['packs']:
    check('CC0' in pack['license'], f"CC0 declaration: {pack['id']}")
    check(pack['source_url'].startswith('https://'), f"creator source: {pack['id']}")
    check(len(pack['archive_sha256']) == 64, f"download identity: {pack['id']}")
    check(local(pack['license_record']).is_file(), f"retained declaration: {pack['id']}")
for source_id, source in sources.items():
    path = local(source['path'])
    check(path.is_file(), f'source recording present: {source_id}')
    if path.is_file():
        check(digest(path) == source['sha256'], f'source integrity: {source_id}')
    check('CC0' in source['license'], f'source license: {source_id}')
    check(bool(source['creator']) and bool(source['member']), f'creator and archive member: {source_id}')
for path, asset in assets.items():
    runtime, master = local(path), local(asset['master'])
    check(runtime.is_file() and master.is_file(), f'local runtime and master: {path}')
    check(bool(asset['source_ids']) and all(s in sources for s in asset['source_ids']), f'traceable layers: {path}')
    check(bool(asset['recipe']), f'reproducible processing record: {path}')
    if not runtime.is_file() or not master.is_file():
        continue
    check(runtime.read_bytes()[:4] == b'OggS', f'Ogg runtime: {path}')
    check(digest(runtime) == asset['sha256'], f'runtime integrity: {path}')
    check(digest(master) == asset['master_sha256'], f'master integrity: {path}')
    with wave.open(str(master), 'rb') as reader:
        rate, channels, frames = reader.getframerate(), reader.getnchannels(), reader.getnframes()
        check(rate == 32000 and channels == 2 and reader.getsampwidth() == 2, f'portable stereo PCM: {path}')
        check(abs(frames / rate - asset['duration_seconds']) < .001, f'actual duration: {path}')
        check(.04 <= frames / rate <= 8, f'bounded interaction length: {path}')
        samples = array.array('h', reader.readframes(frames))
        if sys.byteorder != 'little':
            samples.byteswap()
        peak = max(abs(v) for v in samples) / 32768
        rms = math.sqrt(sum(v * v for v in samples) / len(samples)) / 32768
        check(.02 < peak < .9 and rms > .001, f'audible with headroom: {path}')
        check(max(abs(v) for v in samples[:2] + samples[-2:]) <= 4, f'click-free edges: {path}')
        check(abs(20 * math.log10(peak) - asset['peak_dbfs']) < .08, f'peak measurement: {path}')
        check(abs(20 * math.log10(rms) - asset['rms_dbfs']) < .08, f'RMS measurement: {path}')
for name, cue in manifest['cues'].items():
    check(catalog['sfx'].get(name) == cue, f'catalog matches production cue: {name}')
    variants = cue['variants']
    check(len(set(variants)) >= 2 and cue['path'] in variants, f'repeat variation: {name}')
    check(all(p.removeprefix('res://') in assets for p in variants), f'provenance covers every variant: {name}')
    hashes = [assets[p.removeprefix('res://')]['sha256'] for p in variants]
    check(len(hashes) == len(set(hashes)), f'variants are different audio: {name}')
    check(-40 <= cue['gain_db'] <= 0, f'conservative level: {name}')
    check(.9 <= cue['pitch_range'][0] <= cue['pitch_range'][1] <= 1.1, f'bounded pitch: {name}')
    check(0 <= cue['cooldown_seconds'] <= 1, f'bounded cooldown: {name}')
if manifest.get('generator'):
    check(digest(local(manifest['generator'])) == manifest['generator_sha256'], 'Foley build source integrity')
if failures:
    for message in failures:
        print('FOLEY AUDIT FAIL:', message)
    sys.exit(1)
print(f'FOLEY_AUDIT_OK: {checks} checks; {len(assets)} effects; {len(sources)} retained CC0 sources; listening acceptance separate')
