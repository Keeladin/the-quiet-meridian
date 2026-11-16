#!/usr/bin/env python3
"""Install an explicitly selected complete offline voice batch; never generates speech."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil

from voice_captions import captions
from voice_fidelity import compare_text
from voice_review import provider_format_warning_only

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return json.loads(path.read_text())


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--selection', type=Path, required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    selected = read(args.selection)['lines']
    path = ROOT / 'content/voice-script.json'
    script = read(path)
    assert set(selected) == set(script['lines']), 'Select exactly all 98 canonical lines'
    receipts = ROOT / 'docs/voice-production/receipts'
    candidates = ROOT / 'work/gateway-voice/candidates'
    prepared = []
    for line_id, choice in selected.items():
        receipt_path = (receipts / choice['receipt']).resolve()
        assert receipt_path.is_relative_to(receipts.resolve()) and receipt_path.suffix == '.json'
        receipt = read(receipt_path)
        line = script['lines'][line_id]
        assert receipt['status'] == 'review_required'
        assert line['spoken_text'] == line['text']
        # Prosodic punctuation may differ; lexical or numeric rewrites may not.
        assert compare_text(line['text'], receipt['spec']['text'])['passed']
        assert receipt['spec']['voice'] == line['voice']
        assert receipt['spec']['script_sha256'] == hashlib.sha256(receipt['spec']['text'].encode()).hexdigest()
        assert receipt['result']['usage_seconds'] is not None
        assert choice['technical_review'] and choice['human_listening_status'] == 'pending'
        clip_id = receipt['id']
        master = ROOT / 'work/gateway-voice/masters' / (clip_id + '.wav')
        encoded = candidates / (clip_id + '.ogg')
        conversion = read(candidates / (clip_id + '.json'))
        review_path = (ROOT / 'work/gateway-voice' / choice.get('review_report', 'review/' + choice['receipt'])).resolve()
        assert review_path.is_relative_to((ROOT / 'work/gateway-voice').resolve())
        review = read(review_path)
        assert receipt.get('issue') is None or (
            choice.get('provider_transcript_format_exception') is True
            and provider_format_warning_only(receipt, review)
        ), 'Unresolved provider warning: ' + line_id
        assert review['clip_id'] == clip_id and review['wav_sha256'] == digest(master)
        assert digest(master) == receipt['result']['wav_sha256'] == conversion['source_sha256']
        assert digest(encoded) == conversion['encoded_sha256'] and conversion['encoded_signal']['passed']
        if conversion.get('tempo_factor', 1.0) != 1.0:
            # Use new acoustic timestamps from the actual stretched delivery,
            # never raw-master caption positions for altered timing.
            assert review.get('asr_input', {}).get('sha256') == digest(encoded)
            assert review['independent_comparison']['passed']
        assert conversion['duration_seconds'] > 0
        prepared.append((line_id, choice, receipt, master, encoded, conversion, review))
    print(json.dumps({'selected':len(prepared),'encoded_bytes':sum(p[4].stat().st_size for p in prepared),'apply':args.apply}))
    if not args.apply:
        return
    voices = ROOT / 'assets/audio/voice'
    masters = ROOT / 'assets/audio/voice-masters'
    voices.mkdir(parents=True, exist_ok=True)
    masters.mkdir(parents=True, exist_ok=True)
    (masters / '.gdignore').touch()
    for line_id, choice, receipt, master, encoded, conversion, review in prepared:
        destination = voices / (line_id + '.ogg')
        archive = masters / master.name
        shutil.copy2(encoded, destination)
        if archive.exists():
            assert digest(archive) == digest(master)
        else:
            shutil.copy2(master, archive)
        line = script['lines'][line_id]
        line.update({'path':'res://' + str(destination.relative_to(ROOT)), 'duration':conversion['duration_seconds'],
            'audio_sha256':digest(destination),'status':'produced','gain_db':0.0,
            'subtitles':captions(line['text'], review['independent_segments'], conversion['duration_seconds']),
            'provenance':{'provider':'OpenAI API via Jaco Audio Clips gateway','model':receipt['spec']['model'],
                'request_id':receipt['id'],'session_id':receipt['session_id'],
                'generated_utc':datetime.fromtimestamp(master.stat().st_mtime, timezone.utc).isoformat(),
                'generated_utc_basis':'Local receipt/download completion time; provider session ID retained separately.',
                'terms_record':'docs/LICENSES.md',
                'commercial_use_basis':'OpenAI API Services Agreement and Service Terms: customer output rights as between the parties, subject to applicable law and terms; no exclusivity claim.',
                'master_path':str(archive.relative_to(ROOT)),'master_sha256':digest(master),
                'request_direction':receipt['spec']['direction'],'receipt':'docs/voice-production/receipts/'+choice['receipt'],
                'request_text_sha256':receipt['spec']['script_sha256'],
                'canonical_text_sha256':line['text_sha256'],
                'request_punctuation_adjusted':receipt['spec']['text'] != line['text'],
                'usage_seconds':receipt['result']['usage_seconds'],'cost_usd':receipt['reserved_or_charged_usd'],
                'processing':conversion['processing'],'technical_review':choice['technical_review'],
                'provider_transcript_format_exception':choice.get('provider_transcript_format_exception',False),
                'human_listening_required':True,'acting_approved':False,
                'caption_timing':'Source-exact phrase captions aligned to independent ASR word positions; display timing requires listening review. Low-confidence alignment falls back to a complete line.'}})
    path.write_text(json.dumps(script,indent=2,ensure_ascii=False)+'\n')


if __name__ == '__main__':
    main()
