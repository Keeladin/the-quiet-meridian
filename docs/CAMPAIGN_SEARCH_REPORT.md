# Hidden-object campaign development build

14 November 2026. Branch: `feature/classic-hidden-object`.

The six-chapter case now has 36 playable hidden-object rooms and 507 finds.
The approved opening retains its 17 targets and painting. Each of the other
35 rooms has a newly generated original painting and 14 visually mapped finds.
The local asset ledger preserves prompts, original cache provenance and hashes.

Each chapter’s map groups three areas with two rooms apiece. Completing a room
records its story evidence and useful items exactly once. Existing characters,
chapter stories, deductions and inventory combinations remain connected.
Five old collection-confirmation tasks now resolve from actual picture searches;
55 further investigations remain. Chapter conclusions require every room search
as well as their narrative prerequisites. Search lists are the default room view.

Finds are crossed off immediately and saved after each selection. The picture
has no hover giveaways or permanent target circles. Scroll/+/- zoom, right-drag
pan, keyboard searching, 20-second rechargeable hints, larger text and fullscreen
are supported. Version-3 saves preserve partial searches. Earlier valid campaign
saves can be imported into a separate save folder without overwriting them.
Standalone opening-preview progress remains separate.

## Sound pass

Thirty-three purchased library masters are used: the thirteen owner choices
plus twenty Codex selections. Thirty-six distinct approximately 90-second room
mixes combine appropriate water, wind, rain, birds, hearth, steam, clockwork and
occasional structural details. Arrival and mechanism cues have selected library
recordings; the owner’s discovery, symbol, hint, menu and staged-completion cues
are integrated. Suitable existing material Foley and the original score remain.
The quieter opening ocean and more audible rain balance are retained.

The 46 new encoded files occupy approximately 56.6 MB. Masters stay unchanged
in Downloads. The game runs offline; no external upload, paid generation or
Atlas/GCC/server changes were made. Shareable source archives omit reusable
licensed audio; `RESTORE_LICENSED_AUDIO.md` explains restoration.

Selection used scene context, source descriptions and signal analysis. This is
not a claim of listening approval. Exact filenames, selectors, processing,
levels and hashes are in `audio-selection/campaign-plan.json` and
`campaign-provenance.json`.

## Validation and acceptance

Target geometry checks cover all 36 paintings and 507 listed finds, plus
alternative matches. State tests cover partial progress, repeated finds,
one-time rewards, malformed saves, legacy migration and chapter search gates.
Full forward/reverse state traversals and a presentation traversal reach the
ending using authored answers. These are functional tests, not a player
playthrough or a measurement of duration.

Native Linux captures inspect search layouts at 960×600, 1280×800 and
1920×1080, including larger text. Final build results and exact source revision
are recorded in `builds/verification.json` after verification. Linux and
Windows exports are checked from their extracted archives; Wine validation,
when recorded, is distinct from native Windows gameplay testing.

This is a playable campaign development build. Difficulty, repeated-object
variety, concealment, pacing and whether searches dominate the player’s time
need blind playtesting. The 6–10 hour target is unmeasured. Voice production,
subjective mixing acceptance and native Windows validation remain open.


## Interface and story follow-up

The picture now fills the screen beside a vertical item rail. Compact icons
open map, notebook, inventory, case overview and pause. The compass (C) explains
the mystery and offers a next available action. Opening/chapter briefings and
room discoveries state their story purpose plainly. Existing campaign saves
continue. See `INTERFACE_STORY_REVISION.md` for scope and validation.
