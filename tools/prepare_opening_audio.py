#!/usr/bin/env python3
"""Prepare only the owner's selected recordings; preserve the purchased masters.

Requires numpy, scipy, soundfile and imageio-ffmpeg (existing audio environment).
Use --library-root to restore from a different licensed copy of the collection.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

import imageio_ffmpeg
import numpy as np
from scipy.signal import resample_poly, butter, sosfilt
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'assets/audio/licensed-opening'
RATE = 48000
SETTINGS = {
    'harbour_water': ('loop', -18, 0, 0),
    'rain_on_the_office': ('loop', -4, 0, 0),
    'moored_boat_and_ropes': ('periodic', -24, 13, 23),
    'office_room_tone': ('loop', -23, 0, 0),
    'office_clock': ('periodic', -29, 1, 1),
    'building_movement': ('periodic', -28, 22, 39),
    'object_found': ('event', -12, 0, 0),
    'symbol_understood': ('event', -18, 0, 0),
    'receipt_recovered': ('event', -13, 0, 0),
    'search_completed': ('event', -16, 0, 0),
    'hint_revealed': ('event', -19, 0, 0),
    'menu_interaction': ('event', -23, 0, 0),
    'journal_updated': ('event', -21, 0, 0),
}


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--library-root', type=Path)
    args = parser.parse_args()
    selected = json.loads((ROOT / 'docs/audio-selection/requests.json').read_text())
    requests = {r['id']: r for r in selected['requests']}
    prior_path = ROOT / 'docs/audio-selection/opening-provenance.json'
    prior = json.loads(prior_path.read_text())['assets'] if prior_path.exists() else {}
    sources = {}
    for cue in SETTINGS:
        request = requests[cue]
        if request['selected_by'] != 'Jaco' or len(request['selected_files']) != 1:
            raise ValueError('Expected one owner-approved file for ' + cue)
        source = Path(request['selected_files'][0])
        if args.library_root:
            matches = [p for p in args.library_root.rglob(source.name) if p.is_file()]
            if len(matches) != 1:
                raise ValueError('Expected one matching licensed master for ' + cue)
            source = matches[0]
        if not source.is_file():
            raise FileNotFoundError(f'{cue}: restore from your licensed library using --library-root')
        if cue in prior and sha(source) != prior[cue]['source_sha256']:
            raise ValueError('Source differs from the approved master: ' + cue)
        sources[cue] = source
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = {'collection': 'Gamemaster Audio Pro Sound Collection v1.3, 24-bit / 96 kHz',
                'selected_by': 'Jaco', 'selected_date': '2026-11-14',
                'license_url': 'https://gamemasteraudio.com/wp-content/uploads/2020/01/Gamemaster-Audio-End-User-License-Agreement.pdf',
                'distribution': 'Licensed recordings embedded in the game; excluded from shareable source archives. No AI training or external upload.',
                'assets': {}}
    runtime = {'version': 1, 'music': {'path': 'res://assets/audio/score/ch1.ogg', 'volume_db': -30}, 'cues': {}}
    with tempfile.TemporaryDirectory() as temp:
        for cue, (kind, volume, minimum, maximum) in SETTINGS.items():
            source = sources[cue]
            info = sf.info(source)
            samples, rate = sf.read(source, always_2d=True, dtype='float64')
            divisor = int(np.gcd(rate, RATE))
            samples = resample_poly(samples, RATE // divisor, rate // divisor)
            recipe = ['Resample with polyphase anti-alias filter to 48 kHz; retain stereo']
            if kind == 'loop':
                samples = sosfilt(butter(2, 6000, fs=RATE, output='sos'), samples, axis=0)
                # Wrap the final 40 ms into the beginning, eliminating a hard seam.
                n = min(int(.04 * RATE), len(samples) // 4)
                ramp = np.linspace(0, 1, n)[:, None]
                samples[:n] = samples[-n:] * (1 - ramp) + samples[:n] * ramp
                samples = samples[:-n]
                recipe += ['6 kHz gentle low-pass for distance', '40 ms wrap crossfade at loop seam']
            else:
                n = min(int(.002 * RATE), len(samples) // 4)
                samples[:n] *= np.linspace(0, 1, n)[:, None]
                samples[-n:] *= np.linspace(1, 0, n)[:, None]
                recipe += ['2 ms edge fades; retain original timing and tail']
            peak = float(np.max(np.abs(samples)))
            if not np.isfinite(samples).all() or peak < 1e-7:
                raise ValueError('Invalid or silent master: ' + cue)
            gain = 10 ** (-3 / 20) / peak
            samples *= gain
            recipe += [f'Peak gain {20*np.log10(gain):.3f} dB, target -3 dBFS', 'Ogg Vorbis quality 6, 48 kHz stereo']
            master = Path(temp) / (cue + '.wav')
            sf.write(master, samples, RATE, subtype='PCM_24')
            target = DEST / (cue + '.ogg')
            subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-v', 'error', '-y', '-i', str(master),
                            '-c:a', 'libvorbis', '-q:a', '6', str(target)], check=True)
            decoded, decoded_rate = sf.read(target, always_2d=True)
            decoded_peak = float(np.max(np.abs(decoded)))
            if decoded_rate != RATE or decoded_peak >= 1 or not np.isfinite(decoded).all():
                raise ValueError('Invalid or clipping output: ' + cue)
            manifest['assets'][cue] = {
                'source_file': str(source), 'source_sha256': sha(source),
                'source_rate': rate, 'source_subtype': info.subtype,
                'source_seconds': info.duration, 'processing': recipe,
                'runtime_file': str(target.relative_to(ROOT)), 'runtime_sha256': sha(target),
                'runtime_rate': decoded_rate, 'runtime_seconds': len(decoded)/decoded_rate,
                'runtime_peak_dbfs': round(float(20*np.log10(decoded_peak)), 3),
                'runtime_rms_dbfs': round(float(20*np.log10(np.sqrt(np.mean(decoded**2)))), 3),
                'listening_status': 'Owner selected source; prepared game mix awaits owner listening review'}
            runtime['cues'][cue] = {'path': 'res://' + str(target.relative_to(ROOT)), 'kind': kind,
                                    'volume_db': volume, 'interval_min': minimum, 'interval_max': maximum}
            print(cue, f'{len(decoded)/RATE:.3f}s', f'{target.stat().st_size:,} bytes')
    prior_path.write_text(json.dumps(manifest, indent=2) + '\n')
    (ROOT / 'content/hidden-object-audio.json').write_text(json.dumps(runtime, indent=2) + '\n')


if __name__ == '__main__':
    main()
