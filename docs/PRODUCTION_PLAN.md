# Production plan and acceptance gates

Status (16 November 2026): balance, puzzle and search-list revision applied;
see the final section. Status (15 November 2026): the full six-chapter hidden-object campaign is
implemented on `feature/classic-hidden-object`, with 36 searches, 507 finds,
room rewards, chapter gates and 36 licensed room atmospheres. This is a new
playable development build, not final release acceptance. Earlier alpha and
standalone opening packages remain preserved. See `CAMPAIGN_SEARCH_REPORT.md`.

## Hidden-object campaign milestone

The owner’s correction is now integrated: the primary room view shows a dense
illustration and vertical item list, crossed-off finds, zoom, keyboard searching
and timed Detective searches. Hints are capped at three per attempt, with a
45-second active-play cooldown; the first is free and the next two cost one
Insight each. All 36 locations use this view. Five former
three-hotspot confirmation tasks resolve automatically from real searches.
The remaining investigation, combination and story content is retained.

Each chapter has three named map areas with two rooms each. Clearing a room
awards its existing story evidence and collectible items exactly once; the
local investigation uses those discoveries. Chapter conclusions require all
six searches as well as their original narrative prerequisites. The six local
stories still lead into the overarching mystery. See `CHAPTER_SEARCH_STRUCTURE.md`.

The approved 17-target opening painting is retained. Thirty-five new original
paintings have 14 authored finds each, with synonyms, embedded motifs and
explicit alternative matches where visibly warranted. Every target has an
observed interior point checked against its click region. Visual camouflage,
search difficulty and whether searches dominate actual playtime still need
first-time playtesting; asset counts are not a duration or quality guarantee.

Progress uses version-4 transactional saves in a separate campaign folder.
Partial searches, attempt clocks, hint use and Insight survive travel and reload.
Continue loads the active autosave and migrates supported older save formats;
already investigated rooms and completed chapters remain cleared. Runtime
manual-checkpoint, recovery and earlier-campaign import screens are removed.
Existing unrelated save files are retained, and the standalone preview remains
separate. A previous valid autosave is still kept as an integrity backup.

## Purchased sound-library integration

The thirteen owner-selected opening recordings remain unchanged. Codex selected
20 additional 24-bit / 96 kHz masters from the purchased Gamemaster library,
with exact source identities and scene rationale in `audio-selection/campaign-plan.json`
and `campaign-provenance.json`. There are 36 distinct approximately 90-second
room mixes, with sheltered/exposed water, wind, rain, birds, fire, steam,
clockwork and occasional structural details. The opening retains the requested
quieter ocean and more audible rain. Discovery, symbols, hints, menus and the
staged room payoff use the owner’s choices. Selected arrival and mechanism
cues use the additional recordings; existing suitable material Foley remains.

The source library is unchanged. Only selected derived audio is integrated;
shareable source packages omit reusable licensed recordings and include
restoration instructions. Checks cover paths, hashes, levels, loop seams,
runtime routing and independent mixer controls. No subjective hearing or
owner listening approval is claimed. Refine through whole-room feedback.

## Remaining release acceptance

Independent blind playtesting, measured duration, difficulty/variety review,
subjective sound balance, voice performance review and native Windows testing remain
open. The 6–10 hour target is unmeasured. The owner-selected “Sonder” by Purrple
Cat now supplies the active music; its integration is described below. The
separately authorized gateway voice batch is described in `VOICE_BATCH_REPORT.md`.
No Atlas/GCC deployment or service restart is involved.

## Current production record

* Creative baseline: six chapters, 36 named locations, 60 individually designed
  investigations, a recurring nine-person cast and a definitive human resolution.
  See `NARRATIVE_BIBLE.md`, `PUZZLE_DEPENDENCIES.md`, and `CONTENT_SCHEMA.md`.
* Core: data-driven state engine, transactional versioned saves, invalid-action
  tests, and opening-to-ending forward/reverse automated traversals pass.
* Art: all 36 independently generated environments, nine portrait atlas cells,
  36 inventory icons and 15 evidence sprites are stored locally with prompts.
  The earlier short ambient loops are preserved as legacy assets. The new pass
  added seven eight-frame expression sheets, 36 animated environment profiles,
  nine developed score cues, six ambience layers and twelve effects, with
  original source, prompts and hashes. The nine original score cues are retained
  in source and project history; the active music is now the owner-selected
  “Sonder” by Purrple Cat. Voice script and runtime are implemented;
  all 98 recorded lines are integrated with timed subtitles, seven consistent
  character voices, replay/skip and background ducking. The owner authorized
  production and necessary corrections through the gateway under a US$6
  cumulative cap; phonetic guidance was used for name retakes. Exact costs,
  selected takes and review limitations are in `VOICE_BATCH_REPORT.md`.
  The original failed request retains its reservation and unknown actual usage.
  Independent recognition and native playback checks do not replace human
  pronunciation, acting or mix acceptance. All audio is packaged for offline use.
  Earlier auditions and their separate receipts are preserved as history.
  Correspondence between scene objects, text and hotspots is still under review.
* UI: scene examination, travel, casebook, ordered/code/deduction interactions,
  active inventory combinations, limited hints, audio/display/accessibility
  settings and automatic saving are implemented. The pinned city map and unified
  Casebook replace the earlier room gallery and separate compass panel. Twelve
  conversations supply 36 gated topics. Earlier known-answer UI traversal passed
  at three native Linux window sizes; the current Detective update passes 2,011
  headless UI checks, 1,176 hotspot checks and 3,920 search-layout checks. Four
  interactive route diagrams now present the actual clue graphs with selectable
  nodes and path highlighting; independent graph/constraint checks pass.
* First `tools/game.sh verify` run passed on 14 November: import, data/audio
  audits, state tests, source startup, both exports, archive checks, extracted
  native Linux startup/save operations and Windows startup/save under Wine.
  This is a development packaging checkpoint, not release acceptance.
* Acceptance is **not complete**: representative chapter manual playtest, full
  manual playthrough, 6–10 hour blind duration testing, native Windows execution,
  and final art/hotspot alignment remain open gates. Automated solutions prove
  state reachability, not usability, pacing, or release quality.

## Next acceptance work

0. Finish the audiovisual gates in `AV_POLISH_PLAN.md`: voice performance review,
   expressive-motion review, recorded-dialogue mixing and representative preview
   acceptance. A tested silent fallback does not complete the voice requirement.
1. Independently play the full case without source answers; record active time,
   hints, confusion and skipped dialogue by chapter using `PACING_REVIEW.md`.
   The current volume may fall short of 6–10 hours and require substantive
   additional puzzle/environment work. Counts do not waive this requirement.
2. Resolve remaining art/text/interaction issues from `ART_REVIEW_CH*.md` and
   subjective audio balance. Preserve all original asset and prompt provenance.
3. Execute the extracted Windows build on native Windows, including graphical
   input, sound, display modes and saves. Wine success is separate evidence.
4. Close acceptance only after those records exist, then create release packages
   and a release checkpoint. Until then, distribute only as development alpha.

1. **Creative and dependency planning.** Choose a title, visual style, setting,
   cast, mystery and resolution. Map every chapter, location, clue and puzzle.
   Record puzzle IDs, prerequisites, clues, inventory changes, solutions,
   hints and recovery paths. Check reachability and absence of softlocks.
2. **Core systems.** Build interaction, inventory, dialogue, scene transitions,
   hints, versioned saves, settings and accessibility. Test state changes and
   save/load across transitions. Establish an artwork style guide and asset ledger.
3. **Representative chapter.** Integrate original final-quality art, audio,
   puzzles and storytelling. Playtest the complete chapter. This is an
   intermediate quality gate, not a reduction of the requested game scope.
4. **Full production.** Complete all planned chapters and dependencies. Track
   content counts, integration status, art provenance and known defects.
   Keep builds working and checkpoint meaningful milestones locally in Git.
5. **Complete-game verification.** Finish an opening-to-ending playthrough;
   test alternate interaction orders, wrong item uses, hints and saves at
   chapter boundaries. Measure first-time play duration. Audit content and
   accessibility; fix progression failures before calling it complete.
6. **Delivery.** Package offline Windows and Linux distributions, source,
   assets, player guide, credits/licenses, and an honest development/QA report.
   Test extracted packages on native Windows and Linux systems. Record exact
   versions, checksums, test evidence, limitations and any unresolved issues.

Future system tests belong in `tests/`. The existing setup probe checks only
startup, a packaged image, and a storage round trip; it cannot validate puzzles,
duration, gameplay, save compatibility or completion of the future game.

## Audiovisual milestone verification

Implementation checkpoint `73af866` passed full `tools/game.sh verify`, including
both exports and extracted Linux/Wine checks. Separate extracted graphical
opening captures passed on native Linux and Wine. A 40-second preview uses the
actual renderer and audio mix. `AV_VERIFICATION.json` preserves this evidence;
`builds/verification.json` identifies the latest packaged revision. The original
alpha archive hashes were rechecked unchanged. No runtime voice recordings or paid provider music candidates were produced
at that checkpoint. The later GPT Live audition stage has a US$0.25 approval
for three first takes only; see `VOICE_SAMPLE_REVIEW.md`. All full-game
acceptance requirements above persist.

## GPT Live audition milestone

The separate recorder uses OpenAI GPT Live, read-only Atlas credential reuse,
per-session voices, a persistent spending ledger and strict transcript/signal
rejection. Three spoken auditions and two silent failures are preserved with
provenance and final usage receipts. Two specific replacement requests were
explicitly approved; all authorized requests are now exhausted. No credential
is stored and no runtime API dependency is introduced. See
`VOICE_SAMPLE_REVIEW.md` for exact outcomes and `VOICE_ASR_PROVENANCE.md` for the
independent offline recognizer and its observed failure modes. The narrative
and puzzle dependency map are unchanged by this audiovisual milestone.

The user’s first audition feedback requested natural conversational delivery.
A separately authorized one-take Mara revision now retains every script word
while using scene-led acting direction. Its original master, exact-word checks
and independent ASR are retained; subjective listening acceptance remains open.
Original and revised Mara can be compared locally without an API connection.

The speech-aware runtime follow-up separates audible-word activity from file
playback. Isolated native/headless audio and UI checks pass, and an actual
Mara-first-take movie demonstrates the portrait resting through silence, stable
ducking, sentence captions and reduced motion. That movie is an unapproved
audition test, not production voice acceptance. Final Windows/Linux package
checks are recorded in `builds/verification.json`.

All 36 environment placements were reviewed natively, with eight data-only
corrections and scoped recapture evidence in `ENVIRONMENT_FULL_REVIEW.md`.
Reduced-motion image pairs are identical for every location. This closes the
previous 32-scene placement sample gap, while continuous-motion comfort,
minimum-hardware performance and full art/hotspot acceptance remain open.

## Historical hotspot and material sound milestone

The examined-object circles reported in the Ferry Landing screenshot were
unintended button backgrounds. Normal exploration now keeps those targets
invisible while preserving hover feedback, keyboard focus and optional F1
name tags in that earlier presentation. The current picture-search view has no
revealing hover targets, and F1 requests a limited search hint. Dedicated native
pixel comparisons and stateful interaction tests covered the original regression;
existing campaign saves remain compatible through migration.

Material Foley now uses separately attributed CC0 recordings, multiple variants,
authored per-action mappings, restrained pitch/cooldown behavior and dialogue
ducking. No paid calls were made. Sources, licenses, processing recipes, previews
and limitations are recorded in `SFX_POLISH_REPORT.md`. The narrative and puzzle
dependency map are unchanged. Full verification and offline Windows/Linux
packages are tracked by `builds/verification.json`; all acceptance gates above
remain in force.

## Historical opening audio balance follow-up

The owner’s first listening feedback was positive apart from an over-loud ocean
and inaudible rain. Preview 3.1 lowers the ocean and raises the selected rain
recording. Other cues and gameplay are unchanged. The revised balance awaits
listening feedback. Full campaign integration subsequently added the other room
atmospheres, as recorded in the current sound-library section above.


## Historical picture-first interface and story clarity revision

The owner requested a much larger search painting, compact navigation, a
vertical side checklist and a clearer explanation of the mystery. These are
implemented across all 36 rooms. That revision introduced clear opening/chapter
briefings and a separate compass case overview, with progression-aware directions
for searches, combinations and deductions. The current Detective revision merges
the overview into one Casebook, prioritizes ready local investigations and uses
version-4 attempt-aware saves. Discovery and recap gating still preserve narrative
progression; clue, audio and puzzle dependency edges are unchanged.
`INTERFACE_STORY_REVISION.md` records the earlier interface checkpoint. Current
full-build verification is recorded in `builds/verification.json`.


## Detective campaign and navigation revision — 15 November 2026

The owner approved the illustrated city map, compact active inventory, unified
Casebook and Detective-only challenge/economy design. The map uses district and
room pins with explicit progress states. Casebook actions open the ready local
investigation directly; story and chapter summaries remain available within it.
Incorporated components and fully used tools leave the active satchel while the
collection record preserves provenance and dependencies.

Search attempts have eight minutes for fourteen objects and ten minutes for the
seventeen-object opening. Five misses in three active seconds cost ten seconds.
Three wrong deduction submissions in sixty active seconds impose a ten-second
submission cooldown. Search time pauses behind fully covered panels and on focus
loss. Three hints are allowed per search attempt or deduction: the first free,
the next two one Insight each, all with forty-five-second active-play cooldowns.
The initial six Insight is supplemented by first-completion rewards: two for a
search, one extra for a penalty-free search, and one for a solved deduction.
One Insight adds thirty search seconds, at most twice per attempt. Restarting an
unfinished search refunds only that attempt's purchases and resets that search;
replays cannot earn duplicate rewards. Save migration preserves existing case
progress, records prior completions as already rewarded and persists attempt
budgets and cooldowns. These timing and price values still require blind-player
balancing; automated completion does not prove an enjoyable difficulty curve.

The title and pause menus each expose only the four requested actions. The title
now explains the initial mystery. Manual-checkpoint, recovery/import and
credits/build-status screens are removed from runtime navigation and handlers;
automatic saving/loading and data-integrity backups remain. Licence notices and
honest development-status reports remain packaged separately.

The clue and puzzle dependency edges are unchanged. Validation is tracked by
`builds/verification.json`; the existing blind-playthrough, native-Windows,
voice-performance and audiovisual acceptance gates remain open. The new economy
requires persistence, no-farming, failed-attempt refund and timer-pause checks
alongside ordinary search, inventory and complete-progression regressions.


## Owner-selected music — 15 November 2026

The owner supplied `Sonder(chosic.com).mp3` and selected “Sonder” by Purrple Cat,
from *City Nights 2*, as the game's music. The same track continues across the
title, rooms and investigation panels rather than restarting with each context.
Existing music-volume controls and dialogue ducking remain, as do the separate
room atmospheres and interaction effects.

The nine original synthesized score cues remain in source and project history,
but are not active music selections. Exact source provenance, attribution and
licence evidence are recorded separately in `LICENSES.md` and the asset records.
This routing change does not establish subjective mix or listening acceptance;
those production checks remain open.

## Balance, puzzle and search-list revision — 16 November 2026

Follows an external design review of Campaign v4. The review found no scarcity
in Insight (about 160 earnable against a small useful spend), a generous and
uniform clock, a restart that wiped all finds, deductions whose wrong answers
were throwaways, instructions that stated their own answers, the correct
deduction answer listed third in 11 of 14 puzzles, heavy repetition of search
targets (Plume in 26 of 36 rooms) and later searches with larger targets than
chapters two to four.

Economy (save version 5): four starting Insight; a first search clear pays 1, plus
1 for a clean clear (no rapid-click penalty, no paid hint, no restart; the free
hint and bought time are allowed); a deduction pays 1 only without a paid hint;
assembly pays nothing. Hint cooldown is 30 seconds. Standard search clocks are
8:00, 7:00, 6:30, 6:00, 5:30 and 5:00 by chapter; the 17-object opening keeps
ten minutes. Restarting an expired search keeps its finds, starts a clock for
the remaining objects (minimum 90 s), refunds nothing and keeps hint use.

Saves now record each attempt's own clock budget, restart count and cumulative
spend, and the case's starting balance. Validation checks the ledger's internal
consistency instead of the current tuning constants, so later rebalancing does
not invalidate saves. Version-4 saves are upgraded in place on load with their
balance, purchases and rewards unchanged, and remain valid as backups.

Search interaction: choosing a name in the list aims the next hint at it, and
a click within seven screen pixels of an outline counts, with unfound objects
taking priority over found ones. From chapter three the most repeated objects
are listed by rotating riddle clues (per room: 4, 6, 9 and 11 of 14 in
chapters three to six); finding the object or hinting it reveals its name.

Puzzles: every deduction and choice option is now a reading a character or
record supports, refutable from a specific clue. Answer positions are spread
across all four slots. Instructions that restated a solution or its method
(p07, p19, p22, p23, p37, p38, p45, p47, p57, p59) now point to the evidence,
and six clue sentences that stated a deduction's conclusion were removed.
Assembly instructions describe the need rather than naming the two items; the
third hint still names them. Solutions and dependency edges are unchanged, and
the 17 independent puzzle oracles still derive the authored answers.

Code: the packaged smoke check moved from `main.gd` to `scripts/smoke_test.gd`
(the `--smoke-test` flag remains for package verification). Player archives
now carry only the guide and licence documents; development reports stay in
the repository and source archive. `main.gd` is otherwise not yet split: UI
tests address its internals directly, so the split needs its own pass.

None of these values have been measured with blind first-time players. The
riddle wording, clock lengths and Insight prices are the first things to check
in playtesting. Assembly steps remain lightweight two-item combinations; a
deeper redesign is still open.
