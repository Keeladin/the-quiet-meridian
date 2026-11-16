# Investigative route boards

Four functional vector diagrams were added on 14 November 2026. They are
interfaces for reasoning about the authored networks, not generated environment
art. Narrative rules and geometry are in `content/boards.json`; the reusable
renderer is `scripts/investigation_board.gd`. No answer, puzzle ID, story rule or
progression mutation is embedded in that renderer.

| Puzzle | Source evidence | Diagram interpretation | Nodes / links |
|---|---|---|---|
| p12 — A dry way through | `ch2_l1_c` service chart; `ch2_l2_c` current safety tag | All ten one-way service links, including flooded PIT and SUMP. GAUGE LANDING remains identified as a required inspection. | 9 / 10 |
| p26 — Across the roofline | `ch3_l4_b` relay chart; `ch3_l6_b` total-loss requirement | All ten one-way relay links, each labelled with its exact loss. All alternatives remain visible. | 8 / 10 |
| p32 — Above the mud | `ch4_l1_a` route tag; `ch4_l1_b` crossing marker | All nine one-way links. FERRY HUT identifies the rope source; WILLOW→STONE RIDGE is labelled ROPE; collapsed SOFT MUD remains visible. | 7 / 9 |
| p36 — The high-ground approach | `ch4_l4_a` coordinate survey; `ch4_l4_c` height annotation | Nine undirected, side-adjacent links derived from the exact coordinates. Positive survey y is drawn upward. Every node shows its coordinate and height; heights at or below three are marked unsafe. | 8 / 9 |

Node buttons send the exact existing answer-option string to the main interface.
Keyboard focus and descriptive accessibility names are provided, and the existing
text option buttons remain usable. `set_path()` updates the selected nodes and
links after selecting, undoing or clearing. Gold highlights selected charted
links; a selected transition with no charted link is drawn in dashed coral.
These are transparent visual feedback about the supplied graph, not a judgement
that the complete proposed route satisfies the puzzle's other conditions.
Hazards are never removed, and selecting them does not consume an item or lock
progress. Text labels explain hazards without requiring colour recognition.

## Verification

`python3 tools/check_boards.py` passed with `BOARD_CHECKS_OK`: four diagrams,
32 selectable nodes and 38 documented links. The checker independently
transcribes the directed clue tables and computes the p36 adjacency graph from
coordinates. It verifies exact node/option correspondence, source-clue IDs,
edge completeness, relay weights, no repeated answer nodes and continuous
answer paths. It enumerates simple routes independently of the authored answers:

* The p12 safety/gauge constraints leave one legal route.
* The p26 graph has four complete routes; the unique minimum loss is six.
* The p32 valid route acquires rope before departing WILLOW and avoids mud.
* The p36 strictly-above-water rule leaves one legal chain. Height equal to
  three is correctly excluded.

Godot 4.7.2 parsed the board script successfully. A dedicated native Compatibility
renderer preview exercised every board's node callback and selected-path update
and saved `work/boards-review.png`; all four were visually reviewed. The main UI
test's routing branch now clicks the board nodes, checks their selected path,
and submits through the existing sequence button. The root's integrated native
UI traversal passed 1,484 assertions after board integration. Four named
`board-p12`, `board-p26`, `board-p32` and `board-p36` captures were then added for
the final layout review; the final run and counts are recorded in the QA report.

The diagrams are supplemental interfaces within the existing scrolling puzzle
panel. They have not been assessed by independent first-time players, and their
addition does not establish the full game's 6–10 hour duration. The moving-wheel
and finite-state relay challenges (p25 and p53) retain their existing accessible
sequence controls; no diagram was added for those two challenges.
