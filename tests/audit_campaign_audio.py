#!/usr/bin/env python3
"""Verify scene choices, licensed provenance, encoded file identities and mix records."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1]
m=json.loads((R/'docs/audio-selection/campaign-provenance.json').read_text());p=json.loads((R/'docs/audio-selection/campaign-plan.json').read_text());c=json.loads((R/'content/audio-score.json').read_text());g=json.loads((R/'content/game.json').read_text());o=json.loads((R/'docs/audio-selection/opening-provenance.json').read_text())
checks=0
def check(x,msg):
 global checks
 checks+=1
 if not x:raise AssertionError(msg)
def sha(path):
 with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
check(set(m['rooms'])==set(p['rooms'])=={l['id'] for l in g['locations']},'one atmosphere per campaign room')
check(sha(R/m['generator'])==m['generator_sha256'],'preparation recipe identity')
check(sha(R/'docs/audio-selection/campaign-plan.json')==m['plan_sha256'],'authored mix plan identity')
check((R/m['license_record']).is_file(),'retained license review')
check(len(m['sources'])==33,'33 selected licensed source recordings')
for key,s in m['sources'].items():
 check(len(s['source_sha256'])==64 and s['role'] and s['selected_by'],'source identity and selection rationale '+key)
 if s.get('prepared_input'):check(sha(R/s['prepared_input'])==s['prepared_sha256'],'owner preparation unchanged '+key)
for id,a in m['assets'].items():
 f=R/a['path'];check(f.is_file() and f.read_bytes()[:4]==b'OggS','local Ogg '+id)
 check(sha(f)==a['sha256'],'encoded integrity '+id)
 check(a['sample_rate']==48000 and a['channels']==2,'stereo 48 kHz '+id)
 check(-90<a['rms_dbfs']<-10 and a['peak_dbfs']<-2,'non-silent conservative signal '+id)
 check(set(a['source_ids'])<=set(m['sources']) and bool(a['recipe']),'traceable preparation '+id)
 if a['kind']=='ambience':check(89<a['duration_seconds']<91 and a['seam_delta']<.08,'long loop with checked seam '+id)
for room,cue in m['rooms'].items():
 check(c['location_ambience'][room]==cue and c['ambience'][cue]['path']=='res://'+m['assets'][cue]['path'],'runtime room mapping '+room)
paths={a['path'] for a in m['assets'].values()}|{a['runtime_file'] for a in o['assets'].values()}
for cue,entry in m['cues'].items():
 check(c['sfx'][cue]==entry,'runtime effect matches authored choice '+cue)
 check(all(x.removeprefix('res://') in paths for x in entry.get('variants',[entry['path']])),'every effect variant licensed and traceable '+cue)
check(p['rooms']['ch1_l1']['beds'][0]['gain_db'] == -18+12.396 and p['rooms']['ch1_l1']['beds'][1]['gain_db']==-4+12.396,'approved quieter ocean and audible rain preserved')
print('CAMPAIGN_AUDIO_AUDIT_OK:',checks,'checks;',len(m['rooms']),'room mixes;',len(m['sources']),'licensed sources; subjective listening acceptance separate')
