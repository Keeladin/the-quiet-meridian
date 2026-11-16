#!/usr/bin/env python3
"""Build the exact spoken script and a source-exact OpenAI GPT Live casting plan; no network."""
import json, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
existing_path = ROOT / 'content/voice-script.json'
if existing_path.exists():
 existing = json.loads(existing_path.read_text())
 if any(line.get('path') or line.get('status') != 'awaiting_generation_approval'
        for line in existing.get('lines', {}).values()):
  raise SystemExit('Refusing to overwrite production voice records. Reconcile changed source text with the existing manifest explicitly.')
game=json.loads((ROOT/'content/game.json').read_text())
dialogue=json.loads((ROOT/'content/dialogues.json').read_text())
cast={
 'iona':('willow','Thoughtful conservator; warm precise questions; restrained emotion, never a trailer voice.'),
 'mara':('quartz','Measured archivist; careful consonants, fatigue giving way to relief.'),
 'rowan':('stone','Weathered lockkeeper; low and unhurried, shame held inside plain speech.'),
 'nadi':('delta','Practical ferryperson; grounded warmth, wry wit, firmness about what she witnessed.'),
 'sera':('gleam','Young printer; clear energetic thought, conviction without shouting.'),
 'elian':('vesper','Older engineer; hesitant admissions, restrained regret, technical precision.'),
 'ada':('marin','Older astronomer; dry wit, patient authority and compassion.'),
 'rusk':('meridian','Courteous magistrate; polished authority masking defensiveness.'),
 'tomas':('ripple','Remembered gatekeeper; grounded quiet assurance, no invented present-day testimony.')}
lines={}
def add(id,speaker,text,context,delivery=''):
 spoken=text
 lines[id]={'speaker':speaker,'text':text,'spoken_text':spoken,'voice':cast[speaker][0], 'direction':cast[speaker][1], 'context':context,'path':'','duration':0.0,'subtitles':[], 'status':'awaiting_generation_approval','text_sha256':hashlib.sha256(text.encode()).hexdigest()}
add('narration_opening','iona',game['intro'],'Opening letter and arrival')
for c in game['chapters']:
 add(c['id']+'_intro','iona',c['intro'],'Chapter opening')
 add(c['id']+'_closing','iona',c['closing'],'Chapter conclusion')
add('narration_ending','iona',game['ending'],'Final narrative conclusion')
for c in dialogue['conversations']:
 add(c['id']+'_greeting','iona',c['greeting'],'Conversation scene description')
 for i,t in enumerate(c['topics']):
  add(f"{c['id']}_q{i}",'iona',t['question'],'Player question')
  add(f"{c['id']}_r{i}",c['character'],t['reply'],'Character reply')
script={'version':1,'casting':{k:{'voice':v[0],'direction':v[1]} for k,v in cast.items()},'provider':'OpenAI API','model':'gpt-live-1','rate':'USD 0.05 per active session minute, billed per second; only three audition takes authorized separately','generation_scope':'See content/voice-audition.json; full 98-clip production is not authorized','lines':lines}
(ROOT/'content/voice-script.json').write_text(json.dumps(script,ensure_ascii=False,indent=2)+'\n')
(ROOT/'assets/audio/voice').mkdir(parents=True,exist_ok=True)
print(json.dumps({'clips':len(lines),'characters':sum(len(x['spoken_text']) for x in lines.values()),'full_batch_authorized':False,'speakers':sorted(set(x['speaker'] for x in lines.values()))},indent=2))
