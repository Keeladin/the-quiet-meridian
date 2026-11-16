# The Quiet Meridian — development report

> Current update — 15 November 2026: all 98 story and conversation recordings are
> integrated, with seven character voices and timed subtitles. See
> `VOICE_BATCH_REPORT.md` for correction, selection, budget and listening limits;
> `PLAYER_GUIDE.md` and `DETECTIVE_UPDATE.md` describe current controls and rules.
> Exact final build checks are in the delivered `verification.json`.
> The milestone sections below are historical and may describe superseded
> menus, rules, music or unavailable voices. Native Windows gameplay and human
> performance acceptance remain open.

Development build, 14 November 2026. The requested product remains an original
6–10 hour mystery adventure. This repository is no longer the setup probe, but
the production acceptance gates in `PRODUCTION_PLAN.md` remain authoritative.

## Architecture

Godot 4.7.2, GDScript and Compatibility rendering; offline Windows and Linux
x86_64 exports. `scenes/main.tscn` and `scripts/main.gd` present a scalable
illustrated scene, map, inventory, casebook, puzzle workbench and accessible
settings. The artwork, fonts and audio are packaged resources, with no runtime
network calls or service dependencies.

`scripts/game_state.gd` is a presentation-independent state machine. Narrative,
locations, hotspots, inventory and puzzles are in `content/game.json`;
conversations and reviewed hotspot positioning have separate content files.
Puzzle types are hidden evidence collection, code, single-choice deduction,
ordering, repeated signal sequences, directed routes and inventory assembly.
Required evidence and prerequisite investigations are checked before solutions.

Four routing investigations also use `scripts/investigation_board.gd`, driven
by `content/boards.json`. The board draws the exact clue graph and lets players
select nodes and inspect their highlighted route. Full-size text choices remain
available. `tools/check_boards.py` independently verifies the links, weights,
equipment requirements and water-height constraints against unique solutions.

All progress is monotonic: previously examined clues remain in the casebook,
items survive combinations, scenes remain revisitable, wrong attempts cost
nothing, and hints never spend a limited resource. Chapter finales require the
other investigations in their chapter. No real-time deadline can end the game.

Saves contain an explicit game/version identifier, current location, solved
investigations, evidence, item IDs, settings and elapsed time. Loading validates
IDs, dependency closure, item provenance and chapter access before changing live
state. Saving writes a temporary file, preserves a valid previous checkpoint,
and renames the completed new file. Manual and automatic slots are independent;
the UI exposes backup recovery. Test storage stays inside `work/`.

## Art and sound

Original built-in image generation supplies separately authored environments,
a nine-person portrait atlas and a 36-object inventory atlas. Original PNGs are
kept in `assets/art/`; prompts and provenance are recorded alongside the project.
Godot atlas regions do not modify those originals. Environmental markers are
interaction aids; hotspot/image correspondence is reviewed separately from
technical texture loading and remains an art acceptance concern.

The previous short loops are preserved. Runtime audio now uses nine developed
original compositions (23 minutes), six ambience beds and twelve effects from
`tools/compose_score.py`. Original PCM masters, note-event scores, signal audits
and provenance are included. Separate AudioDirector channels crossfade music
and ambience and duck beneath actual speech. Seven original expression sheets
drive painted blinks, gestures and voice-gated mouth poses. EnvironmentStage
uses 36 authored profiles for localized water, fog, light and machinery motion.
Reduced motion freezes animation without removing information.

The complete 98-line voice script has exact-source validation and preset casting.
Offline speech/subtitle/skip/replay systems are tested, but no production voices
have been generated: a paid provider plan and explicit spending approval remain
outstanding. See `AV_POLISH_REPORT.md` and `VOICE_PRODUCTION.md`. The new save
schema adds voice/ambience/subtitle preferences and migrates valid old saves.
DejaVu font licenses and Godot third-party notices ship with the game. No
external musical samples or artist-reference images were used.

## Verification and limits

`tools/game.sh verify` audits content and audio, imports resources, runs state
tests and UI smoke checks, exports both systems, checks archive integrity, and
executes an extracted Linux package. A Windows package may also be exercised
through repository-isolated Wine when available. Wine is not native Windows.

State tests exercise invalid actions, duplicate grants, recipes in both orders,
forged/inconsistent/corrupt saves, transaction failure and recovery, and full
content traversal in different orders with save/load checkpoints. Automated
traversal reads stored answers: it is neither a blind human playthrough nor
evidence of play duration. `QA_REPORT.md` records actual test results.

The remaining release gates include independent first-time completion and
pacing measurement, native Windows graphical play, subjective audio review,
and final environmental hotspot/art alignment. Short solves must be deepened
with meaningful investigation, not waiting or repeated travel. The project must
not be described as a finished 6–10 hour release until those gates are met.
