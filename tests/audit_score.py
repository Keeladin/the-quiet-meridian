#!/usr/bin/env python3
"""Validate delivered score audio against source events and actual PCM masters.

Uses Python's standard library; the synthesizer's build dependencies are not
needed to verify packages. This is signal/structure evidence, not a listening
panel, an orchestral-performance claim, or subjective mix approval.
"""
from pathlib import Path
import array
import hashlib
import json
import math
import sys
import wave

ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'assets/audio/score/manifest.json').read_text())
config=json.loads((ROOT/'content/audio-score.json').read_text())
failures=[]
checks=0

def check(condition,message):
    global checks
    checks+=1
    if not condition: failures.append(message)

def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()

check(set(config['music'])==set(['title','ch1','ch2','ch3','ch4','ch5','ch6','tension','resolution']),'complete music set')
check(len(config['ambience'])>=6,'six independent ambience layers')
check(len(config['sfx'])>=12,'twelve sound-effect identities')
check(len(config['location_ambience'])==36,'ambience covers all locations')
for location,key in config['location_ambience'].items():check(key in config['ambience'],f'{location} references available ambience')
by_path={a['path']:a for a in manifest['assets']}
if config.get('foley_manifest'):
    foley=json.loads((ROOT/config['foley_manifest'].removeprefix('res://')).read_text())
    by_path.update({a['path']:a for a in foley['assets']})
if config.get('campaign_audio_manifest'):
    campaign=json.loads((ROOT/config['campaign_audio_manifest'].removeprefix('res://')).read_text())
    by_path.update({a['path']:a for a in campaign['assets'].values()})
    opening=json.loads((ROOT/'docs/audio-selection/opening-provenance.json').read_text())
    by_path.update({a['runtime_file']:a for a in opening['assets'].values()})
if config.get('selected_music_manifest'):
    selected=json.loads((ROOT/config['selected_music_manifest'].removeprefix('res://')).read_text())
    for asset in selected['assets']:
        path=ROOT/asset['path']
        by_path[asset['path']]=asset
        check(path.is_file(),f"selected music present: {asset['path']}")
        if path.is_file():check(digest(path)==asset['sha256'],f"selected music integrity: {asset['path']}")
    identities={(entry.get('playback_id'),entry['path'],entry.get('loop',True)) for entry in config['music'].values()}
    check(len(identities)==1 and next(iter(identities))[0], 'selected background music uses one continuous playback identity')
check(digest(ROOT/manifest['generator'])==manifest['generator_sha256'],'composition/synthesis source integrity')
for kind in ['music','ambience','sfx']:
    for name,entry in config[kind].items():
        relative=entry['path'].removeprefix('res://')
        check(relative in by_path,f'{name} has provenance')
        check((ROOT/relative).is_file(),f'{name} has local runtime file')
        check(entry.get('gain_db',0)<=0,f'{name} has conservative mixing gain')
        if kind=='music':check(entry['duration_seconds']>=120,f'{name} is developed beyond the old short loops')

actual_totals={}
for asset in manifest['assets']:
    path=ROOT/asset['path'];master=ROOT/asset['master']
    check(path.is_file(),f"runtime asset present: {asset['path']}")
    check(master.is_file(),f"original PCM present: {asset['master']}")
    if not path.is_file() or not master.is_file():continue
    check(digest(path)==asset['sha256'],f"runtime integrity: {asset['path']}")
    check(digest(master)==asset['master_sha256'],f"master integrity: {asset['master']}")
    check(path.read_bytes()[:4]==b'OggS',f"runtime container valid: {asset['path']}")
    with wave.open(str(master),'rb') as reader:
        rate=reader.getframerate();channels=reader.getnchannels();frames=reader.getnframes()
        check(rate==32000 and channels==2 and reader.getsampwidth()==2,f"stereo PCM format: {asset['master']}")
        duration=frames/rate
        check(abs(duration-asset['duration_seconds'])<.001,f"duration agrees with actual file: {asset['master']}")
        samples=array.array('h',reader.readframes(frames))
        if sys.byteorder!='little':samples.byteswap()
        maximum=max(abs(v) for v in samples)
        # Sample complete signal every eight frames for RMS; maxima inspect every sample.
        selection=samples[::16]
        rms=math.sqrt(sum(v*v for v in selection)/len(selection))/32768
        check(800<maximum<31000,f"audible headroom without clipping: {asset['master']}")
        check(.002<rms<.14,f"non-silent moderate signal: {asset['master']}")
        check(max(abs(v) for v in samples[:2]+samples[-2:])<=4,f"zero-edge click prevention: {asset['master']}")
        actual_totals[asset['kind']]=actual_totals.get(asset['kind'],0)+duration
        if asset['kind']=='music':
            check(digest(ROOT/asset['events'])==asset['events_sha256'],f"authored event score integrity: {asset['path']}")
            events=json.loads((ROOT/asset['events']).read_text())
            check(len(events['form'])>=6,f"musical form: {asset['path']}")
            check(len(events['note_events'])>=300,f"developed written score: {asset['path']}")
            check(len(set(e['instrument'] for e in events['note_events']))>=4,f"instrumental variety: {asset['path']}")
            check(max(e['start'] for e in events['note_events'])>duration*.90,f"score extends throughout cue: {asset['path']}")
            # Ensure file is not one short signal repeated or merely extended by silence.
            windows=[]
            for start in (16,32,48,64,80,96):
                segment=samples[int(start*rate*channels):int((start+8)*rate*channels)]
                windows.append(hashlib.sha256(segment.tobytes()).hexdigest())
                sparse=segment[::32]
                energy=math.sqrt(sum(v*v for v in sparse)/len(sparse))/32768
                check(energy>.007,f"active scored section {start}s: {asset['path']}")
            check(len(set(windows))==len(windows),f"non-repeated section waveforms: {asset['path']}")
            # Phrase-aware score timing never needs a MIDI player at runtime.
            check(all(e['start']>=0 and e['duration']>0 and 21<=e['midi']<=108 for e in events['note_events']),f"valid score event ranges: {asset['path']}")
if failures:
    for message in failures:print('SCORE AUDIT FAIL:',message)
    sys.exit(1)
print('SCORE_AUDIT_OK:',checks,'checks;',len(config['music']),'music cue routes;',len({e['path'] for e in config['music'].values()}),'active music tracks;',round(actual_totals.get('music',0),1),'seconds of preserved original score;',len(config['ambience']),'ambiences;',len(config['sfx']),'effects; no subjective quality claim')
