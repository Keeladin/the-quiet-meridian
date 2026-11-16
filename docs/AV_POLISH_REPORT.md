# The Quiet Meridian — audiovisual development record

> Current update — 15 November 2026: all 98 story and conversation recordings are
> integrated, with seven character voices and timed subtitles. See
> `VOICE_BATCH_REPORT.md` for correction, selection, budget and listening limits;
> `PLAYER_GUIDE.md` and `DETECTIVE_UPDATE.md` describe current controls and rules.
> Exact final build checks are in the delivered `verification.json`.
> The milestone sections below are historical and may describe superseded
> menus, rules, music or unavailable voices. Native Windows gameplay and human
> performance acceptance remain open.

Status: substantial audiovisual production pass; **not a finished release**.
The prior alpha is preserved at `alpha-before-av-polish`; its packages and
hashes are retained separately. Original full-game scope remains unchanged.

## Implemented

* Nine separately arranged original musical cues total 1,380 seconds (23 minutes):
  title, six chapters, tension and resolution. Individual cues last roughly two
  to three minutes, with contrasting sections, melody, harmony and counterlines.
  Six independent 72-second ambience beds and twelve effects are also included.
* Music and ambience use separate crossfading players. Recorded speech ducks
  background audio smoothly. Music, ambience, voices and effects have independent
  levels; rapid scene changes coalesce to the latest requested cue.
* Thirty-six location-specific animation profiles cover water reflections,
  surface distortion, fog, light, rain/dust, steam and selected working machinery.
  Reduced motion freezes ongoing effects and interaction pulses.
* Seven original transparent expression atlases provide 56 painted poses:
  resting/blinking, speech shapes, concern/relief and explanatory hand gestures.
  Speaking frames now follow decoded voice activity on a separate local bus,
  resting during pauses/silent tails. Music and effects cannot move the mouth;
  reduced motion remains still. Ducking stays stable through sentence pauses.
* A complete 98-line voice script covers seven speaking characters, twelve
  conversations with 36 questions/replies, opening/ending and chapter narration.
  Offline playback, timed-subtitle support, complete transcripts, skip, replay,
  automatic-play preference and separate voice level are integrated.
* Save schema 2 migrates valid schema-1 alpha saves and adds the new preferences.
  Recordings, if produced, will be local files; the game makes no generation calls.

## Voice production is still outstanding

There are **zero accepted runtime voice clips** in this build. Unavailable recordings
are clearly identified in the interface and cannot masquerade as playback.
The user replaced the Runway proposal with OpenAI GPT Live and approved only
three first-take auditions under a US$0.25 cap, then one specific replacement
each for silent Iona and Rowan failures. Three spoken candidates are now
available; computed usage cost is US$0.0975. Audition candidates remain
outside runtime assets until script, listening and user review are complete.
No subscription or credit purchase is authorized; the remaining 95 recordings
require separate approval after the samples are heard. Iona’s first “Mara” and
Rowan’s “Tomas” have unresolved ASR pronunciation holds. Mara’s independent
word check matches; acting and full listening acceptance remain open.
After listening, the user requested more natural conversational delivery. One
separately approved Mara revision is captured and word-checked; acting approval
remains open. Cumulative computed API cost is about US$0.1242. The A/B player
is `builds/previews/voice-natural/index.html`. All current take approvals are used.
See `VOICE_PRODUCTION.md` for the script, casting, approval boundary and sources.

## Validation and previews

Full `tools/game.sh verify` passed on clean implementation revision `73af866`,
including both exports and extracted native Linux / Windows-under-Wine package
checks. Separate extracted graphical opening captures also passed; Wine emitted
an SDR-white-level warning but rendered and exited successfully. The full UI
traversal passes 1,451 headless assertions; native 1280×800 and 960×600 passes
recorded 1,488 assertions before the six final-narration queue assertions were
added. Environment tests pass 1,166 headless / 1,189 native assertions.

`AV_VERIFICATION.json` preserves implementation evidence. The latest exact
package revision and archive hashes are in `builds/verification.json`. The
current follow-up adds audition evidence and targeted animation/mixing checks;
historical evidence is not relabeled as testing those later changes.

The representative score excerpt is
`assets/audio/score/previews/quiet-meridian-score-preview.wav` (60 seconds).
The integrated native-render preview is produced under `builds/previews/`.
Its labels identify voice recordings as pending. It is a presentation sample,
not a player playthrough or proof of a 6–10 hour experience.

## Remaining quality and acceptance gaps

* Full expressive voice production, pronunciation/performance review and final
  listening-based dialogue mix remain incomplete. Three auditions do not
  establish coverage or acceptance for the 98-line game.
* The score is an original synthesized chamber performance. Instrument realism,
  emotional pacing, repetition over several hours and final listening approval
  remain subjective review tasks; it is not a live orchestral recording.
* Portraits use authored expression frames and breathing, not skeletal acting
  or phoneme-aligned lip sync. All 36 environment placements were reviewed and eight defects corrected;
  continuous motion and final art direction still need review. Representative previews do not cover every
  scene, display configuration or hardware combination.
* Native Windows gameplay/audio, a full manual opening-to-ending playthrough,
  and blind first-time 6–10 hour duration testing remain open. Wine execution is
  useful compatibility evidence and does not substitute for native Windows.
* The requested Grim Legends / Enigmatis presentation standard remains an
  acceptance target. This pass must not be described as reaching parity or
  completing the voice/polish request while these gaps remain.

## Speech-aware runtime follow-up

The new voice bus meters decoded local WAV/Ogg audio, separately from music,
ambience and effects. A short onset guard, hysteresis and 130ms release keep
mouth animation from carrying over from an interrupted clip or continuing
through its silent tail. Playback controls/subtitles continue during pauses;
dialogue ducking remains stable. No phoneme-level lip-sync claim is made.

Native Linux and headless checks pass 66 audio assertions and 113 AV UI
assertions, including mute, skip/replay, source changes and both reduced-motion
states. `builds/previews/voice-audition/mara-unapproved-audition.mp4` exercises
the actual renderer and mixer using the **first, unapproved Mara take**. Its
six sentence captions use explicitly unreviewed ASR timing, staged only in
memory. Telemetry confirms speech-driven motion, a resting mouth over the
original silent tail, a still music-only portrait and frozen reduced motion.
The preview’s +6dB audition gain is recorded; its measured mix does not clip.
The user’s later natural-delivery revision is a separate A/B audio preview.

Final package checks and the tested source revision are recorded by
`builds/verification.json`. This follow-up does not waive any full-game,
native-Windows, listening or duration acceptance gates.

## All-location environment review

All 36 locations received native motion, reduced-motion and placement review.
Eight confirmed water/fog/lamp placement defects were corrected and their
scenes recaptured. Every location changes across sampled animated poses; every
reduced-motion frame pair is byte-identical. The untouched 36-scene baseline
and two scoped correction runs remain distinct. `ENVIRONMENT_FULL_REVIEW.md`
records scene-level results, exact hashes and remaining motion/comfort limits.
