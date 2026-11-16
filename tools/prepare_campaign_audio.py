#!/usr/bin/env python3
"""Rebuild licensed room atmospheres locally; never alter or upload purchased masters."""
from pathlib import Path
import argparse,hashlib,json,subprocess,tempfile
import numpy as np
import soundfile as sf
import imageio_ffmpeg
from scipy.signal import resample_poly,butter,sosfilt
ROOT=Path(__file__).resolve().parents[1]
RATE=48000
DEST=ROOT/'assets/audio/licensed-campaign'

def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def db(x):return float(20*np.log10(max(float(x),1e-12)))
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--library-root',type=Path,default=Path('/home/jaco/Downloads/Gamemaster_Audio_Pro_Sound_Collection_v1.3_24bit_96k'));args=ap.parse_args()
    plan=json.loads((ROOT/'docs/audio-selection/campaign-plan.json').read_text())
    files={}
    for p in args.library_root.rglob('*'):
        if p.suffix.lower()=='.wav':files.setdefault(p.name,[]).append(p)
    manifest={'collection':'Gamemaster Audio Pro Sound Collection v1.3, 24-bit / 96 kHz','selected_by':'Codex, with owner-delegated creative direction','license_record':'docs/GAMEMASTER_AUDIO_REVIEW.md','distribution':'Only embedded in the game. Reusable licensed audio excluded from source archives. Original masters unchanged. No external upload or AI training.','review':'Source descriptions and objective signal checks; subjective listening acceptance remains separate.','sources':{},'assets':{},'cues':{},'rooms':{}}
    prior_path=ROOT/'docs/audio-selection/campaign-provenance.json'
    prior=json.loads(prior_path.read_text()).get('sources',{}) if prior_path.exists() else {}
    cached={}
    def source(key):
        if key in cached:return cached[key]
        spec=plan['sources'][key]
        if spec.get('prepared'):
            p=ROOT/spec['prepared'];info=sf.info(p);x,rate=sf.read(p,dtype='float32',always_2d=True)
            origin=json.loads((ROOT/'docs/audio-selection/opening-provenance.json').read_text())['assets'][key]
            entry={'source_file':origin['source_file'],'source_sha256':origin['source_sha256'],'prepared_input':spec['prepared'],'prepared_sha256':sha(p),'selected_by':'Jaco','role':spec['role'],'processing':'Reuse approved opening preparation without changing it.'}
        else:
            matches=files.get(spec['file'],[])
            if len(matches)!=1:raise ValueError('Need exactly one licensed master: '+spec['file'])
            p=matches[0];info=sf.info(p)
            if info.samplerate!=96000 or info.subtype!='PCM_24':raise ValueError('Expected selected 24-bit / 96 kHz master: '+key)
            if key in prior and sha(p)!=prior[key]['source_sha256']:raise ValueError('Selected master identity changed: '+key)
            x,rate=sf.read(p,frames=min(info.frames,info.samplerate*120),dtype='float32',always_2d=True)
            g=int(np.gcd(rate,RATE));x=resample_poly(x,RATE//g,rate//g).astype('float32');rate=RATE
            x=sosfilt(butter(2,45,fs=RATE,btype='highpass',output='sos'),x,axis=0).astype('float32')
            if spec['kind']=='bed':x=sosfilt(butter(2,6500,fs=RATE,output='sos'),x,axis=0).astype('float32')
            entry={'source_file':str(p),'source_sha256':sha(p),'source_rate':info.samplerate,'source_subtype':info.subtype,'source_seconds':info.duration,'used_seconds':len(x)/RATE,'selected_by':'Codex','role':spec['role'],'processing':'First 120 seconds maximum, polyphase resampling to 48 kHz, 45 Hz high-pass; ambience low-pass 6.5 kHz; mono duplicated to stereo.'}
        if x.shape[1]==1:x=np.repeat(x,2,axis=1)
        assert x.shape[1]==2 and rate==RATE and np.isfinite(x).all() and np.max(np.abs(x))>1e-7,key
        manifest['sources'][key]=entry;cached[key]=x;return x
    DEST.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory() as temp:
        def encode(id,x,kind,used,recipe):
            peak=float(np.max(np.abs(x)))
            attenuation=min(1,10**(-4/20)/max(peak,1e-9));x*=attenuation
            wav=Path(temp)/(id+'.wav');sf.write(wav,x,RATE,subtype='PCM_24')
            target=DEST/(id+'.ogg')
            subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','5',str(target)],check=True)
            y,sr=sf.read(target,always_2d=True,dtype='float32');assert sr==RATE and np.isfinite(y).all() and np.max(np.abs(y))<.9
            manifest['assets'][id]={'path':str(target.relative_to(ROOT)),'sha256':sha(target),'kind':kind,'source_ids':sorted(set(used)),'recipe':recipe,'limiting_gain_db':db(attenuation),'sample_rate':sr,'channels':y.shape[1],'duration_seconds':len(y)/sr,'peak_dbfs':round(db(np.max(np.abs(y))),3),'rms_dbfs':round(db(np.sqrt(np.mean(y*y))),3),'seam_delta':float(np.max(np.abs(y[-1]-y[0])))}
            wav.unlink();return 'res://'+str(target.relative_to(ROOT))
        config=json.loads((ROOT/'content/audio-score.json').read_text())
        for index,(room,profile) in enumerate(plan['rooms'].items()):
            count=RATE*90;x=np.zeros((count,2),dtype='float32');used=[];rng=np.random.default_rng(20261114+index)
            for layer in profile['beds']:
                key=layer['source'];a=source(key).copy();used.append(key)
                if 'gain_db' in layer:a*=10**(layer['gain_db']/20)
                else:a*=10**(layer['rms_dbfs']/20)/max(float(np.sqrt(np.mean(a*a))),1e-9)
                n=min(int(.08*RATE),len(a)//4);ramp=np.linspace(0,1,n,dtype='float32')[:,None];a[:n]=a[-n:]*(1-ramp)+a[:n]*ramp;a=a[:-n]
                phase=0 if room=='ch1_l1' else int(rng.integers(0,len(a)))
                x+=a[(np.arange(count)+phase)%len(a)]
            for event in profile.get('events',[]):
                key=event['source'];a=source(key).copy();used.append(key)
                a*=10**(event['peak_dbfs']/20)/max(float(np.max(np.abs(a))),1e-9)
                n=min(96,len(a)//4);a[:n]*=np.linspace(0,1,n)[:,None];a[-n:]*=np.linspace(1,0,n)[:,None]
                t=event.get('start',float(rng.uniform(2,9)))
                while t<89:
                    start=int(t*RATE);length=min(len(a),count-start);x[start:start+length]+=a[:length]
                    t+=float(rng.uniform(*event['interval']))
            n=int(.12*RATE);ramp=np.linspace(0,1,n,dtype='float32')[:,None];x[:n]=x[-n:]*(1-ramp)+x[:n]*ramp;x=x[:-n]
            cue='room_'+room;path=encode(cue,x,'ambience',used,{'profile':profile,'final_seam_crossfade_ms':120,'runtime_default_bus_gain_db':db(.48*.5)})
            entry={'path':path,'gain_db':0,'description':profile['description']};config['ambience'][cue]=entry;config['location_ambience'][room]=cue;manifest['rooms'][room]=cue
            print(room,profile['description'],flush=True)
        for cue,spec in plan['effects'].items():
            if 'opening' in spec:
                original=json.loads((ROOT/'content/hidden-object-audio.json').read_text())['cues'][spec['opening']]
                entry={'path':original['path'],'gain_db':min(0,original['volume_db']-db(.7*.8)),'pitch_range':[1,1],'cooldown_seconds':.1,'description':spec['description']}
                source(spec['opening'])
            else:
                paths=[]
                for index,key in enumerate(spec['sources']):
                    a=source(key).copy();a*=10**(-6/20)/max(float(np.max(np.abs(a))),1e-9)
                    n=min(144,len(a)//4);a[:n]*=np.linspace(0,1,n)[:,None];a[-n:]*=np.linspace(1,0,n)[:,None]
                    paths.append(encode(cue+'_'+str(index+1),a,'sfx',[key],{'edge_fades_ms':3,'peak_target_dbfs':-6}))
                entry={'path':paths[0],'variants':paths,'gain_db':spec['gain_db'],'pitch_range':[1,1],'cooldown_seconds':.18,'description':spec['description']}
            config['sfx'][cue]=entry;manifest['cues'][cue]=entry
        config['campaign_audio_manifest']='res://docs/audio-selection/campaign-provenance.json'
        (ROOT/'content/audio-score.json').write_text(json.dumps(config,indent=2,ensure_ascii=False)+'\n')
        manifest['generator']='tools/prepare_campaign_audio.py';manifest['generator_sha256']=sha(ROOT/manifest['generator'])
        manifest['plan_sha256']=sha(ROOT/'docs/audio-selection/campaign-plan.json')
        (ROOT/'docs/audio-selection/campaign-provenance.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
        print('CAMPAIGN_AUDIO_PREPARED',len(manifest['sources']),len(manifest['assets']),flush=True)
if __name__=='__main__':main()
