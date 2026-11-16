# The Quiet Meridian — hotspot and interaction sound pass

14 November 2026. Development alpha; this pass does not close full-game acceptance.

## Reported circles

The screenshot exposed a presentation defect. Each evidence target had a rounded,
dark button background. Unexamined targets with illustrated evidence icons hid
that background, but recording the evidence removed the icon and revealed the
circle. This was unrelated to a missing object or a broken puzzle state.

Normal exploration now draws no background or text on those recorded targets.
The evidence remains clickable. Hover gives an object name and pointer cursor;
Tab provides one visible keyboard-focus outline. F1 and the persistent label
setting reveal readable named tags with recorded checkmarks. No save migration
or progress reset is needed.

Native Linux checks reproduce the screenshot's three examined Ferry Landing
targets. The scene pixels are identical with those target controls shown or
hidden, proving that their normal styles no longer mark the painting. The
headless suite exercises 108 targets, actual activation, the first puzzle,
review, save/reload, hover, focus and F1. Native windows were tested at 1280×800
and 1920×1080; the latter preserves 16:10 content at 1728×1080 with side bars.
Review captures and exact dimensions: `work/hotspot-review/`.

## Interaction audio

Routine handling uses edited material recordings by Kenney and rubberduck under
CC0, with selected originals, licenses, hashes and processing recipes retained
in `assets/audio/foley/`. These are separately attributed recordings, not a claim
of project-original field recording. The score, music themes and ambience retain
their existing authorship. No paid generation calls were made in this pass.

The delivered set contains **49 variations across 18 cues**, derived from 55
retained source clips, adding approximately 695 KB of runtime Ogg data. The
complete sound-effect catalog has 22 identities including retained musical
confirmations and the compatibility travel fallback.

`content/interaction-audio.json` explicitly assigns sound to every evidence
point and travel destination, plus recipe results and puzzle conclusions. A
document, brass plate and wet walkway no longer receive the same generic cue.
Assignments reflect actions described by the narrative; they do not alter
story, inventory, puzzle dependencies or answers.

The audio director selects variants without immediate repeats, applies subtle
bounded pitch changes and per-cue cooldowns, and drops excess effects beyond
eight simultaneous players. It never steals a voice or music player. A smooth
4 dB reduction gives speech room; the separate Sound and Voice controls remain.
Muted effects do not queue for later playback. Missing variants fall back to
another valid local file; unavailable sets produce a diagnostic.

## Review and reproduction

* `builds/previews/sfx/`: local before/after and material-cue listening gallery.
* `builds/previews/sfx-game/quiet-meridian-interactions.mp4`: staged opening
  actions captured through the native game UI and mixer, with clean targets,
  optional tags, paper handling, a brass mechanism and surface-specific travel.
  It demonstrates implementation and mix, not a complete playthrough.
* `tools/build_foley.py`: reproducible source selection, processing and preview.
* `tests/audit_foley.py`: source/master/output integrity, format, headroom, edges,
  variants and catalog provenance. Signal checks are not listening approval.
* `tests/test_audio_director.gd`: decoder-based mixing, fallback, variant,
  cooldown, mute, saturation and dialogue-priority checks.
* `tests/test_interaction_audio.gd`: authored mapping and actual action routing.
* `tests/test_hotspots.gd`: invisible recorded targets and usable optional reveal.

Focused results: 1,152 Foley provenance/signal assertions, 558 combined score
assertions, 92 audio-director assertions in both headless and native Linux,
504 interaction-routing assertions, and 384 headless/386 native hotspot
assertions. A separate 444-check decoded-asset pass also confirmed that repeated
offline builds produce byte-identical derivatives. These are objective evidence;
subjective listening approval remains open.

`tools/game.sh verify` performs the full state/UI/resource checks, both exports,
archive integrity and extracted Linux/Wine smoke checks. Exact revision and
results are recorded in `builds/verification.json`; Wine is not native Windows.

## Playability and remaining work

The alpha implements a route through all six chapters, 36 locations and 60
investigations, with inventory, conversations, hints and saved progress. The
reported save has solved the Ferry Landing investigation; **Explore the city**
or **M** opens other locations. Recorded evidence can still be reviewed.

This is playable development content, not an accepted finished game. Independent
manual playthroughs, measured 6–10 hour pacing, native Windows gameplay and final
listening/art/interaction acceptance remain open. Production voice coverage is
still 0/98; existing local auditions are awaiting acceptance and are not included
as finished performances. The new Foley improves material variety but does not
establish parity with a professionally performed and mixed commercial adventure.
