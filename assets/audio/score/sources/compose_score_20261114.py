#!/usr/bin/env python3
"""Original deterministic chamber score, soundscapes and foley for The Quiet Meridian.

No recordings, sample libraries, copyrighted melodies, artist references or external
model outputs are used. Runtime Ogg files are rendered from the included note-event
scores and project-authored physical/additive instruments. Build-only dependencies:
work/av-env/bin/python -m pip install numpy scipy soundfile imageio-ffmpeg
"""
from __future__ import annotations
import argparse, hashlib, json, math, subprocess
from pathlib import Path
import numpy as np
import scipy.signal as signal
import soundfile as sf
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
SR = 32000
TAU = 2 * np.pi
SCORE = ROOT / 'assets/audio/score'
AMB = ROOT / 'assets/audio/ambience'
SFX = ROOT / 'assets/audio/sfx'
# Degree/rhythm phrases were written for this story. Degree zero is the tonic.
MERIDIAN = [(0,1),(4,1),(7,2),(5,1),(4,1),(2,2),(-1,1),(2,1),(4,2),(1,1),(0,3)]
NAMES = [(2,1.5),(3,.5),(4,2),(7,1),(6,1),(4,2),(3,1.5),(2,.5),(1,2),(0,4)]
RECORD = [(0,.75),(1,.25),(4,1),(-1,1),(3,1),(2,2),(0,1),(4,1),(5,1),(4,1),(2,2),(1,1),(0,2)]
SCALES = {'minor':[0,2,3,5,7,8,10], 'dorian':[0,2,3,5,7,9,10], 'major':[0,2,4,5,7,9,11]}
# Chord roots are semitone offsets from tonic; type controls the modal colour.
HARMONIES = {
 'minor':[(0,'m'),(8,'M'),(3,'M'),(10,'M'),(5,'m'),(0,'m'),(8,'M'),(7,'dom')],
 'dorian':[(0,'m'),(5,'M'),(10,'M'),(0,'m'),(3,'M'),(5,'M'),(0,'m'),(7,'m')],
 'major':[(0,'M'),(7,'M'),(9,'m'),(5,'M'),(2,'m'),(0,'M'),(5,'M'),(7,'dom')]
}
CUES = [
 dict(id='title',title='The Quiet Meridian — main theme',tonic=50,mode='minor',bpm=72,meter=3,bars=64,lead='piano',answer='flute',theme='Meridian',density=.85),
 dict(id='ch1',title='The Borrowed Bell',tonic=50,mode='minor',bpm=66,meter=3,bars=48,lead='harp',answer='flute',theme='Meridian',density=.64),
 dict(id='ch2',title='Water Has a Memory',tonic=43,mode='dorian',bpm=82,meter=3,bars=64,lead='cello',answer='reed',theme='Record',density=.80),
 dict(id='ch3',title='The Unstruck Hour',tonic=48,mode='minor',bpm=74,meter=4,bars=48,lead='celesta',answer='flute',theme='Meridian',density=.74),
 dict(id='ch4',title='Names in the Reeds',tonic=53,mode='major',bpm=68,meter=4,bars=48,lead='flute',answer='cello',theme='Names',density=.66),
 dict(id='ch5',title='An Unbroken Chain',tonic=45,mode='minor',bpm=78,meter=3,bars=64,lead='reed',answer='piano',theme='Record',density=.86),
 dict(id='ch6',title='A Record Kept in Common',tonic=50,mode='major',bpm=76,meter=4,bars=48,lead='piano',answer='flute',theme='Names',density=.80),
 dict(id='tension',title='The Unaccounted Minute',tonic=50,mode='minor',bpm=90,meter=4,bars=48,lead='cello',answer='reed',theme='Record',density=.92),
 dict(id='resolution',title='Every Name at Dawn',tonic=50,mode='major',bpm=68,meter=4,bars=48,lead='flute',answer='piano',theme='Meridian',density=.84)
]


def hz(note): return 440.0 * 2 ** ((note - 69) / 12)
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def db(value): return 20 * math.log10(max(float(value), 1e-12))
def degree(tonic, scale, d):
    octave, index = divmod(d, 7)
    return tonic + scale[index] + octave * 12


def env(n, attack, sustain, release):
    t = np.arange(n, dtype=np.float32) / SR
    rising = np.minimum(t / max(attack, .001), 1)
    falling = np.clip((sustain + release - t) / max(release, .001), 0, 1)
    return (np.sin(rising*np.pi/2)**2 * np.sin(falling*np.pi/2)**2).astype(np.float32)


def synth(instrument, midi, duration, seed):
    """Instruments share pitch, not a single generic oscillator envelope."""
    rng = np.random.default_rng(seed)
    release = {'piano':1.6,'harp':1.1,'celesta':2.1,'cello':.65,'strings':.9,'flute':.2,'reed':.3,'bass':.7}.get(instrument,.3)
    n = int((duration + release) * SR)
    t = np.arange(n, dtype=np.float32) / SR
    f = hz(midi)
    y = np.zeros(n, np.float32)
    if instrument in ('piano','harp','celesta','bass'):
        if instrument == 'celesta':
            partials = [(1,1,1.9),(2.01,.26,1.1),(3.98,.13,.7),(5.43,.055,.35)]
        else:
            partials=[]
            for k in range(1, 9 if instrument=='piano' else 6):
                stretch=math.sqrt(1+.00016*k*k) if instrument=='piano' else 1
                amplitude=1/(k**(1.8 if instrument=='harp' else 1.55))
                partials.append((k*stretch,amplitude,(2.6 if instrument=='piano' else 1.7)/(1+.24*(k-1))))
        for ratio, amp, decay in partials:
            if f*ratio < SR*.44:
                y += amp * np.sin(TAU*f*ratio*t + .06*math.sin(ratio)) * np.exp(-t/decay)
        y *= env(n,.005,duration,release)
        if instrument=='bass': y = signal.sosfilt(signal.butter(2,1200,fs=SR,output='sos'),y).astype(np.float32)
    elif instrument in ('strings','cello'):
        # Slightly independent bowed partials, slow breath and delayed vibrato.
        vib = .004 * np.minimum(t/.8,1) * np.sin(TAU*5.05*t + seed*.01)
        phase = TAU*f*t + f/5.05*.004*(1-np.cos(TAU*5.05*t))*np.minimum(t/.8,1)
        for k in range(1,9):
            if k*f<6500:
                y += np.sin(k*phase + .012*np.sin(TAU*(.63+k*.03)*t)) / k**1.75
        rosin = signal.sosfilt(signal.butter(2,[400,2400],btype='bandpass',fs=SR,output='sos'),rng.normal(0,1,n))
        y += rosin.astype(np.float32)*.025
        y *= env(n,.28 if instrument=='cello' else .48,duration,release)
        y *= .93+.07*np.sin(TAU*.37*t + seed)
    elif instrument in ('flute','reed'):
        vibrato = .0025*f/5.2*(1-np.cos(TAU*5.2*t))*np.minimum(t/.6,1)
        phase = TAU*f*t + vibrato
        partials=[(1,1),(2,.055),(3,.12),(4,.025)] if instrument=='flute' else [(1,1),(3,.27),(5,.10),(7,.025)]
        for k,a in partials:
            if f*k < 6000: y += a*np.sin(k*phase)
        breath = signal.sosfilt(signal.butter(2,[850,4500],btype='bandpass',fs=SR,output='sos'),rng.normal(0,1,n)).astype(np.float32)
        y += breath*.035*np.exp(-t*.8)
        y *= env(n,.095,duration,release)
        y *= .96+.04*np.sin(TAU*.65*t+seed)
    y /= max(float(np.max(np.abs(y))),1.0)
    return y.astype(np.float32)


def add_stereo(buffer, mono, start, volume=1., pan=0.):
    offset=max(0,int(start*SR)); available=min(len(mono),len(buffer)-offset)
    if available<=0:return
    angle=(pan+1)*np.pi/4
    buffer[offset:offset+available,0]+=mono[:available]*(volume*math.cos(angle))
    buffer[offset:offset+available,1]+=mono[:available]*(volume*math.sin(angle))


def room(audio, wet=.21):
    # Authored diffuse stereo impulse, not a recorded room or external preset.
    result=audio.copy()
    for delay, gain in [(.037,.24),(.071,.20),(.113,.17),(.173,.135),(.251,.10),(.359,.075),(.503,.052),(.719,.035),(.971,.021),(1.337,.013)]:
        shift=int(delay*SR)
        if shift>=len(audio):continue
        result[shift:,0]+=audio[:-shift,1]*(gain*wet)
        result[shift:,1]+=audio[:-shift,0]*(gain*wet*.94)
    return result


def master(audio, rms_target=.065, peak_limit=.61, fade=2.):
    # DC removal and conservative headroom rather than brick-wall loudness.
    audio=signal.sosfilt(signal.butter(2,30,fs=SR,btype='highpass',output='sos'),audio,axis=0).astype(np.float32)
    rms=float(np.sqrt(np.mean(audio.astype(np.float64)**2)))
    peak=float(np.max(np.abs(audio)))
    audio*=min(rms_target/max(rms,1e-9),peak_limit/max(peak,1e-9))
    count=min(int(fade*SR),len(audio)//4)
    ramp=np.sin(np.linspace(0,np.pi/2,count,dtype=np.float32))**2
    audio[:count]*=ramp[:,None]
    audio[-count:]*=ramp[::-1,None]
    return audio


def score_events(cue):
    rng=np.random.default_rng(22141+CUES.index(cue)*103)
    spb=60/cue['bpm']; meter=cue['meter']; scale=SCALES[cue['mode']]
    bars=cue['bars']; blocks=bars//8
    forms = ['Prelude','Statement','Answer','Shadow','Reprise','Coda'] if blocks==6 else ['Prelude','Statement','Answer','Shadow','Countermotion','Return','Reprise','Coda']
    events=[]
    def note(inst,midi,beat,duration,velocity,pan=0):
        if beat>=bars*meter:return
        jitter=float(rng.uniform(-.012,.012)) if beat else 0
        events.append(dict(instrument=inst,midi=int(midi),start=round(max(0,beat*spb+jitter),5),duration=round(duration*spb,5),velocity=round(velocity*float(rng.uniform(.94,1.06)),5),pan=pan,seed=int(rng.integers(1,999999))))
    for bar in range(bars):
        block=bar//8; form=forms[block]; barbeat=bar*meter
        local=bar%8
        root, kind=HARMONIES[cue['mode']][(bar//2 + (2 if form in ('Shadow','Countermotion') else 0))%8]
        # Minor tonal centre returns in final two bars; resolution ends major.
        if bar>=bars-2: root,kind=0,('M' if cue['mode']=='major' else 'm')
        chord=[cue['tonic']+root + interval for interval in ([0,3,7] if kind=='m' else [0,4,7])]
        if kind=='dom':chord.append(cue['tonic']+root+10)
        while min(chord)>58:chord=[n-12 for n in chord]
        intensity=[.40,.70,.78,.52,.87,.48][block] if blocks==6 else [.38,.62,.74,.56,.83,.72,.91,.46][block]
        intensity*=cue['density']
        # Breathable sustained harmony changes every two bars; common tones voiced softly.
        if bar%2==0:
            for j,pitch in enumerate(chord):
                note('strings',pitch+12,barbeat,meter*1.9,.10*intensity,[-.50,.15,.55,.3][j])
            note('cello',chord[0]-12,barbeat,meter*1.8,.12*intensity,-.20)
        # Broken chords have a composed pattern, rests, inversions, and phrase-level variation.
        arp_inst='harp' if cue['id'] not in ('ch2','ch5','tension') else 'piano'
        rhythm=[0,1,2] if meter==3 else [0,.75,1.5,2.5,3.25]
        if form=='Prelude':rhythm=[0,2] if meter==3 else [0,2.5]
        if form=='Coda' and local>3:rhythm=[0]
        pattern=[0,2,1,2,3] if len(chord)==4 else [0,2,1,2,0]
        for i,b in enumerate(rhythm):
            pitch=chord[pattern[(i+bar%2)%len(pattern)]%len(chord)]+12
            if form in ('Answer','Reprise') and i%3==2:pitch+=12
            note(arp_inst,pitch,barbeat+b,.7,.13*intensity,-.28 if arp_inst=='harp' else .25)
        if cue['id'] in ('ch2','ch5','tension') and form not in ('Prelude','Coda'):
            note('bass',chord[0]-12,barbeat,.8,.16*intensity,-.1)
            if meter==4:note('bass',chord[2]-12,barbeat+2,.65,.10*intensity,.05)
        if cue['id']=='ch3' and bar%4==2:
            note('celesta',degree(cue['tonic'],scale,11),barbeat+meter-.5,1.2,.09*intensity,.65)
        # New melodic phrase each four bars; silence in the opening/closing margins.
        if bar%4==0 and bar>=4 and bar<bars-4:
            motif={'Meridian':MERIDIAN,'Names':NAMES,'Record':RECORD}[cue['theme']]
            phrase_len=4*meter; raw_len=sum(d for _,d in motif)
            factor=phrase_len/raw_len
            elapsed=0
            lead=cue['lead'] if form not in ('Answer','Shadow','Return') else cue['answer']
            base=cue['tonic']+12
            if lead=='cello':base-=12
            # Contrasting phrase answers rise through a different scale segment;
            # the reprise returns the original interval identity with a higher peak.
            shift=2 if form in ('Answer','Countermotion') else (1 if form=='Shadow' else 0)
            for index,(d,length) in enumerate(motif):
                if form=='Shadow' and index in (3,7):elapsed+=length*factor;continue
                deg=d+shift
                if form=='Reprise' and index in (2,3):deg+=7
                # Anticipated final dominant is voiced as a leading tone.
                pitch=degree(base,scale,deg)
                duration=length*factor*(.88 if lead in ('flute','reed') else .94)
                emphasis=1.1 if index in (0,2,6) else .9
                note(lead,pitch,barbeat+elapsed,duration,.23*intensity*emphasis,.12 if lead in ('flute','reed') else -.12)
                elapsed+=length*factor
            # A slowly moving independent countermelody, present only in developed sections.
            if form in ('Answer','Countermotion','Reprise'):
                counter='cello' if lead!='cello' else 'flute'
                for j,d in enumerate([4,3,2,0]):
                    octave=0 if counter=='cello' else 12
                    note(counter,degree(cue['tonic']+octave,scale,d),barbeat+j*meter,meter*.86,.085*intensity,-.48)
    return events,forms


def render_score(cue):
    events,forms=score_events(cue)
    duration=cue['bars']*cue['meter']*60/cue['bpm']+3.0
    audio=np.zeros((int(duration*SR),2),np.float32)
    for e in events:
        add_stereo(audio,synth(e['instrument'],e['midi'],e['duration'],e['seed']),e['start'],e['velocity'],e['pan'])
    audio=master(room(audio,.34),.066,.63,2.5)
    metadata={'id':cue['id'],'title':cue['title'],'bpm':cue['bpm'],'meter':cue['meter'],'bars':cue['bars'],'mode':cue['mode'],'tonic_midi':cue['tonic'],'theme':cue['theme'],'form':forms,'note_events':events}
    path=SCORE/'events'/f"{cue['id']}.json"
    path.write_text(json.dumps(metadata,indent=2)+'\n')
    return audio,metadata


def noise_filter(rng,n,cutoff,btype='lowpass'):
    return signal.sosfilt(signal.butter(2,cutoff,fs=SR,btype=btype,output='sos'),rng.standard_normal(n)).astype(np.float32)


def ambience(kind,seconds=72):
    seed=4400+['harbor','interior','machinery','marsh','wind','rain'].index(kind)*701
    rng=np.random.default_rng(seed);n=int(seconds*SR);t=np.arange(n,dtype=np.float32)/SR
    channels=[]
    for ch in range(2):
        low=noise_filter(rng,n,400)
        hiss=noise_filter(rng,n,[350,4500],'bandpass')
        swell=(.52+.22*np.sin(TAU*.071*t+ch)+.13*np.sin(TAU*.117*t+.4))
        y=(low*.17+hiss*.018)*swell
        if kind in ('harbor','marsh'):
            y+=noise_filter(rng,n,[150,1900],'bandpass')*(.02+.018*np.sin(TAU*.23*t+ch)**2)
            for _ in range(125 if kind=='harbor' else 60):
                start=int(rng.uniform(0,seconds-.4)*SR);m=int(rng.uniform(.05,.25)*SR);u=np.arange(m)/SR
                f=rng.uniform(450,1300)
                bubble=np.sin(TAU*(f*u-500*u*u))*np.exp(-u*30)*np.sin(np.minimum(u/.008,1)*np.pi/2)
                y[start:start+m]+=bubble[:min(m,n-start)]*rng.uniform(.01,.05)
        if kind in ('wind','marsh'):
            y+=noise_filter(rng,n,[70,850],'bandpass')*(.08+.07*np.sin(TAU*.041*t+.5)**2)
        if kind=='rain':
            y+=noise_filter(rng,n,[600,10500],'bandpass')*(.10+.025*np.sin(TAU*.053*t))
            for _ in range(190):
                start=int(rng.uniform(0,seconds-.06)*SR);m=int(.05*SR);u=np.arange(m)/SR
                y[start:start+m]+=rng.normal(0,.04,m)*np.exp(-u*100)
        if kind=='machinery':
            y+=.10*np.sin(TAU*52*t+.07*np.sin(TAU*.6*t))+.035*np.sin(TAU*104*t)
            y+=noise_filter(rng,n,[400,3200],'bandpass')*.09*(.3+.7*np.sin(TAU*.77*t+ch)**16)
        if kind=='interior':
            y*=.18
            for beat in np.arange(.4,seconds,1.27):
                start=int(beat*SR);m=min(int(.06*SR),n-start);u=np.arange(m)/SR
                y[start:start+m]+=.022*np.sin(TAU*(1650 if int(beat/1.27)%2 else 1930)*u)*np.exp(-u*70)
        channels.append(y)
    return master(np.column_stack(channels),.033,.26,.25)


def sfx(kind):
    rng=np.random.default_rng(7700+sum(map(ord,kind)))
    length={'ui':.18,'paper':.8,'collect':1.2,'combine':1.9,'success':3.6,'error':.75,'travel':1.5,'door':1.4,'mechanism':2.3,'stamp':.55,'chapter':5.4,'voice_skip':.22}[kind]
    n=int(length*SR);t=np.arange(n,dtype=np.float32)/SR
    mono=np.zeros(n,np.float32)
    if kind in ('ui','paper','travel','voice_skip'):
        rustle=noise_filter(rng,n,[500,7500],'bandpass')
        modulation=np.sin(np.minimum(t/.025,1)*np.pi/2)**2 * np.exp(-t/(length*.4))
        if kind=='paper':modulation*=.35+.65*np.sin(TAU*7*t)**2
        if kind=='travel':modulation=np.sin(np.pi*t/length)**2*(.55+.45*np.sin(TAU*2.5*t)**2)
        mono=rustle*modulation*.25
        if kind=='ui':mono+=np.sin(TAU*870*t)*np.exp(-t*40)*.12
    elif kind in ('collect','combine','success','chapter'):
        pitches={'collect':[74,81],'combine':[62,69,77],'success':[62,69,74,77],'chapter':[50,57,62,66,69,74]}[kind]
        for i,pitch in enumerate(pitches):
            sound=synth('celesta' if kind!='combine' else 'harp',pitch,.65,900+i)
            offset=int(i*(.13 if kind!='chapter' else .35)*SR);count=min(len(sound),n-offset)
            mono[offset:offset+count]+=sound[:count]*.3
    elif kind=='error':
        mono=.2*(np.sin(TAU*146.8*t)+.3*np.sin(TAU*220*t))*np.exp(-t*7)*np.sin(np.minimum(t/.03,1)*np.pi/2)**2
    elif kind in ('door','mechanism','stamp'):
        if kind=='door':
            mono=.1*np.sin(TAU*(180*t+35*t*t))*np.sin(np.pi*t/length)**2
            for when in [.04,.88]:
                at=int(when*SR);m=min(int(.25*SR),n-at);u=np.arange(m)/SR
                mono[at:at+m]+=.3*(np.sin(TAU*90*u)+.3*rng.normal(size=m))*np.exp(-u*20)
        elif kind=='mechanism':
            for when in [.02,.24,.48,.74,1.0,1.28,1.60,1.92]:
                at=int(when*SR);m=min(int(.3*SR),n-at);u=np.arange(m)/SR
                mono[at:at+m]+=.22*(np.sin(TAU*460*u)+.32*np.sin(TAU*1103*u)+.25*rng.normal(size=m))*np.exp(-u*30)
        else:
            mono=(.4*np.sin(TAU*100*t)+.18*rng.normal(size=n))*np.exp(-t*35)
    audio=np.column_stack([mono,mono*.97])
    return master(room(audio,.18),.075,.49,.008)


def save_audio(audio,path,kind,extra=None,master_path=None):
    path.parent.mkdir(parents=True,exist_ok=True)
    wav=master_path or path.with_suffix('.wav')
    wav.parent.mkdir(parents=True,exist_ok=True)
    sf.write(wav,audio,SR,subtype='PCM_16')
    if path.suffix=='.ogg':
        subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','5',str(path)],check=True)
    source=audio.astype(np.float64)
    rms=np.sqrt(np.mean(source**2));peak=np.max(np.abs(source))
    # Window features expose arrangement/dynamic changes without claiming a listening test.
    windows=[round(db(np.sqrt(np.mean(source[i:i+SR*8]**2))),3) for i in range(0,len(audio),SR*8) if len(audio[i:i+SR*8])>=SR*2]
    record={'path':str(path.relative_to(ROOT)),'master':str(wav.relative_to(ROOT)),'kind':kind,'sample_rate':SR,'channels':2,'duration_seconds':round(len(audio)/SR,5),'peak_dbfs':round(db(peak),3),'rms_dbfs':round(db(rms),3),'window_rms_dbfs':windows,'sha256':digest(path),'master_sha256':digest(wav)}
    if extra:record.update(extra)
    return record


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--only',choices=['score','ambience','sfx','preview','all'],default='all');args=parser.parse_args()
    for folder in [SCORE/'events',SCORE/'masters',SCORE/'previews',AMB/'masters',SFX/'masters']:
        folder.mkdir(parents=True,exist_ok=True)
    for folder in [SCORE/'events',SCORE/'masters',SCORE/'previews',AMB/'masters',SFX/'masters']:(folder/'.gdignore').touch()
    manifest_path=SCORE/'manifest.json'
    records=json.loads(manifest_path.read_text()).get('assets',[]) if manifest_path.exists() else []
    def register(record):
        nonlocal records
        if 'events' in record: record['events_sha256']=digest(ROOT/record['events'])
        records=[r for r in records if r['path']!=record['path']]+[record]
        manifest_path.write_text(json.dumps({'created':'2026-11-14','method':'Original authored event scores and project-written physical/additive synthesis','generator':'tools/compose_score.py','generator_sha256':digest(Path(__file__)),'build_dependencies':'tools/score-requirements.txt','external_samples':[],'external_melodies':[],'external_model_outputs':[],'commercial_use_provenance':'All musical notes, arrangements, synthesis, ambience and effects authored for this project. No third-party recordings, soundfonts, copyrighted melodies or generated-service outputs used. Build tools do not impose their code licenses on rendered original audio.','quality_status':'Substantial synthesized chamber score; not a live orchestral recording or a claim of parity with a commercially produced reference game. Objective signal/structure checks and subjective audition are separate.','assets':records},indent=2)+'\n')
    if args.only in ('score','all'):
        for cue in CUES:
            print('Rendering',cue['id'],flush=True)
            audio,events=render_score(cue)
            register(save_audio(audio,SCORE/f"{cue['id']}.ogg",'music',{'title':cue['title'],'theme':cue['theme'],'form':events['form'],'bpm':cue['bpm'],'meter':cue['meter'],'note_count':len(events['note_events']),'events':f"assets/audio/score/events/{cue['id']}.json"},SCORE/'masters'/f"{cue['id']}.wav"))
    if args.only in ('ambience','all'):
        for kind in ['harbor','interior','machinery','marsh','wind','rain']:
            print('Rendering ambience',kind,flush=True)
            register(save_audio(ambience(kind),AMB/f'{kind}.ogg','ambience',{'loop':True},AMB/'masters'/f'{kind}.wav'))
    if args.only in ('sfx','all'):
        for kind in ['ui','paper','collect','combine','success','error','travel','door','mechanism','stamp','chapter','voice_skip']:
            print('Rendering effect',kind,flush=True)
            register(save_audio(sfx(kind),SFX/f'{kind}.ogg','sfx',{},SFX/'masters'/f'{kind}.wav'))
    if args.only in ('preview','all'):
        # Eight excerpts reveal statement, alternate instrumentation, tension and release.
        clips=[]
        for name,at in [('title',24),('ch1',28),('ch2',36),('ch3',32),('ch4',40),('ch5',38),('tension',36),('resolution',48)]:
            audio,_=sf.read(SCORE/'masters'/f'{name}.wav',dtype='float32')
            clip=audio[int(at*SR):int((at+7.5)*SR)].copy();fade=int(.20*SR)
            clip[:fade]*=np.linspace(0,1,fade)[:,None];clip[-fade:]*=np.linspace(1,0,fade)[:,None]
            clips.append(clip)
        preview=np.concatenate(clips)
        register(save_audio(preview,SCORE/'previews'/'quiet-meridian-score-preview.ogg','preview',{'contents':'Eight 7.5-second excerpts: title, chapters1–5, tension, resolution. No dialogue.'},SCORE/'previews'/'quiet-meridian-score-preview.wav'))
    configuration={'version':1,'music':{},'ambience':{},'sfx':{},'location_ambience':{},'manifest':'res://assets/audio/score/manifest.json','authored_source':'tools/compose_score.py'}
    by_path={r['path']:r for r in records}
    for cue in CUES:
        path=f"assets/audio/score/{cue['id']}.ogg";record=by_path.get(path,{})
        configuration['music'][cue['id']]={'path':'res://'+path,'title':cue['title'],'duration_seconds':record.get('duration_seconds',0),'gain_db':-2.0 if cue['id']!='tension' else -4.0,'loop':True,'theme':cue['theme'],'form':record.get('form',[])}
    for kind in ['harbor','interior','machinery','marsh','wind','rain']:
        configuration['ambience'][kind]={'path':f'res://assets/audio/ambience/{kind}.ogg','gain_db':-8.0,'loop':True}
    for kind in ['ui','paper','collect','combine','success','error','travel','door','mechanism','stamp','chapter','voice_skip']:
        configuration['sfx'][kind]={'path':f'res://assets/audio/sfx/{kind}.ogg','gain_db':-5.0 if kind in ('ui','paper','voice_skip') else -1.0}
    locations={1:['harbor','interior','interior','interior','interior','wind'],2:['machinery','machinery','machinery','interior','harbor','harbor'],3:['wind','interior','interior','wind','interior','wind'],4:['marsh','interior','rain','marsh','marsh','interior'],5:['wind','interior','interior','machinery','interior','machinery'],6:['harbor','interior','machinery','machinery','wind','interior']}
    for chapter,values in locations.items():
        for i,kind in enumerate(values,1):configuration['location_ambience'][f'ch{chapter}_l{i}']=kind
    (ROOT/'content/audio-score.json').write_text(json.dumps(configuration,indent=2)+'\n')
    print('Score configuration written',flush=True)

if __name__=='__main__':main()
