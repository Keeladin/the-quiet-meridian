#!/usr/bin/env python3
"""Make level-matched offline candidates from saved gateway masters; no API calls."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import wave

from voice_fidelity import analyze_pcm

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', type=Path, required=True)
    args = parser.parse_args()
    work = ROOT / 'work/gateway-voice'
    output = work / 'candidates'
    output.mkdir(parents=True, exist_ok=True)
    adjustments_path = ROOT / 'docs/voice-production/tempo-adjustments.json'
    adjustments = json.loads(adjustments_path.read_text())['clips'] if adjustments_path.exists() else {}
    for receipt_file in sorted((ROOT / 'docs/voice-production/receipts').glob('*.json')):
        receipt = json.loads(receipt_file.read_text())
        identity = receipt['id']
        adjustment = adjustments.get(identity, {})
        tempo = float(adjustment.get('factor', 1.0))
        assert 0.5 <= tempo <= 2.0
        record_file = output / (identity + '.json')
        if record_file.exists() and json.loads(record_file.read_text()).get('tempo_factor', 1.0) == tempo:
            continue
        source = work / 'masters' / (identity + '.wav')
        if not source.exists():
            continue
        assert sha(source) == receipt['result']['wav_sha256']
        if adjustment: assert adjustment['source_sha256'] == sha(source)
        with wave.open(str(source)) as stream:
            assert stream.getnchannels() == 1 and stream.getsampwidth() == 2
            pcm = stream.readframes(stream.getnframes())
            rate = stream.getframerate()
        integrity = analyze_pcm(pcm, rate, expected_text=receipt['spec']['text'])
        if not integrity['passed']:
            print(json.dumps({'clip':identity,'status':'signal_hold','reasons':integrity['reasons']}),flush=True)
            continue
        common = [str(args.ffmpeg), '-nostdin', '-hide_banner', '-y', '-i', str(source), '-vn']
        tempo_filter = f'atempo={tempo},' if tempo != 1.0 else ''
        analysis = subprocess.run(common + ['-af', tempo_filter + 'loudnorm=I=-20:TP=-2:LRA=9:print_format=json', '-f', 'null', '-'],
                                  capture_output=True, check=True, text=True).stderr
        measurements = json.loads(analysis[analysis.rfind('{'):analysis.rfind('}')+1])
        filter_spec = ('loudnorm=I=-20:TP=-2:LRA=9:linear=true:print_format=json:'
            'measured_I={input_i}:measured_TP={input_tp}:measured_LRA={input_lra}:'
            'measured_thresh={input_thresh}:offset={target_offset}').format(**measurements)
        normalized = output / (identity + '-normalized.wav')
        converted = subprocess.run(common + ['-af',tempo_filter+filter_spec,'-ar',str(rate),'-ac','1','-c:a','pcm_s16le',str(normalized)],
                                   check=True, capture_output=True, text=True)
        output_measurements = json.loads(converted.stderr[converted.stderr.rfind('{'):converted.stderr.rfind('}')+1])
        with wave.open(str(normalized)) as stream:
            normalized_pcm = stream.readframes(stream.getnframes())
            duration = stream.getnframes() / stream.getframerate()
        assert abs(duration - integrity['duration_seconds'] / tempo) < 0.05
        normalized_signal = analyze_pcm(normalized_pcm,rate)
        assert normalized_signal['passed'], identity
        encoded = output / (identity + '.ogg')
        subprocess.run([str(args.ffmpeg),'-nostdin','-hide_banner','-loglevel','error','-y','-i',str(normalized),
                        '-map_metadata','-1','-c:a','libvorbis','-q:a','5',str(encoded)],check=True)
        decoded = subprocess.run([str(args.ffmpeg),'-nostdin','-hide_banner','-loglevel','error','-i',str(encoded),
                                  '-f','s16le','-ac','1','-ar',str(rate),'-'],capture_output=True,check=True).stdout
        encoded_signal = analyze_pcm(decoded,rate)
        assert encoded_signal['passed'] and abs(encoded_signal['duration_seconds']-duration)<0.1
        record={'clip_id':identity,'source_sha256':sha(source),'encoded_sha256':sha(encoded),
            'normalized_pcm_sha256':sha(normalized),'duration_seconds':duration,'sample_rate':rate,
            'processing':(f'Owner-requested pitch-preserving FFmpeg atempo={tempo}; ' if tempo != 1.0 else '')
                + 'Two-pass -20 LUFS / -2 dBTP loudness normalization, no word edits or trimming; mono Vorbis quality 5.',
            'tempo_factor':tempo,'source_duration_seconds':integrity['duration_seconds'],
            'input_measurements':measurements,'output_measurements':output_measurements,
            'encoded_signal':encoded_signal,'paid_api_calls':0,'human_listening_required':True}
        record_file.write_text(json.dumps(record,indent=2)+'\n')
        print(json.dumps({'clip':identity,'status':'prepared_candidate','duration':duration}),flush=True)


if __name__ == '__main__':
    main()
