# The Quiet Meridian — player guide

Development build. The six-chapter case is playable, but the 6–10 hour target,
first-time-player difficulty and native Windows gameplay still require independent
playtesting. Automated checks do not establish release acceptance.

## Install and start

Extract the entire Linux or Windows archive into one directory. Keep the
executable and `quiet-meridian.pck` together. On Windows, open
`quiet-meridian.exe`. On Linux, run `quiet-meridian.x86_64`; if your archive
manager removed its executable permission, enable execution in Properties →
Permissions, or run `chmod +x quiet-meridian.x86_64` in that directory.

The game runs offline without Godot, Python, an account, an API key or downloaded
content. It uses the Compatibility renderer and needs a working graphics driver.
Wine checks are separate from native Windows validation.

The title screen offers **Continue investigation**, **Begin a new investigation**,
**Settings & accessibility** and **Quit**. The introduction explains Iona's return,
Mara's disappearance and the question behind the flood. Continue resumes your
automatically saved case. Starting a new investigation replaces that active case.

## Search the picture

Find the objects, symbols and embedded shapes listed vertically beside the
picture. A clue may use an alternative name, such as Plume for a feather.
Credible alternative matches count once. Found names are crossed off; permanent
circles and pointer changes do not give away the remaining objects.

From chapter three, some objects are listed by a riddle in italics instead of a
name, such as *A writer's feather*. The share of riddles grows each chapter.
Finding the object, or using a hint on it, reveals its name. A click a few
pixels outside an object's outline still counts.

Detective mode is the only mode. The clock tightens as the case goes on. A
standard 14-object search allows 8:00 in chapter one, then 7:00, 6:30, 6:00,
5:30 and 5:00 in chapter six. The 17-object opening allows ten minutes. These
are initial balancing values, subject to first-time-player review. Scroll or use +/− to zoom, right-drag
to pan, and use Fit to see the entire painting.

The clock runs while you can actively search the picture. It pauses while
reading a story, using another screen, pausing or switching away from the game.
The painting is covered while paused. Leaving and returning to a room preserves
its remaining time and finds; it does not refill the clock.

An occasional miss is forgiven. Three rapid misses give a warning. Five misses
within three seconds cost ten seconds and reset that burst counter. Interface
clicks, dragging, clicks outside the picture and selecting an already-found
object are not search misses.

Clear the list to recover the room's story evidence and useful objects. All six
room searches contribute to the chapter's conclusion. If the clock reaches zero,
finds stop counting. Spend an available time extension or restart the clock.
A restart keeps every object you have found and starts a shorter clock for the
ones that remain (at least 90 seconds). It refunds nothing, keeps the room's
hint use, reopens the two time extensions, and gives up that room's clean-search
bonus. Completed rooms and story progress are never affected.

## Hints and Insight

Insight is scarce: spend it where you are truly stuck. A new case begins with
**four Insight**. You earn:

| Achievement | Reward |
| --- | --- |
| First completion of a search | 1 Insight |
| A clean completion: no rapid-click penalty, no paid hint and no restart | 1 additional Insight |
| A deduction solved without a paid hint | 1 Insight |
| An assembly step | nothing |

The free first hint and bought time do not spoil a clean completion. Replaying
completed content gives no further Insight. Existing completed content from an
older save is not rewarded again when the save is migrated. A save from the
previous build keeps its balance, purchases and rewards exactly.

Every search attempt has a maximum of **three hints**. The first is free; the
next two cost one Insight each. Each use begins a **30-second cooldown** during
active play. F1 or the lightbulb requests a hint. By default it points to the
first object still hidden; select a name in the list (click it, or Tab to it and
press Enter) to aim the next hint at that object instead. Choosing is free.
Buying a hint cannot bypass the cooldown or three-use limit.

One Insight buys **30 additional search seconds**. You can buy at most two
extensions per clock, including an emergency extension after reaching zero.
Restarting refunds nothing and earns nothing.

Timer, hint uses, cooldowns, purchases and rewards are saved with the case.
Closing and reopening the game does not refill an attempt or its hint allowance.

## Travel and investigate

The illustrated map shows the city's districts and room pins. Select a district
to see its rooms, then select a pin to inspect progress and travel. Markers
separate unsearched rooms, finished searches with investigations remaining,
fully resolved rooms and locked locations. Your current location is marked
separately. Earlier unlocked rooms stay revisitable.

The **Casebook** combines the current room's field notes, its available actions,
the chapter investigation and the story so far. It opens to your current room.
A ready investigation opens directly from its action; you do not need to pass
through a separate mystery-summary page. Relevant evidence stays available
while solving the connected puzzle.

Deduction puzzles are untimed. Read their prompts and rules, assemble the needed
evidence and submit an answer. Three incorrect submissions within one minute
cause a ten-second submission cooldown; you can still read evidence and revise
an answer. Editing an answer and trying an inventory combination are free.

Each deduction has up to **three escalating hints**, with the same first-free,
next-two-for-one-Insight arrangement and 30-second active-play cooldown. Leaving
and reopening the puzzle preserves its used hints. The chapter's final
conclusion unlocks the next chapter.

## A tidy inventory

Select an object in the satchel to inspect it or try combining it with another.
A successful combination replaces its separate usable components with the
finished object. For example, the viewing lens and frame become a plate viewer.
Unsuccessful combinations keep the objects.

Objects leave the active satchel only when incorporated into something else or
when all their remaining uses are complete. Their acquisition and component
history remains recorded, so earlier evidence and saved progress are retained.
The active satchel shows what you can still use instead of every object ever
collected.

## Controls and accessibility

| Control | Action |
| --- | --- |
| Left mouse button | Travel, inspect, choose, interact |
| Tab / Shift+Tab | Move keyboard focus between controls |
| Enter / Space | Activate the focused control |
| F1 | Request a search hint, subject to its limit, cost and cooldown |
| F11 | Toggle fullscreen |
| Mouse wheel / + / − | Zoom the search picture |
| Right-drag | Pan the zoomed picture |
| Arrow keys, with picture focused | Move the search cursor; Enter selects |
| J or C | Open the unified Casebook |
| M | Open the city map |
| I | Open inventory |
| Escape | Close the current panel or open the pause menu |

Settings include separate music, ambience, effects and voice levels, larger text,
reduced motion, subtitles and fullscreen. All clues are available as text and
progress never depends on hearing a sound. Larger text applies when a panel is
reopened. The game opens fullscreen by default.

**Set the case down** offers **Return to investigation**, **Settings &
accessibility**, **Save and return to title**, and **Save and quit**.

## Saves

The active case is saved automatically after progress and important attempt
actions, periodically during play, and when using either save-and-exit action.
**Continue investigation** resumes `autosave.json`. There are no manual-checkpoint,
import or recovery menu screens. Existing files from older versions are not
deleted by installing this update.

Saves live in the operating system's per-user Godot directory, not beside the
executable. This campaign uses `the-quiet-meridian-search-campaign`; the earlier
alpha and standalone opening preview keep their own directories. The save system
retains a backup of the previous valid automatic save. Existing campaign progress
is migrated when necessary; a rejected or damaged save does not replace the
active state in memory.

When using `tools/game.sh run`, development saves remain in `work/player-data/`
inside the repository. Automated tests use separate storage. Preserve a copy of
your save before replacing a development build if you want an independent
rollback point. Do not edit save JSON to repair progress.

## Troubleshooting and audiovisual status

If the game does not start, confirm the whole archive was extracted and the
`.pck` remains beside its executable. Licence notices are provided in
`LICENSES.md`, `GODOT_NOTICES.txt` and the accompanying licence files. Build
verification and remaining production work are documented in the source repository;
the title and pause menus do not display development-status screens.

When reporting a problem, include the location, investigation, last action,
remaining time and whether you had resumed a save. The game has no telemetry or
online-account dependency.

All 98 story and conversation recordings are included locally, with seven
distinct character voices. Dialogue supports automatic playback, replay, skip,
subtitles and an independent voice-volume control. Speech works offline; no
account or API key is required. The written conversations remain readable.

The music is **“Sonder” by Purrple Cat**, from
*City Nights 2*, supplied by the owner through Chosic. It continues across rooms
and menus; the music slider and automatic lowering during dialogue remain
available. Purchased-library room atmospheres and interaction effects remain
separate. The nine original score cues are retained in source and project
history, but are not active in play. See `LICENSES.md` for attribution and licence
details. Production and listening-review records are kept with the source.
