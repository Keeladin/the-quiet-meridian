# Pacing and puzzle-design review

14 November 2026. The production target remains **6–10 hours of meaningful
first-time play**, across six substantial chapters. It has not been measured or
accepted. A complete authored ending and a successful automated solution traversal
do not establish that duration, nor the physical richness of a finished adventure.

## Work completed in this revision

The campaign contains 60 challenges across 36 revisitable locations, 108 evidence
hotspots, 36 inventory items and 12 combinations. Twelve optional conversations
add 36 topics with puzzle-gated replies. Conversation choices do not lock progress,
spend evidence or secretly determine a character's guilt. They develop the cast's
positions on responsibility, institutional records and repair, rather than merely
repeating the next objective.

An independent review identified a substantive weakness: many original challenge
solutions could be copied directly from one instruction card. Seventeen challenges
were revised; sixteen now demand additional inference or computation, while p37
is deliberately an evidence-verification task. The revisions include:

| IDs | Reasoning now required |
|---|---|
| p12 | Directed route through a required inspection point, excluding hazards named in another location |
| p13 | Derive a safe valve order from state conditions and restoration requirements |
| p16 | Order six arrivals from adjacency, distance and before/after constraints distributed between records |
| p23 | Convert six events from three differently calibrated clocks before ordering them |
| p25 | Track a signal wheel's changing position across a four-letter encoded message |
| p26 | Compare complete weighted relay paths and choose the unique minimum-loss route |
| p28 | Recover a worn delay calibration by subtracting an exposure duration and dividing the remaining interval |
| p32 | Plan a one-way route that acquires a rope before a crossing requiring it |
| p33 | Sort six historical cards by category, using arrival numbers only to break ties |
| p35 | Solve a constrained three-digit archive index from a separate number key and condition note |
| p36 | Combine coordinates, side adjacency and an independent height survey to avoid flooded sites |
| p37 | Verify the omitted lodger category against the total and individual names; this remains a short verification |
| p43 | Reconstruct a six-event deed chain from contractual precedence and relative positions |
| p49 | Link six custody receipt endpoints from unsigned draft to deposited original |
| p52 | Schedule six witnesses using adjacent pairs, precedence and a fixed closing witness |
| p53 | Find the unique shortest pulse sequence through a finite-state relay, avoiding loops |
| p54 | Compute a position-weighted check digit that satisfies an integrity condition |

The independent reviewer inferred answers with intended solutions withheld and
then compared the recorded answers with runtime data. That is a designer review,
not a blind first-time player test: the reviewer had already read the wider story.
See `docs/PUZZLE_REVIEW.md` for the exact scope and any enumerated uniqueness checks.

Two chronology defects were also repaired. The harbour tide now turns at 00:20,
consistent with the bypass operating at 00:14 before the tide. Elian's earlier
assurance is a preliminary capacity sheet and a spoken promise; the formal false
evacuation return is dispatched later at 00:22. The clinic page explicitly records
deaths, including recovered people, and Tomas is one of the twenty-three named
victims. These repairs matter more than a higher raw word count.

## Intended rhythm

The first chapter teaches examination, inventory combination, evidence comparison
and safe retries. Its shorter operations are appropriate introductions. Chapters
two and three increase the number of sources and the number of transformations
needed to reconcile them. Chapter four interrupts the machinery with people and
names; the route and register tasks support that shift. Chapter five establishes
responsibility through records whose separate limits are stated. Chapter six mixes
a final technical reconstruction with deliberate, shorter acts of testimony and
correction. The ending should not be gated behind an unrelated difficult cipher.

The design budget remains approximately 55–85 minutes for chapter one, 60–90 for
two, 65–95 for three, 65–95 for four, 65–95 for five and 50–80 for six. These are
**production budgets**, not observed durations or a prediction that the present
build will fill them. The current text and interaction volume may still produce
a substantially shorter experience for a fluent puzzle player.

The latest authored runtime content has roughly eleven thousand words across
scene evidence, challenges and optional conversation. Reading volume cannot stand
in for gameplay duration. Most assembly operations require one two-item
combination; they should be counted as short connective actions until their
physical interaction has been evaluated. Likewise, clicking three labelled
hotspots is an accessible evidence collection task, not automatically a substantial
hidden-object scene. The generated paintings and hotspot alignment must earn the
search component through actual legibility and scene design.

## Duration acceptance procedure

Use testers who have not seen the answers or watched the generated solution
traversal. Ask for normal play, with hints available and no encouragement to delay.
Record session time separately from idle time. At minimum, record chapter start
and finish, puzzle attempt counts, time to first useful clue, hint level used,
return visits, and optional conversations opened. Testers may decline optional
reading; the main adventure must still make sense.

Review at least these distinct patterns before fixing a typical-player estimate:

* A regular adventure player who reads optional dialogue.
* A capable puzzle player who follows only the main case.
* A less experienced player who uses the hint ladder freely.

For each short chapter, identify whether the cause is a trivial answer, a clue
that announces the conclusion, an interaction that has no meaningful state, or
missing environmental work. Deepen the cause. Useful work could include a
multi-stage paper reconstruction whose joins matter, a valve board showing its
intermediate states, or a route map whose selected path can be inspected visually.
Each addition needs its own clue logic and state/save tests. Do not add waiting,
longer walking distances, repeated object lists, repeated explanations, or random
passwords to make a stopwatch reach six hours.

## Remaining acceptance risks

* The revised route, relay and ordering logic is currently expressed through the
  shared puzzle interface. A stronger physical presentation may improve
  comprehension and engagement without changing the rules. That requires actual
  graphical testing, not a content-count assertion.
* Sixteen deeper deductions do not transform all sixty tasks into long puzzles.
  Short investigative operations serve the story, but too many in succession
  would still make the campaign shorter than its target.
* Freely revisitable chapter locations can reveal a later document before its
  associated puzzle unlocks. Gated dialogue avoids major conversation spoilers;
  hotspot prose still needs observation during first-time play. The state graph
  prevents premature completion, not every premature inference.
* Optional conversations have meaningful character content, but their reading
  time must not be required to disguise an undersized main path.
* The final register and public correction intentionally restate already-proven
  conclusions. Their value is narrative resolution. They must not be described
  as new high-difficulty puzzles in a duration claim.
* Native Windows playtesting, readable art-object alignment, full GUI completion,
  save/load during real interaction, and first-time duration are separate gates.
  Passing a headless solver does not close any of those gates automatically.

The next content decision should follow playtest evidence. Until that evidence
exists, label builds as development builds and keep the 6–10 hour acceptance gate
open in the production plan. The requested full-length game remains the objective.
