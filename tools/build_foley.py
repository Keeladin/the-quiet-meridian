#!/usr/bin/env python3
"""Build tactile Foley derivatives from retained CC0 source recordings.

Rebuild offline: work/av-env/bin/python tools/build_foley.py
First import only: add --import-archives work/sfx-research. No network requests,
provider calls, credentials or system configuration are used. Source originals
remain unmodified. Runtime Ogg and PCM masters are deterministic with the pinned
score toolchain (see tools/score-requirements.txt).
"""
from __future__ import annotations
import argparse, base64, hashlib, html, io, json, math, shutil, subprocess, zipfile
from pathlib import Path
import numpy as np
import scipy.signal as signal
import soundfile as sf
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio/foley'
PREVIEW = ROOT / 'builds/previews/sfx'
SR = 32000
PACKS = [
    dict(id='kenney', archive='rpg_oga.zip', creator='Kenney Vleugels', title='50 RPG sound effects', source_url='https://opengameart.org/content/50-rpg-sound-effects', download_url='https://opengameart.org/sites/default/files/RPGsounds_Kenney.zip', archive_sha256='3ae398ad63e293f9c450bda22d5d81c3af69c74df66fc1400f33c012c0bbc231', license='CC0-1.0', license_record='assets/audio/foley/sources/Kenney-license.txt'),
    dict(id='rubberduck', archive='rubberduck_sfx100v2.zip', creator='rubberduck', title='100 CC0 SFX #2', source_url='https://opengameart.org/content/100-cc0-sfx-2', download_url='https://opengameart.org/sites/default/files/sfx_100_v2.zip', archive_sha256='0fc61b4494e2e893c0c015ced4877b3f689c7d84a48cb61daecd7ddb52db797b', license='CC0-1.0', license_record='assets/audio/foley/sources/rubberduck-license-declaration.txt')]


def layer(source, at=0.0, gain=0.0, start=0.0, duration=None, rate=1.0, pan=0.0, fade=.008):
    return dict(source=source, at=at, gain_db=gain, start_seconds=start, duration_seconds=duration, playback_rate=rate, pan=pan, fade_seconds=fade)


def k(name, **kw): return layer('kenney:'+name, **kw)
def r(name, **kw): return layer('rubberduck:'+name, **kw)

# Each variation is a distinct performance or an intentionally different physical
# sequence. Runtime pitch variation is subtle and is not the source of diversity.
RECIPES = {
 'paper': [[k('bookFlip1')], [k('bookFlip2')], [k('bookFlip3')]],
 'book': [[k('bookOpen'),k('bookFlip1',at=.12,gain=-4)], [k('bookFlip2'),k('bookPlace2',at=.38,gain=-8)], [k('bookFlip3'),k('bookClose',at=.30,gain=-7)]],
 'cloth': [[k('cloth1')], [k('cloth2')], [k('cloth3')]],
 'rope': [[k('clothBelt'),k('creak1',at=.03,gain=-8)], [k('clothBelt2'),k('creak2',at=.06,gain=-9)], [k('cloth4'),k('creak3',at=.08,gain=-10)]],
 'metal': [[r('metal_01')], [r('metal_02')], [r('metal_04'),k('handleCoins2',at=.10,gain=-11)]],
 'lock': [[r('lock_open_01'),k('metalLatch',at=.42,gain=-8)], [k('metalClick'),r('lock_open_01',at=.14,rate=.97)]],
 'glass': [[r('glass_01')], [r('glass_02')], [r('glass_03')]],
 'wood': [[r('wood_01')], [r('wood_02')], [r('wood_03')]],
 'water': [[r('loop_water_01',start=.8,duration=1.7,fade=.16)], [r('loop_water_02',start=1.3,duration=1.8,fade=.16)], [r('loop_water_03',start=2.4,duration=1.6,fade=.16)]],
 'footsteps_wet': [[r('footstep_wet_01',pan=-.12),r('footstep_wet_02',at=.39,pan=.12)], [r('footstep_wet_02',pan=-.12),r('footstep_wet_03',at=.42,pan=.12)], [r('footstep_wet_03',pan=-.12),r('footstep_wet_01',at=.37,pan=.12)]],
 'footsteps_wood': [[r('footstep_wood_01',pan=-.12),r('footstep_wood_03',at=.40,pan=.12)], [r('footstep_wood_02',pan=-.12),r('footstep_wood_04',at=.43,pan=.12)], [r('footstep_wood_04',pan=-.12),r('footstep_wood_01',at=.38,pan=.12)]],
 'door': [[k('metalLatch',gain=-8),k('doorOpen_1',at=.12)], [r('door_02',gain=-7),k('doorOpen_2',at=.10)]],
 'mechanism': [[k('metalClick'),r('loop_machine_01',at=.12,start=1.5,duration=1.2,gain=-5,fade=.09),k('metalLatch',at=1.26,gain=-5)], [r('switch_01'),r('loop_machine_03',at=.15,start=.1,duration=1.3,gain=-5,fade=.09),r('metal_05',at=1.38,gain=-7)]],
 'collect': [[k('handleSmallLeather'),k('cloth1',at=.10,gain=-6)], [k('handleSmallLeather2'),k('cloth2',at=.08,gain=-5)], [k('cloth3'),k('beltHandle2',at=.20,gain=-7)]],
 'combine': [[k('cloth2'),r('metal_02',at=.18,gain=-3),k('metalClick',at=.34,gain=-5)], [k('cloth3'),r('wood_04',at=.16,gain=-2),k('metalLatch',at=.36,gain=-9)], [k('cloth4'),r('metal_06',at=.17),k('beltHandle1',at=.37,gain=-5)]],
 'stamp': [[r('wood_hit_01'),k('bookFlip3',at=.15,gain=-10)], [r('wood_hit_02'),k('bookFlip2',at=.17,gain=-10)], [k('bookPlace3'),k('bookFlip3',at=.19,gain=-9)]],
 'ui': [[r('switch_01')], [r('switch_02')]],
 'voice_skip': [[k('cloth4',duration=.18,fade=.025)], [k('handleSmallLeather2',duration=.16,fade=.025)]]
}
DESCRIPTIONS = {
 'paper':'Individual pages handled close to the listener.', 'book':'A page or cover movement followed by a restrained book contact.',
 'cloth':'Soft fabric handling for bags, aprons and textiles.', 'rope':'Fibres pulled taut with a quiet strain underneath.',
 'metal':'Small metal fittings handled, with a faint coin rattle in the third variation.', 'lock':'A lock turns and its catch settles.',
 'glass':'Short glass contacts for fragile instruments and vessels.', 'wood':'Dry wooden fittings and surfaces handled.',
 'water':'Brief flowing-water detail, faded into the existing location ambience.', 'footsteps_wet':'Two measured steps across wet ground.',
 'footsteps_wood':'Two measured steps on wooden flooring.', 'door':'A latch releases before a door opens.',
 'mechanism':'A control engages, machinery moves briefly, and a catch settles.', 'collect':'A small object is tucked into a soft bag.',
 'combine':'Handling, contact and a final fitting together.', 'stamp':'A paper-backed wooden stamp or firm tabletop contact.',
 'ui':'Quiet tactile switches for interface confirmations.', 'voice_skip':'A very soft fabric motion without a distracting musical tone.'
}
GAINS = {'paper':-3,'book':-4,'cloth':-3,'rope':-4,'metal':-6,'lock':-5,'glass':-7,'wood':-5,'water':-7,'footsteps_wet':-5,'footsteps_wood':-5,'door':-6,'mechanism':-7,'collect':-3,'combine':-5,'stamp':-6,'ui':-10,'voice_skip':-12}


def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def db(x): return 20*math.log10(max(float(x),1e-12))
def rel(path): return path.relative_to(ROOT).as_posix()
def source_path(source):
    pack,name=source.split(':',1)
    return OUT/'sources'/pack/(name+'.ogg')
def member_name(source):
    pack,name=source.split(':',1)
    return 'OGG/'+name+'.ogg' if pack=='kenney' else 'sfx100v2_'+name+'.ogg'


def import_sources(folder):
    required={item['source'] for recipes in RECIPES.values() for recipe in recipes for item in recipe}
    for pack in PACKS:
        archive=folder/pack['archive']
        if digest(archive)!=pack['archive_sha256']: raise ValueError('Source archive hash mismatch: '+str(archive))
        with zipfile.ZipFile(archive) as z:
            for source in sorted(required):
                if not source.startswith(pack['id']+':'): continue
                path=source_path(source);path.parent.mkdir(parents=True,exist_ok=True)
                path.write_bytes(z.read(member_name(source)))
            if pack['id']=='kenney': (OUT/'sources/Kenney-license.txt').write_bytes(z.read('license.txt'))
    (OUT/'sources/rubberduck-license-declaration.txt').write_text(
        'License declaration record, checked 14 November 2026\n'
        'Creator: rubberduck\nTitle: 100 CC0 SFX #2\n'
        'Author page: https://opengameart.org/content/100-cc0-sfx-2\n'
        'The author page lists License(s): CC0 and describes the pack as "another pack with 100 CC0 sfx".\n'
        'CC0 1.0 public-domain dedication: https://creativecommons.org/publicdomain/zero/1.0/\n'
        'The downloaded archive contains no separate license file. This is a project-maintained record of the author page, not an invented upstream license file.\n')
    sources=[]
    for source in sorted(required):
        pack=next(p for p in PACKS if p['id']==source.split(':')[0]);path=source_path(source)
        sources.append(dict(id=source,path=rel(path),sha256=digest(path),creator=pack['creator'],pack=pack['id'],member=member_name(source),license='CC0-1.0',source_url=pack['source_url']))
    (OUT/'sources/provenance.json').write_text(json.dumps(dict(checked_date='2026-11-14',packs=PACKS,sources=sources),indent=2)+'\n')


def trim_silence(a):
    level=np.max(np.abs(a),axis=1); active=np.flatnonzero(level>max(np.max(level)*.002,1e-5))
    if not len(active): raise ValueError('Silent source')
    pad=int(.012*SR)
    return a[max(0,int(active[0])-pad):min(len(a),int(active[-1])+pad+1)]


def fade(a,seconds):
    n=min(len(a)//2,max(1,round(seconds*SR)))
    a=a.copy();ramp=np.sin(np.linspace(0,np.pi/2,n))**2
    a[:n]*=ramp[:,None];a[-n:]*=ramp[::-1,None]
    return a


def prepare_layer(item):
    a,sr=sf.read(source_path(item['source']),dtype='float64',always_2d=True)
    start=int(item['start_seconds']*sr)
    end=len(a) if item['duration_seconds'] is None else start+int(item['duration_seconds']*sr)
    a=a[start:end]
    if a.shape[1]==1:a=np.repeat(a,2,axis=1)
    elif a.shape[1]>2:raise ValueError('Unexpected channel layout')
    target_len=round(len(a)*SR/sr/item['playback_rate'])
    a=signal.resample_poly(a,SR,round(sr*item['playback_rate']),axis=0)[:target_len]
    a=signal.sosfilt(signal.butter(2,[50,11000],btype='bandpass',fs=SR,output='sos'),a,axis=0)
    a=trim_silence(a)
    a=fade(a,item['fade_seconds'])
    # RMS matching bounded by peak headroom keeps quiet cloth audible without
    # flattening impact transients or clipping source Vorbis decode overshoot.
    gain=min(10**(-25/20)/max(np.sqrt(np.mean(a*a)),1e-9),10**(-10/20)/max(np.max(np.abs(a)),1e-9))
    a*=gain*10**(item['gain_db']/20)
    a[:,0]*=1-max(0,item['pan'])*.5;a[:,1]*=1+min(0,item['pan'])*.5
    return a


def render(recipe,cue):
    layers=[(int(item['at']*SR),prepare_layer(item)) for item in recipe]
    n=max(at+len(a) for at,a in layers)+int(.035*SR)
    a=np.zeros((n,2),dtype=np.float64)
    for at,part in layers:a[at:at+len(part)]+=part
    rms_target=-29 if cue in ('ui','voice_skip') else -24
    peak_target=-12 if cue in ('ui','voice_skip') else -7
    a*=min(10**(rms_target/20)/max(np.sqrt(np.mean(a*a)),1e-9),10**(peak_target/20)/max(np.max(np.abs(a)),1e-9))
    return fade(a,.004)


def encode(a,master,ogg):
    sf.write(master,a,SR,subtype='PCM_16')
    # Bitexact muxing fixes the Ogg stream serial so repeated offline builds hash
    # identically, while retaining the pinned encoder's standard Vorbis quality.
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-v','error','-y','-i',str(master),'-c:a','libvorbis','-q:a','5','-fflags','+bitexact','-flags:a','+bitexact',str(ogg)],check=True)


def preview(manifest):
    PREVIEW.mkdir(parents=True,exist_ok=True)
    # Embedded media makes this gallery a single file that can be shared offline.
    def player(path):
        mime='audio/ogg' if path.suffix=='.ogg' else 'audio/wav'
        uri='data:'+mime+';base64,'+base64.b64encode(path.read_bytes()).decode()
        return '<audio controls preload="none" src="'+uri+'"></audio>'
    rows=[]
    for cue,config in manifest['cues'].items():
        variants=[]
        for i,path in enumerate(config['variants']):variants.append('<div><span>Variation '+str(i+1)+'</span>'+player(ROOT/path.removeprefix('res://'))+'</div>')
        old=ROOT/'assets/audio/sfx'/f'{cue}.ogg'
        before='<details><summary>Previous synthesized effect</summary>'+player(old)+'</details>' if cue in ('paper','collect','door','mechanism','ui') and old.exists() else ''
        rows.append('<section><h2>'+html.escape(cue.replace('_',' ').title())+'</h2><p>'+html.escape(config['description'])+'</p>'+''.join(variants)+before+'</section>')
    excerpts=[];timeline=[];t=0.0
    for cue in ('paper','book','rope','collect','lock','door','footsteps_wet','footsteps_wood','metal','glass','mechanism','water','combine','stamp','ui'):
        path=ROOT/manifest['cues'][cue]['path'].removeprefix('res://')
        asset=next(a for a in manifest['assets'] if a['path']==rel(path))
        a,_=sf.read(ROOT/asset['master'],always_2d=True)
        # Showcase applies runtime cue trim, but not device/user/master volume.
        a*=10**(manifest['cues'][cue]['gain_db']/20)
        timeline.append(dict(cue=cue,start_seconds=round(t,3),end_seconds=round(t+len(a)/SR,3)))
        excerpts.extend([a,np.zeros((int(.65*SR),2))]);t+=(len(a)+int(.65*SR))/SR
    medley=np.concatenate(excerpts)
    sf.write(PREVIEW/'quiet-meridian-foley-preview.wav',medley,SR,subtype='PCM_16')
    (PREVIEW/'timeline.json').write_text(json.dumps(timeline,indent=2)+'\n')
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The Quiet Meridian — Foley review</title><style>body{font:17px/1.55 system-ui;background:#102126;color:#e4dcc7;max-width:1100px;margin:auto;padding:30px}h1,h2{color:#d9b36c}p{max-width:78ch}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:18px}section{background:#1b3034;padding:18px;border-radius:8px}audio{display:block;width:100%;margin:8px 0 20px}summary{cursor:pointer}a{color:#e4c389}.timeline{font-size:14px;color:#b9cbc9}</style><h1>The Quiet Meridian: tactile sound review</h1><p>49 new material and interaction variations derived from explicitly licensed CC0 recordings. These are development candidates for listening review; the full game remains an alpha. No provider or API connection is needed.</p><p>The short sequence applies the proposed in-game cue gains. Individual players below present the prepared masters without that additional gain. Start at a comfortable device volume. No autoplay.</p>'''
    page+='<h2>Representative sequence</h2>'+player(PREVIEW/'quiet-meridian-foley-preview.wav')+'<p class="timeline">'+' · '.join(f"{x['start_seconds']:.1f}s {html.escape(x['cue'].replace('_',' '))}" for x in timeline)+'</p><main>'+''.join(rows)+'</main><p>Sources: <a href="https://opengameart.org/content/50-rpg-sound-effects">Kenney Vleugels, RPG sounds</a> and <a href="https://opengameart.org/content/100-cc0-sfx-2">rubberduck, 100 CC0 SFX #2</a>. CC0-1.0. Editing, sequences and mix prepared for The Quiet Meridian. Original synthesized comparison effects are retained from the previous project pass.</p></html>'
    (PREVIEW/'index.html').write_text(page)


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--import-archives',type=Path);args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    for name in ['sources','masters']:
        (OUT/name).mkdir(exist_ok=True);(OUT/name/'.gdignore').touch()
    if args.import_archives:import_sources(args.import_archives)
    provenance=json.loads((OUT/'sources/provenance.json').read_text())
    for source in provenance['sources']:
        if digest(ROOT/source['path'])!=source['sha256']:raise ValueError('Retained source hash mismatch: '+source['id'])
    assets=[];cues={}
    for cue,recipes in RECIPES.items():
        paths=[]
        for i,recipe in enumerate(recipes,1):
            a=render(recipe,cue);ogg=OUT/f'{cue}_{i:02}.ogg';master=OUT/'masters'/f'{cue}_{i:02}.wav'
            encode(a,master,ogg)
            # Report the actual encoded WAV measurements, not the float work buffer.
            pcm,_=sf.read(master,always_2d=True)
            assets.append(dict(path=rel(ogg),master=rel(master),kind='sfx',cue=cue,variant=i,sample_rate=SR,channels=2,duration_seconds=round(len(pcm)/SR,6),peak_dbfs=round(db(np.max(np.abs(pcm))),3),rms_dbfs=round(db(np.sqrt(np.mean(pcm*pcm))),3),sha256=digest(ogg),master_sha256=digest(master),source_ids=sorted({item['source'] for item in recipe}),recipe=recipe))
            paths.append('res://'+rel(ogg))
        cues[cue]=dict(path=paths[0],variants=paths,gain_db=GAINS[cue],pitch_range=[.985,1.015] if cue not in ('ui','voice_skip','water') else [1.0,1.0],cooldown_seconds=.12 if cue in ('ui','voice_skip') else .18,description=DESCRIPTIONS[cue])
    manifest=dict(version=1,created='2026-11-14',method='Edited and sequenced CC0 material Foley; third-party source recordings retained unchanged.',generator='tools/build_foley.py',generator_sha256=digest(Path(__file__)),build_dependencies='tools/score-requirements.txt',license='CC0-1.0',commercial_use_provenance='Selected recordings are explicitly dedicated under CC0 by Kenney Vleugels and rubberduck. This is licensed third-party Foley, not a claim that the source recordings were made for the project. Editing and sequences were authored locally. No voice, service-generated audio, purchased subscription or paid API calls used.',quality_status='Signal, decoder, provenance and repetition checks are separate from subjective material realism and final listening acceptance.',processing=dict(sample_rate=SR,channels=2,highpass_hz=50,lowpass_hz=11000,layer_target_rms_dbfs=-25,layer_peak_ceiling_dbfs=-10,final_target_rms_dbfs=-24,final_peak_ceiling_dbfs=-7,ui_target_rms_dbfs=-29,ui_peak_ceiling_dbfs=-12,tail_padding_seconds=.035,final_fade_seconds=.004,normalization='Linear RMS matching with peak ceiling, no clipping or synthesized tones.'),packs=provenance['packs'],sources=provenance['sources'],cues=cues,assets=assets)
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (OUT/'LICENSES.txt').write_text('THE QUIET MERIDIAN — FOLEY CREDITS\n\nSelected sound recordings: Kenney Vleugels (RPG sounds) and rubberduck (100 CC0 SFX #2).\nLicense: CC0 1.0 Universal public-domain dedication.\nhttps://creativecommons.org/publicdomain/zero/1.0/\n\nSources:\nhttps://opengameart.org/content/50-rpg-sound-effects\nhttps://opengameart.org/content/100-cc0-sfx-2\n\nOriginal recordings remain retained without modification in sources/.\nGame derivatives are edited, resampled and sequenced locally; detailed recipes and source hashes are in manifest.json.\n\nExact Kenney archive license follows:\n'+(OUT/'sources/Kenney-license.txt').read_text()+'\n\nRubberduck author-page declaration record follows:\n'+(OUT/'sources/rubberduck-license-declaration.txt').read_text())
    preview(manifest)
    print(f'FOLEY_BUILD_OK: {len(cues)} cue identities, {len(assets)} variants, {len(provenance["sources"])} retained sources')

if __name__=='__main__':main()
