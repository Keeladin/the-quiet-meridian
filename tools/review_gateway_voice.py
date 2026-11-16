#!/usr/bin/env python3
"""Review saved gateway WAVs locally. Never calls a provider or approves acting."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import time
import wave

from voice_fidelity import analyze_pcm, compare_text

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')
    temp.replace(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model-dir', type=Path, required=True)
    parser.add_argument('--watch', action='store_true')
    parser.add_argument('--output-subdir', choices=['review', 'review-medium'], default='review')
    parser.add_argument('--only-unmatched', action='store_true')
    parser.add_argument('--cpu-threads', type=int, default=4)
    args = parser.parse_args()
    model_dir = args.model_dir.resolve()
    model_manifest = json.loads((model_dir / 'download-manifest.json').read_text())
    for entry in model_manifest['files']:
        candidate = (model_dir / entry['name']).resolve()
        assert candidate.is_relative_to(model_dir)
        assert digest(candidate) == entry['sha256'], entry['name']
    for key in ['HF_HUB_OFFLINE', 'TRANSFORMERS_OFFLINE', 'HF_HUB_DISABLE_TELEMETRY', 'HF_HUB_DISABLE_IMPLICIT_TOKEN']:
        os.environ[key] = '1'
    os.environ['HF_HOME'] = str(model_dir / '.hf-home')
    os.environ['HF_HUB_CACHE'] = str(model_dir / '.hf-cache')
    from faster_whisper import WhisperModel
    assert 1 <= args.cpu_threads <= 14
    model = WhisperModel(str(model_dir), device='cpu', compute_type='int8', cpu_threads=args.cpu_threads, num_workers=1, local_files_only=True)
    canonical = json.loads((ROOT / 'content/voice-script.json').read_text())['lines']
    receipts = ROOT / 'docs/voice-production/receipts'
    work = ROOT / 'work/gateway-voice'
    while True:
        for path in sorted(receipts.glob('*.json')):
            output = work / args.output_subdir / (path.stem + '.json')
            if output.exists():
                continue
            if args.only_unmatched:
                primary = work / 'review' / (path.stem + '.json')
                if not primary.exists():
                    continue
                prior = json.loads(primary.read_text())
                if prior['independent_comparison']['passed'] or not prior['signal']['passed']:
                    continue
            record = json.loads(path.read_text())
            line_id = path.stem.rsplit('-', 1)[0]
            expected = canonical[line_id]['spoken_text']
            # Recording requests may add punctuation for breath/word boundaries;
            # the canonical lexical sequence must remain completely unchanged.
            assert compare_text(expected, record['spec']['text'])['passed']
            master = work / 'masters' / (record['id'] + '.wav')
            if not master.exists():
                continue
            master_hash = digest(master)
            assert master_hash == record['result']['wav_sha256'], record['id']
            with wave.open(str(master)) as wav:
                assert wav.getnchannels() == 1 and wav.getsampwidth() == 2
                rate = wav.getframerate()
                pcm = wav.readframes(wav.getnframes())
            signal = analyze_pcm(pcm, rate, expected_text=expected)
            provider = compare_text(expected, record['result'].get('transcript', ''))
            # The recognizer receives no script, names, phonetic hints or hotwords.
            stream, info = model.transcribe(str(master), language='en', task='transcribe', beam_size=5,
                temperature=0.0, condition_on_previous_text=False, initial_prompt=None, prefix=None,
                hotwords=None, vad_filter=False, word_timestamps=True)
            segments = []
            for segment in stream:
                segments.append({'start': segment.start, 'end': segment.end, 'text': segment.text,
                    'words': [{'word': w.word, 'start': w.start, 'end': w.end, 'probability': w.probability}
                              for w in segment.words or []]})
            transcript = ' '.join(s['text'].strip() for s in segments).strip()
            acoustic = compare_text(expected, transcript)
            assert digest(master) == master_hash
            passed = signal['passed'] and provider['passed'] and acoustic['passed'] and record.get('issue') is None
            result = {'line_id': line_id, 'clip_id': record['id'], 'source_text_sha256': canonical[line_id]['text_sha256'],
                'master': str(master.relative_to(ROOT)), 'wav_sha256': master_hash, 'signal': signal,
                'provider_comparison': provider, 'independent_transcript': transcript, 'independent_segments': segments,
                'independent_comparison': acoustic, 'model': {'repository': model_manifest['repository'], 'revision': model_manifest['revision']},
                'asr_settings': {'device':'cpu','compute_type':'int8','initial_prompt':None,'hotwords':None,'offline':True},
                'checks_passed': passed, 'status':'candidate_checks_passed_pending_listening' if passed else 'review_hold',
                'human_listening_required': True, 'acting_approved':False, 'paid_api_calls':0}
            atomic_json(output, result)
            print(json.dumps({'line':line_id,'clip':record['id'],'status':result['status'],
                'signal':signal['passed'],'provider_match':provider['passed'],'asr_match':acoustic['passed']}),flush=True)
        if not args.watch or (work / 'generation-finished.json').exists():
            break
        time.sleep(2)


if __name__ == '__main__':
    main()
