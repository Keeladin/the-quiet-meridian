# Recorded dialogue integration — 15 November 2026

**All 98 canonical speech lines are installed as offline recordings**, across
seven character voices, with 22.199 minutes of selected audio. Opening,
ending, chapter narration and all twelve conversations have recorded coverage.
The source story wording and displayed name spelling are unchanged.

## Corrections and selection

The correction pass generated 52 additional takes. The selected set uses
31 replacement takes and 67 retained originals. Earlier takes,
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
78 selected clips. The other 20 have individual documented decisions
for transcription spelling, names, numbers or connected-word boundaries in
`voice-production/installed-selection.json`. Provider warnings are preserved.
Accepted provider transcript-format exceptions: 1. These are restricted to
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

Private billing receipts and historical review checkpoints are retained by the developer and omitted from this public snapshot.
