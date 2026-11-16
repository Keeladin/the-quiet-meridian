# Three-voice audition and fidelity review

Status: three spoken auditions captured; no listening acceptance or runtime voice integration is claimed by this record. The user requested OpenAI GPT Live, with Atlas inspected only as a read-only reference. The earlier Runway proposal is superseded; no Runway generation or subscription/credit purchase is authorized. OpenAI model/voices and pricing have been verified. The user approved US$0.25 for exactly three first takes, no retakes, and read-only reuse of the existing Atlas key; see `VOICE_AUDITION_APPROVAL.json`. The user then explicitly approved one replacement Iona request and one replacement Rowan request within the same cap; both have been used. Those specific exceptions are recorded in `VOICE_AUDITION_SUPPLEMENT.json` and `VOICE_AUDITION_ROWAN_SUPPLEMENT.json`.

## Initial capture and review results — 14 November 2026

Five requests produced three spoken candidates and two retained silent failures.
Final receipts report **117 active seconds**, giving **US$0.0975** at the published
rate. Conservative per-attempt upward rounding records US$0.097501 in the ledger.
This is a calculation from provider usage, not an invoice or tax calculation.
All receipts are final; the unchanged approved cap is US$0.25. No further request
is authorized. The full 98-clip production batch has not been approved.

| Request | Reported seconds | Result |
| --- | ---: | --- |
| Iona / Willow, original | 0 | Rejected: missing nullable `delegation_id`; no speech, zero charge. |
| Rowan / Stone, original | 30 | Rejected: instructions acknowledged without speech; US$0.025 of silence. |
| Mara / Quartz, first take | 31 | Complete 59-word provider transcript and sound-integrity pass; independent audio text matches; listening pending. |
| Iona / Willow, authorized replacement | 23 | Complete 40-word provider transcript and sound-integrity pass; independent ASR heard “Mary” for “Mara” at 0.84–1.48 seconds. Pronunciation hold. |
| Rowan / Stone, authorized replacement | 33 | Complete 68-word provider transcript and sound-integrity pass; independent ASR spelled “Tomas” as “Thomas” at 4.66–5.00 seconds. Pronunciation hold. |

The first protocol error was corrected against the official schema. The second
failure exposed that an instructions acknowledgment does not trigger speech.
The successful captures use the documented speak-first startup/commentary
sequence, with input audio active before commentary. No source wording was
changed to make a transcript pass.

Independent ASR hallucinated a trailing “You” over exact-zero PCM in both Mara
and Rowan. The raw reports remain intact. Mara was rechecked on an analysis copy
that retains every original nonzero sample plus one second of zero tail; all 59
words match. Rowan's zero-tail evidence is recorded separately; neither proper
name was silently normalized. ASR spelling is not conclusive pronunciation
judgment, so these names remain on hold for listening.

All original WAVs, filtered events, provider transcripts, requests, usage ledger,
approvals and independent review evidence are local in
`assets/audio/auditions/2026-11-14/`, excluded from runtime import by `.gdignore`.
`VOICE_AUDITION_RESULTS.json` indexes the hashes and outstanding holds.
`tools/build_voice_audition_preview.py` creates an offline player and a separate
ZIP with all three unedited masters. No recording has been promoted into the
runtime voice manifest; production coverage remains **0/98**.

The previews are for the user to hear and evaluate before authorizing any more
recording. Performance quality, accent suitability, pacing, pronunciation and
full listening fidelity are not established by the transcript/signal checks.

## User performance feedback and revised Mara

The user listened and requested natural conversational delivery, finding the
first candidates book-like. One separately approved Mara retake has been
captured with the same Quartz voice and exact 59 words. Provider and independent
word checks pass; the user’s judgment of naturalness remains pending. Total
computed usage across both rounds is about US$0.1242, within the unchanged
US$0.25 cap. All current approvals are used. See `VOICE_NATURAL_DIRECTION.md`
and `VOICE_NATURAL_RESULT.json`; the original evidence is not rewritten.

## Original audition boundary

The user approved only these three representative first takes under a US$0.25 cap. Use a separate clean voice session for each character, with one explicit requested response and no microphone input or conversational history. Keep performance directions outside the text to be spoken. Present all three local recordings for the user to hear; do not record the remaining 95 clips, choose additional paid auditions or infer full-cast approval before the user accepts the samples and authorizes the next batch. Approval to spend previously offered Runway credits does not authorize the new API calls.

These are complete existing lines, not rewritten audition prose or abbreviated excerpts. Accepted samples may later become their corresponding game clips. Together they contain **930 Unicode characters and 167 whitespace-delimited words**, excluding directions. Deliberate natural delivery is approximately 75–90 seconds total. The per-clip planning ceilings sum to 110 seconds; they are budget/safety bounds, not instructions to pad recordings with silence or proof that a clipped take is complete.

## Exact sample scripts

### Iona Vale — `ch1_closing`

Speaker ID: `iona`. 219 Unicode characters; 40 whitespace-delimited words.

Canonical UTF-8 SHA-256: `c3498c81470d4454353081894e1d13d95a7ddd934d60459531184fc3bf84468a`.

Performance direction: Restrained investigative narration; warm clarity, growing certainty without triumph. Keep the final image understated.

Pacing estimate: About 17–21 seconds at 120–145 words/minute; allow up to 25 seconds in the audition budget.

Exact spoken script:

> Mara was not taken from Leth. She borrowed the bell key, recovered a removed folio, and followed a record of the old flood toward the pumping works. The tide and the official story disagree by more than a smudged digit.

### Rowan Pike — `rowan_kitchen_r2`

Speaker ID: `rowan`. 363 Unicode characters; 68 whitespace-delimited words.

Canonical UTF-8 SHA-256: `e16770e007d094d9b8e5ecf2bdd33c93ab7e424b96220ea221417709443ed31b`.

Performance direction: An older lockkeeper taking responsibility. Slow, contained shame; a firmer turn on “I will not give you one of those.” No sobbing, theatrical growl, added sigh, or added words.

Pacing estimate: About 31–37 seconds at 110–130 words/minute; allow up to 45 seconds in the audition budget.

Exact spoken script:

> That I shut the lower footway barrier. That I unfastened it when Tomas called, while he opened the separate upper footway gate. That acting later did not make the earlier closure harmless. I have spent seventeen years rehearsing explanations that end with me having no choice. I will not give you one of those. Ask me what I saw. If I do not know, make me say so.

### Mara Venn — `mara_refuge_r0`

Speaker ID: `mara`. 348 Unicode characters; 59 whitespace-delimited words.

Canonical UTF-8 SHA-256: `cda31d0a99e724fb1f3488d59069716cace6b509531960347683a74608a196bd`.

Performance direction: Vulnerable admission to someone she hurt. Careful first sentences, a slight loss of composure at “I frightened you,” then a quiet, complete final thought. Avoid breathy melodrama.

Pacing estimate: About 25–30 seconds at 118–142 words/minute; allow up to 40 seconds in the audition budget.

Exact spoken script:

> I thought you would understand the letter. Then I thought another letter would lead someone here. Each explanation made the next day of silence easier to justify. I frightened you because I was frightened, and because being useful felt safer than admitting I needed help. I can explain it. I cannot turn that explanation into something you owed me.

## Proposed pronunciation reference

These fictional-name choices are creative pronunciation guidance, not substitutions in the transcript or subtitles. Keep them in a non-spoken direction field. Confirm them by listening before carrying them across the cast.

| Name in these samples | Proposed pronunciation | Check |
| --- | --- | --- |
| Mara | MAH-ruh, first syllable stressed | The narrator says it naturally; no explanatory spelling is spoken. |
| Leth | leth, rhyming with “death” | Final unvoiced “th” is audible. |
| Tomas | TOH-muhs, first syllable stressed | Rowan uses the same name consistently; no “Thomas” textual replacement is made. |

The remaining cast-wide pronunciation sheet should also fix Iona, Nadi, Elian, Ada, Sera, Venn, Quill and Meridian before full production. A consistent preset per character and session isolation are useful controls, but do not by themselves establish consistent performance. Final preset identities must come from the confirmed OpenAI implementation/docs, not from the obsolete provider casting.

## Capture integrity and deterministic rejection

1. Pin the script ID, original text hash, selected voice and complete non-spoken directions before requesting audio. Save an immutable request record without secrets. Never take the legacy `spoken_text` value containing `[sighs]` as literal dialogue; these three sample requests speak exactly `text`.

2. Bind every audio chunk, transcript chunk and completion event to one session. Preserve event order and returned format metadata. Reject a provider error, unsuccessful/incomplete session finalization, token/time cutoff, connection loss, mixed session identifiers, unconfirmed session finalization or missing final audio tail, empty transcript, or an audio buffer with incomplete PCM frames. Use the actual verified API event names in the adapter; this document does not invent a GPT Live event schema.

3. Preserve the original received audio master and raw returned transcript. Decode the final local recording, check its duration/sample rate/channels, and calculate its SHA-256. Reject corrupt, empty, silent or materially clipped audio. Duration and silence thresholds can flag suspicious captures, but cannot prove that every word was spoken. Do not accept a cutoff merely because the paid budget was reached.

4. Compare the returned transcript with the canonical script as word-token sequences. Normalize only Unicode punctuation/case/whitespace and non-spoken sentence punctuation. Retain all pronouns, contractions, negation and repeated words. Do not rewrite numbers or expand contractions: `17` differs from `seventeen` and requires a listening investigation, not automatic acceptance. Record normalization rules and the raw text. Require zero insertions, deletions or substitutions after those narrow rules; report the edit positions. No fuzzy-similarity threshold, synonym allowance or automatic paraphrase correction may promote a take.

5. Explicitly reject introductions, speaker labels, “Here is…”, spoken direction tags, omitted first/last words, duplicated phrases, commentary after the line, or altered testimony. A local transcript mismatch is a failed candidate until a listener establishes that the discrepancy was transcription error and records the exact decision. A retake remains subject to the approved spending cap; failures do not grant unlimited automatic retries.

## Acoustic verification and user listening gate

A matching provider transcript is not proof that its accompanying waveform contains the same words. The provider may transcribe its intended output while the captured audio is incomplete. Conversely, independent ASR may misrecognize a correctly spoken fictional name. Treat the two as evidence with different failure modes.

For each take, obtain a separate transcription from the saved audio with an approved, locally available offline recognizer if one exists, then run the same strict token comparison. Any additional local recognizer must stay inside the repository, have its model/license provenance recorded, and be identified in the toolchain; system packages and user-wide configuration remain untouched. Do not use a paid transcription endpoint or claim an independent transcript when none was obtained. A paid transcription call would need to fit the separately approved cap and be disclosed in the estimate.

A listener must hear each complete sample while following the exact script, including its first word and fully released final word. Check missing/added words, the pronunciation reference, breaths, pacing, emotional appropriateness, artifacts, unwanted introductions and abrupt cuts. Any added or missing speech requires rejection/retake. Record whether independent ASR was used and which discrepancies were resolved by direct listening. User audition approval is also needed for the proposed character identity and delivery; an automated pass cannot supply that approval.

Forced alignment of the expected script is not a fidelity test: an aligner can fit supplied words to the wrong audio. Use alignment only after verbatim speech is accepted, then inspect boundaries to create subtitle timings. Preserve the complete original text regardless of whether timed captions are ready.

## Candidate records and integration gate

Each candidate should retain script ID/hash, exact request text and directions, model and voice, capture date, request/response IDs, actual usage and cost receipt, approved budget reference, audio format/duration/hash, raw/provider transcript, independent-audio transcript when available, normalized token diff, capture/signal results, human listening notes, rejection reasons, processing steps and applicable commercial-use terms. Store no API keys, authorization headers or session credentials.

Keep unaccepted candidates outside the runtime voice paths, and label them audition candidates. Do not populate a production `path` merely because audio was returned. Once the user accepts the audition and production is authorized, promote reviewed local assets into `assets/audio/voice/` with measured duration and source-exact subtitles. Any trimming or loudness processing must retain the original master and be checked again for clipped words.

The existing AudioDirector accepts local WAV/Ogg/MP3 recordings and already supplies transcript fallback, independent voice volume, ducking, replay/skip and cancellation. Preserve these behaviors and reduced-motion speaking controls. Final Windows/Linux packages must contain the audio and require no API key, account, network, Atlas process or model service. Re-run the relevant integrity, playback, subtitle, skip/replay and packaged-resource checks after accepted recordings are integrated.
