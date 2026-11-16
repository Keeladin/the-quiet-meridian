# The Quiet Meridian — quality record

> Current update — 15 November 2026: all 98 story and conversation recordings are
> integrated, with seven character voices and timed subtitles. See
> `VOICE_BATCH_REPORT.md` for correction, selection, budget and listening limits;
> `PLAYER_GUIDE.md` and `DETECTIVE_UPDATE.md` describe current controls and rules.
> Exact final build checks are in the delivered `verification.json`.
> The milestone sections below are historical and may describe superseded
> menus, rules, music or unavailable voices. Native Windows gameplay and human
> performance acceptance remain open.

Status: development alpha; acceptance testing remains open.

## Hidden-object campaign conversion — 14 November 2026

The current campaign branch supersedes the three-hotspot exploration interface
with 36 actual picture searches and 507 listed finds. Earlier records below
describe historical milestones, not the current search controls. See
`CAMPAIGN_SEARCH_REPORT.md` and the current `builds/verification.json`.

The integrated forward/reverse state traversal passes 5,602 assertions; the
presentation traversal passes 1,906. Search geometry passes 1,651 checks;
new partial-save/reward/migration tests pass 46. Search presentation passes
1,170 headless and 1,173 native checks, including actual picture selection,
keyboard zoom, cooldown persistence and room rewards. Native captures cover
960×600, 1280×800 and 1920×1080. All 46 prepared campaign Ogg files were also
independently decoded and matched their recorded peak/RMS measurements without
clipping. Exact final package results are in the machine-readable build report.

These are automated functional and visual checks. They do not establish
6–10 hours of play, subjective sound quality, search difficulty, native Windows
acceptance or completed voice acting. Those release gates remain open.

## Hotspot and material Foley follow-up — 14 November 2026

The reported examined-object circles are fixed, with pixel comparisons showing
no normal-view marker pixels and retained hover/keyboard/F1 navigation. Tests
pass 384 headless and 386 native assertions, including save/reload. Native
windows were checked at 1280×800 and 1920×1080 (the latter uses 1728×1080 content
inside 16:10-preserving side bars).

The new CC0 Foley set contains 49 variations across 18 cues; explicit authored
mapping covers 108 evidence points, 36 destinations, 12 recipes and 60 puzzles.
The real-action routing suite passes 504 checks; the audio director passes 92
checks headlessly and natively. Provenance and signal audits pass 1,152 Foley
and 558 score assertions. Repeated builds yield identical Foley derivatives.
An opening-only native movie records the actual UI and mixer; a separate local
listening gallery compares legacy and new effects. See `SFX_POLISH_REPORT.md`.
Full package results and the exact revision are in `builds/verification.json`.
Listening acceptance, native Windows gameplay and blind playtime remain open.

## Audiovisual production evidence — 14 November 2026

The preserved earlier alpha is tagged `alpha-before-av-polish`. The audiovisual
pass adds original score/ambience/effects, painted expression frames, location
effects and offline voice integration. Production voice coverage is **0/98**;
the OpenAI audition stage is separate from runtime acceptance. Voice production
is an explicit incomplete requirement.

At implementation checkpoint `73af866`, isolated suites passed 4,946 state assertions including valid v1-save migration,
47 audio-director behavior checks, 77 character checks, 1,166 environment checks,
105 voice-UI integration checks, 528 score/provenance/signal checks, 263 art
provenance checks and 1,479
voice-script checks. Those voice runtime tests used test-only tones; they do not prove
voice acting quality, pronunciation or a real dialogue mix.

The complete known-answer UI traversal passed 1,451 headless assertions and
1,488 assertions at both native Linux 1280×800 and 960×600. It still resolves all
60 investigations and visits all 36 conversation topics. Captures and logs are
under `work/av-ui-review-1280`, `work/av-ui-review-960`, and `work/av-ui-*.log`.
Exact final package checks are recorded by the subsequent verification run in
`builds/verification.json`; historical results below describe earlier revisions.

A 40-second native engine movie under `builds/previews/` records the actual
AudioDirector mix, water/fog/machinery, Nadi's blink and explanation gesture,
reduced motion and resolution cue. The final eight seconds spoil the ending.
Its capture manifest distinguishes staged presentation from gameplay and marks
voices pending. See `AV_POLISH_REPORT.md` for remaining quality limits.

## Recorded development evidence — 14 November 2026

* First complete verification passed engine version, content/audio audit,
  resource import, state progression, source startup, both exports, archive
  integrity, extracted Linux execution and extracted Windows execution under
  Wine. Both package smoke modes also wrote, replaced, restored and removed an
  isolated save probe and its backup.
* The state suite passed 4,917 assertions, including forward/reverse complete
  case traversal and a save/load roundtrip after every puzzle.
* Native Linux Compatibility rendering completed scripted UI traversal at
  960×600, 1280×800 and 1668×1043: 1,451 assertions per run, all 60 challenges
  and all 36 conversation topics. Larger-text code/order panels, populated
  inventory, portraits, chapter boundaries and the replayable ending were
  captured. The compositor reduced a requested 1920×1200 window to 1668×1043;
  1920×1200 is not claimed as tested.
* Thirty-nine screenshots per native run are stored locally in
  `work/ui-review-960/`, `work/ui-review-1280/`, and `work/ui-review-1920/`
  (the last folder name records the request, not the actual dimensions).
* Seventeen strengthened puzzles were independently solved with their answers
  withheld. Explicit constraint, route, arithmetic and state-transition oracles
  agree with the authored answers. See `PUZZLE_REVIEW.md`.
* Four interactive routing boards add 32 selectable nodes and 38 source-matched
  links. Independent graph checks cover unique routes, signal losses, rope
  acquisition and strict water-height safety. Integrated native UI traversal
  passed 1,488 assertions after this addition; all four board variants have
  separate graphical review captures in `work/ui-review-final/`.

These tests exercise known-answer automation. None is a complete blind human
playthrough or a measured 6–10 hour experience. The most recent exact package
check results remain in `builds/verification.json`; final changes trigger a new
verification before the final local checkpoint.

The production target remains six substantial chapters, 36 illustrated
environments, at least 60 varied investigative challenges and approximately
6–10 hours for first-time players. Content counts and deterministic solution
traversal do not establish playtime, puzzle quality or a complete human
playthrough.

## Reproducible checks

Run `tools/game.sh verify` from the source repository. It checks the exact
Godot 4.7.2 version, audits content references and dependency reachability,
imports resources, runs the GDScript state tests, starts the source game in
smoke mode, exports Windows and Linux binaries, packages source and player
files, checks ZIP integrity, and runs the extracted Linux package. If Wine
is installed, it also runs the extracted Windows executable with an isolated
prefix under `work/wine`.

Audio verification retains the legacy eight-PCM audit and adds the full new
score/ambience/effects catalog audit, comparing source/event/output hashes,
section diversity, duration, stereo signal, silence and clipping. The voice
audit requires exact source text and honest recording status. Runtime tests
cover crossfades, ducking, independent mutes, queues, skip/replay, missing audio
and subtitles. These do not replace listening and final in-game mixing review.

`builds/verification.json` records the most recent result and exact scope;
`builds/logs/` contains command output. `builds/content-audit.json` records
content counts, puzzle types and a structurally reachable solution order.
`builds/SHA256SUMS.txt` identifies the generated archives. These files are
build artifacts; a result only describes the source revision used for that
run. A later change requires another appropriate verification run.

The state test suite uses the runtime API, including wrong actions, recipe
combination, dependency enforcement, save/load boundaries and corrupt-save
rejection. Its deterministic completion runs intentionally know all answers.
The source and packaged smoke modes establish resource loading and startup;
they are not manual playthroughs.

`tests/test_ui.gd` additionally submits the entire case through the actual
presentation callbacks: opening panels, entering wrong and correct answers,
using ordered-input controls, requesting hints, collecting evidence,
combining objects and loading chapter checkpoints. It requires isolated test
storage and is included in `verify`. This exercises the rendered control
logic; it still does not represent a human playing or deriving answers.

`tools/check_puzzle_logic.py` derives 17 revised puzzle answers independently
from transcribed clue rules. It enumerates constrained orders and routes,
simulates the valve protocol and relay state machine, and performs the
clock/cipher/checksum calculations. These checks establish a unique answer
for the represented constraints. They require editorial maintenance whenever
those clue rules change; they do not automatically understand prose.

## Acceptance work still required

* A complete manual opening-to-ending playthrough through the rendered UI,
  with screenshots and notes at each chapter boundary.
* Independent blind first-time playtests measuring active play and reading
  time, hint usage, bottlenecks and abandonment. Adjust the actual content
  if the 6–10 hour target is missed; do not insert waits or repetitive filler.
* A native Windows install-and-play test of the extracted package, including
  save locations, display modes, audio and input. Wine cannot certify this.
* Artwork review in every location at intended scale, including alignment
  between depicted objects and hotspot positions, readable inventory art,
  and consistent character presentation.
* Graphical checks at multiple resolutions and with larger text, keyboard
  focus, reduced motion, labels and muted audio.
* Narrative fairness review: clues must support the intended conclusions
  without relying on the source data or solution hints.

The current build must remain labelled development alpha until the applicable
production and acceptance gates have evidence. The native Windows and
first-time duration gaps cannot be waived by a green automated report.

The audiovisual implementation checkpoint `73af866` passed full packaging
verification with a clean working tree. Additional extracted graphical opening
checks passed on Linux and Wine; Wine reported an SDR-white-level warning.
`AV_VERIFICATION.json` preserves those exact results and hashes. The final
packaging refresh includes this evidence; its current archive hashes remain in
`builds/verification.json`. The later GPT Live audition stage has an explicit
US$0.25 cap for three first takes; this does not authorize full-game recording.
Offline recorder/fidelity tests exercise approval, spending reservations,
receipt loss, transcript mutations, PCM integrity and required protocol fields.
See `VOICE_SAMPLE_REVIEW.md` for actual candidate outcomes.

## GPT Live audition evidence

Three spoken auditions were captured with exact provider transcripts and PCM
integrity passes. Offline ASR independently matched Mara after an analysis copy
removed only proven zero-valued trailing samples; Iona and Rowan retain proper-
name listening holds. Two failed silent captures remain recorded, not concealed.
All five requests have final usage receipts (117 reported seconds, computed
US$0.0975); all request approvals are exhausted. No voice is accepted into the
runtime manifest. See `VOICE_SAMPLE_REVIEW.md` and `VOICE_AUDITION_RESULTS.json`.

Forty-one offline recorder/fidelity tests pass, covering both explicitly
authorized one-use replacement exceptions, unchanged spending limits, unknown
receipt latches, speech-start event ordering, paraphrases, extra/missing words,
clipped/silent PCM and unaccepted review status. These tests make no API calls.
The normal `tools/game.sh verify` workflow now includes these two Python suites.

A separately approved natural Mara retake followed the user’s book-like-delivery
feedback. Its source words and audio integrity pass, with independent ASR
evidence retained. The recorder carries the immutable first-round cost into the
new hash-bound plan and forbids redirecting that approval into a fresh ledger.
Cumulative usage is 149 seconds, approximately US$0.1242; all approvals are used.
No acoustic or programmatic test establishes that the acting now feels natural.

## Actual recorded-audio runtime checks

The updated AudioDirector passes 66 behavior checks and the AV UI suite passes
113 checks in headless mode and native Linux Compatibility rendering. The
voice-only decoded-PCM meter handles WAV/Ogg, leading silence, pauses, tails,
mute, interruption and reduced motion. Music-only input does not move the mouth.

A native 1280×800/24fps movie uses the first Mara audition in memory, with
approximate sentence captions and a persistent UNAPPROVED AUDITION label.
Telemetry validates 526 speech-window frames, 120 silent-tail frames, 96 frozen
reduced-motion frames and all six exact sentence transitions. The recorded mix
measured -30.5 dBFS mean / -9.3 dBFS peak; these are signal checks, not LUFS or
human mix approval. The production voice manifest remains byte-identical with
all 98 paths empty. The later natural Mara retake remains a separate listening
comparison; it is not silently substituted into this historical movie.
