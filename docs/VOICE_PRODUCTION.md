# OpenAI GPT Live voice production

The latest user instruction replaces the earlier Runway proposal. **Do not use
Runway, buy credits, or purchase a subscription.** The development workflow uses
OpenAI API `gpt-live-1`; the released game will contain reviewed local audio and
will not call any service. Existing subtitle, skip/replay, mute and voice-volume
behavior is preserved.

## Current full-game production — 15 November 2026

The owner authorized all 98 current game speech clips and necessary retakes
through Jaco Audio Clips, with a US$6 cumulative gateway allowance including
US$0.15167 already recorded. The allowance was applied using the existing
owner-only budget command; no service restart, credential handoff, subscription
or top-up was performed. See `voice-production/gateway-approval.json` and the
98 exact prepared requests in `voice-production/gateway-quotes.json`.

The original seven-character casting is retained. Every request has scene-specific
conversational direction; narration remains distinct from spoken exchanges.
Saved masters, finalized usage, signal checks and independent offline transcription
are retained. Matching words or successful playback do not approve acting quality.

All 98 canonical lines are now integrated as offline recordings with source-exact
timed subtitles. The correction pass generated 52 additional takes and
selected 31 replacements, retaining the other originals. Phonetic guides
refine name delivery while the game's normal spelling remains unchanged.
Per-take selection and recognition differences are preserved; no transcript was
silently rewritten to match an incorrect recording. Human listening and acting
acceptance remain open, separate from technical playback and word checks.

Confirmed production usage across all saved takes is US$2.761717.
Including earlier gateway usage and the retained US$0.033334 reservation for the
original missing receipt, the total is US$2.946721, leaving
US$3.053279 under the unchanged US$6 allowance. The failed request's
actual usage remains unknown; the owner's audited exception did not invent a
receipt. No subscription, top-up or service restart was needed.

See `VOICE_BATCH_REPORT.md`, `VOICE_REVIEW_SUMMARY.json` and
`voice-production/installed-selection.json` for the complete current record.
The previous first-take report is preserved under `voice-production/checkpoints/`.

Iona’s opening question was separately retaken after the owner heard slurring.
The owner found the replacement clearer but a little slow; the selected delivery
uses an 8% pitch-preserving tempo increase and a fresh acoustic word/timing check.
The original recording remains preserved, and no extra generation was needed.

### Pronunciation references

The generation directions use connected, naturally stressed names: Iona
eye-OH-nuh, Mara MAH-ruh, Tomas TOH-muhs, Nadi NAH-dee, Elian ELL-ee-uhn,
Ada AY-duh, Sera SEH-ruh, Rowan ROH-uhn, and Leth with a short E and final TH.
The normal names remain in every game script and subtitle. Detailed IPA and
word-specific directions are retained in each retake receipt. Recognition
spellings alone cannot prove pronunciation: unresolved name/accent readings
are identified individually in the installed selection for gameplay feedback.

The sections below preserve the earlier audition history. Their exhausted sample
scopes do not describe the newly authorized production batch. New recordings use
the gateway tools, not the historical Atlas credential/recorder workflow.

## Historical approved audition scope

The user approved **US$0.25 maximum, exactly three first takes, no retakes** and
read-only reuse of Atlas's existing OpenAI key without exposing or storing it.
`VOICE_AUDITION_APPROVAL.json` records the exact authorization and binds it to
`content/voice-audition.json`. Two specific replacement requests were later
approved separately after silent failures: one for Iona and one for Rowan. Both
have now been used, with the original failures retained. The unchanged cap is
US$0.25; no further requests or the remaining 95 clips are authorized.

The initial three spoken auditions are available. Their five requests report 117 billed seconds,
or US$0.0975 computed at the published rate (US$0.097501 with conservative
per-attempt rounding). Mara’s independent text check matches; Iona’s first “Mara”
and Rowan’s “Tomas” need listening review. None is accepted into the game.
See `VOICE_SAMPLE_REVIEW.md` and `VOICE_AUDITION_RESULTS.json` for full evidence.

| Sample | Voice | Delivery | Script words |
| --- | --- | --- | --- |
| Iona: chapter-one closing | Willow | Warm, restrained investigative narration | 40 |
| Rowan: admission | Stone | Weathered remorse and quiet accountability | 68 |
| Mara: refuge admission | Quartz | Tired precision and vulnerability | 59 |

The three full source lines total 167 words. Approximately 75–90 seconds of
speech plus setup, pauses and closing gives an expected **US$0.10–$0.15** first
pass. Official price checked 14 November 2026: **US$0.05 per active session
minute, billed per second**, including silence. No backend model/tool calls or
paid transcription are included or authorized. Each take reserves 90 seconds
including closure, or US$0.075; the three reservations total US$0.225. The
recorder initiates closure before its total deadline and stops all subsequent
work if final usage/closure cannot be confirmed. These are local spending
controls; OpenAI does not document a provider-enforced per-session dollar cap.

Sources:
- https://developers.openai.com/api/docs/models/gpt-live-1
- https://developers.openai.com/api/docs/guides/voice-latency-cost?api=live
- https://developers.openai.com/api/docs/guides/live-conversations
- https://developers.openai.com/api/reference/resources/live/primary-websocket

## Conversational performance revision

The user heard the first candidates and requested more realistic, natural speech,
finding their delivery too much like book narration. A separate one-use approval
authorized one revised Mara/Quartz take, at most US$0.05 additional within the
same US$0.25 total cap. Its manifest, approval, fixed output ledger and carried
prior spending are separate and hash-bound; the first round is immutable.

That retake now exists, with exact provider words and a matching independent
ASR check on a nonzero-preserving analysis copy. It uses personal scene direction,
varied pauses and natural unvoiced breathing while retaining all 59 words.
The user must still judge the acting. Cumulative receipts report 149 seconds:
computed US$0.1241667, conservatively rounded ledger total US$0.124168. All current
take approvals are used; no further generation is authorized. See
`VOICE_NATURAL_DIRECTION.md`, `VOICE_NATURAL_RESULT.json` and the local A/B player
at `builds/previews/voice-natural/index.html`.

## Read-only Atlas reference

The authoritative Atlas source was inspected on the Ubuntu server at
`/srv/jaco/apps/atlas-v6/source/atlas-v6`, Git HEAD
`f79378b05fa575770c4e4915b5380e14e0a49f48`. No source, configuration, database,
service or deployment was modified. GCC was not modified or used.

Relevant files:
- `backend/atlas/whatsapp_voice.py`, SHA-256
  `c971d56f53bf3ad8f0cc76bd0a28f05ca6b1372bc3d12cb740bc6808d275fbc2`:
  primary WebSocket, PCM capture, silence feed, final usage and close handling.
- `backend/atlas/voice.py`, SHA-256
  `2efafed80fda1a628e8b9b391bbaa4b1bf22d26912a4d6e80f993d10024fb5c1`:
  GPT Live/Vesper session integration.

Atlas's prepared-text prompt preserves meaning rather than promising a literal
script. The game uses a separate exact-wording instruction and stricter rejection
checks. It does not import Atlas's modules, history, tools or conversation state.
Key access is a read-only development credential handoff over an existing encrypted
SSH connection into process memory; the key is never printed, written to a file,
placed on a command line, recorded in provenance or included in a game package.

## Independent game workflow

`tools/voice_live.py` defaults to offline planning. Network recording requires an
explicit approved manifest and the development process's API credential. A
persistent locked ledger reserves the full attempt cost before connection;
unknown usage blocks further requests. One clean session per take fixes voice
identity. All received audio is retained, including any unwanted preamble, so
incorrect beginnings cannot be silently hidden. The recorder uses the documented
speak-first sequence: matching developer startup text and one commentary event
after input audio is active. Commentary can paraphrase, so its acknowledgment
does not pass any fidelity or completion gate. Exact request text and prompt
version are retained with each new capture.

Recordings are initially quarantined under ignored `work/voice-auditions/`.
No candidate automatically becomes a production voice path. The runtime manifest
`content/voice-script.json` retains all 98 source-exact lines and the provisional
seven-speaker casting. The original story text is never changed to match a take.
See `VOICE_SAMPLE_REVIEW.md` for full scripts and exact acceptance checks.

GPT Live has no output-audio-done event. Eight seconds of acoustic/transcript
quiet is only an application heuristic; confirmed `session.closed` usage,
complete words, signal checks and listening are separate gates. Transcript
matching alone does not prove that the captured waveform contains every word.
An independent offline transcription is available through
`tools/transcribe_voice_candidate.py`; model and dependency provenance are in
`VOICE_ASR_PROVENANCE.md`. It receives no script or spelling hints.
Failures, paraphrases, introductions, omitted/extra words and truncation are
rejected, not repaired by relabeling the script.

## Provenance and offline integration

For every eventual accepted asset retain canonical text/hash, exact non-spoken
direction, model, voice, request/session identifiers, generation date, usage/cost,
original PCM master/hash, returned transcript, independent transcription/review,
processing steps and applicable terms. Never retain credentials or auth headers.
The API Services Agreement assigns output rights as between the customer and
OpenAI, subject to law and terms; this is not a claim of exclusive copyright.
The applicable API terms are distinct from consumer ChatGPT voice output.
AI-generated voice provenance will be disclosed in the game's credits.

Terms checked 14 November 2026:
- https://openai.com/policies/services-agreement/
- https://openai.com/policies/service-terms/

The owner's full-batch authorization and integration request are recorded above.
Selected Ogg files now live under `assets/audio/voice/`, with exact text and
estimated phrase timing from independent recognition. State, voice, skip/replay,
mixing and both packaged-resource checks are required for each delivery.
The complete 6–10 hour game target, native Windows gameplay testing and manual
full-case playtesting remain acceptance requirements.
