"""Document an installed, selected voice batch; no generation or deployment."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import shutil

ROOT=Path(__file__).resolve().parents[1]
DOC=ROOT/'docs/voice-production'
WORK=ROOT/'work/gateway-voice'
def read(p): return json.loads(p.read_text())
def write(p,d): p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n')

def main():
    selection=read(DOC/'installed-selection.json')['lines']
    catalog=read(ROOT/'content/voice-script.json')['lines']
    budget=read(DOC/'correction-final-budget.json')
    assert set(selection)==set(catalog) and len(catalog)==98
    assert budget['authorized_usd']==6 and not budget['billing_review_required']
    captures=read(WORK/'native-review/capture.json')['captures']
    assert len(captures)==4 and all(x['subtitle_visible'] for x in captures)
    receipts={p.name:read(p) for p in (DOC/'receipts').glob('*.json')}
    all_confirmed=round(sum(r['reserved_or_charged_usd'] for r in receipts.values()),6)
    assert abs(all_confirmed+0.151670+0.033334-budget['spent_or_reserved_usd'])<0.000001
    history=DOC/'checkpoints'
    history.mkdir(parents=True, exist_ok=True)
    for name in ['VOICE_BATCH_REPORT.md','VOICE_REVIEW_SUMMARY.json']:
        target=history/('before-corrections-'+name)
        if not target.exists(): shutil.copy2(ROOT/'docs'/name,target)
    installed={}; exact=0; replaced=0; variants=0
    for line_id,choice in selection.items():
        line=catalog[line_id];receipt=receipts[choice['receipt']]
        assert line['status']=='produced' and line['path']
        path=ROOT/line['path'].removeprefix('res://')
        assert hashlib.sha256(path.read_bytes()).hexdigest()==line['audio_sha256']
        report=read(WORK/choice['review_report'])
        assert report['signal']['passed']
        exact+=int(report['independent_comparison']['passed'])
        replaced+=int('-retake' in choice['receipt'])
        variants+=int(choice.get('provider_transcript_format_exception',False))
        installed[line_id]={'clip_id':receipt['id'],'selected_receipt':choice['receipt'],
            'speaker':line['speaker'],'voice':line['voice'],'path':line['path'],
            'audio_sha256':line['audio_sha256'],'duration_seconds':line['duration'],
            'technical_review':choice['technical_review'],
            'independent_exact':report['independent_comparison']['passed'],
            'provider_transcript_format_exception':choice.get('provider_transcript_format_exception',False),
            'signal_passed':True,'installed_in_runtime':True,'human_listening_required':True,'acting_approved':False}
    for name,r in receipts.items():
        stem=Path(name).stem
        for sub,suffix in [('review','small'),('review-medium','medium'),('review-prepared','prepared-medium')]:
            src=WORK/sub/name
            if src.exists(): shutil.copy2(src,DOC/'review'/(stem+'-'+suffix+'.json'))
        conversion=WORK/'candidates'/(r['id']+'.json')
        if conversion.exists():shutil.copy2(conversion,DOC/'review'/(stem+'-conversion.json'))
    retakes=len(receipts)-98
    minutes=round(sum(x['duration'] for x in catalog.values())/60,3)
    summary={'status':'voices_integrated_pending_human_performance_acceptance',
        'canonical_lines':98,'runtime_recordings_installed':98,'saved_first_takes':98,
        'retakes_generated':retakes,'first_takes_replaced':replaced,'remaining_lines':0,
        'selected_independent_exact_matches':exact,'selected_explicit_transcription_decisions':98-exact,
        'provider_format_exceptions':variants,'audio_minutes':minutes,'retake_candidates':[],
        'billing':{'authorized_usd':6,'confirmed_production_usd':all_confirmed,'carry_in_usd':0.151670,
            'unknown_request_reservation_usd':0.033334,'unknown_request_actual_usd':None,
            'spent_or_reserved_usd':budget['spent_or_reserved_usd'],'remaining_usd':budget['remaining_usd'],
            'owner_accepted_unknown_request':True},
        'completed':installed,'human_listening_required':True,'native_windows_tested':False}
    write(ROOT/'docs/VOICE_REVIEW_SUMMARY.json',summary)
    report=f'''# Recorded dialogue integration — 15 November 2026

**All 98 canonical speech lines are installed as offline recordings**, across
seven character voices, with {minutes:.3f} minutes of selected audio. Opening,
ending, chapter narration and all twelve conversations have recorded coverage.
The source story wording and displayed name spelling are unchanged.

## Corrections and selection

The correction pass generated {retakes} additional takes. The selected set uses
{replaced} replacement takes and {98-replaced} retained originals. Earlier takes,
including rejected wording changes and failures, remain preserved with receipts.
Phonetic stress and connected-pronunciation directions were used for names;
critical timeline numbers received explicit spoken-number guidance.
Selected request-only punctuation can add a short word-boundary pause; lexical
and numeric request rewrites are rejected and canonical subtitles stay unchanged.
Iona's opening question, "Do people still remember my father?", also received
an owner-requested diction retake after slurring was reported. Its provider and
independent transcripts match; the revised performance remains open to listening
feedback rather than being certified by text checks alone.
The owner found that retake clearer but a little slow, so its final delivery uses
an 8% pitch-preserving tempo increase, checked again acoustically after encoding.

Independent offline recognition matches the source word sequence exactly for
{exact} selected clips. The other {98-exact} have individual documented decisions
for transcription spelling, names, numbers or connected-word boundaries in
`voice-production/installed-selection.json`. Provider warnings are preserved.
Accepted provider transcript-format exceptions: {variants}. These are restricted to
known phonetic/regional spellings or equivalent time notation, with an independent
matching word check that permits only explicitly listed number formats;
capture errors and actual lexical substitutions cannot use that exception.

No transcript was edited to hide a discrepancy. Source scripts were not rewritten
to match generated speech. Technical selection is not human hearing: pronunciation,
acting, breaths and overall mix still benefit from gameplay listening feedback.
The raw recognizer comparisons and the prior review checkpoints are retained.

## Runtime and verification

Every installed file has a verified master and encoded hash, decoded audio and
signal checks, finalized usage, and source-exact subtitle text. Copies target
−20 LUFS / −2 dBTP without word edits or trimming. The one owner-requested tempo
adjustment is recorded separately with fresh acoustic subtitle timing. Original WAVs are excluded
from runtime import. The game uses only local files and requires no API key,
account or network connection for speech.

Automatic playback, replay, skip, independent voice volume, background ducking
and speech-driven portrait movement use the existing game systems. Four native
Linux captures exercise actual Nadi and Mara dialogue at 1920×1080 and 960×600.
Automated screen captures mute output while checking playback state and visuals.
The full build/export test results accompany the delivery in `verification.json`.
Windows-under-Wine checks are separate from native Windows gameplay acceptance.

## Budget

| Accounting | USD |
| --- | ---: |
| Earlier gateway usage | 0.151670 |
| Confirmed usage across saved production takes | {all_confirmed:.6f} |
| Original missing receipt, reservation retained | 0.033334 |
| Total spent or reserved | {budget['spent_or_reserved_usd']:.6f} |
| Remaining under the approved US$6 cap | {budget['remaining_usd']:.6f} |

The earlier failed request remains explicitly unconfirmed. The owner's exception
retains its full reservation; no actual duration or charge has been invented.
No budget increase, subscription, top-up or server-service restart was performed
for this correction and integration work.
'''
    (ROOT/'docs/VOICE_BATCH_REPORT.md').write_text(report)
    print(json.dumps({'installed':98,'retakes':retakes,'replaced':replaced,'independent_exact':exact,'minutes':minutes,'budget':budget}))

if __name__=='__main__':main()
