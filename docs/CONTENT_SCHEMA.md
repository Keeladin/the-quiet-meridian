# The Quiet Meridian — content contract

Production target: six substantial chapters, 36 environments, 60 meaningful
investigative challenges, 6–10 hours subject to independent first-time testing.
This contract is shared by narrative, runtime and validation work.

`content/game.json` contains `title`, `subtitle`, `intro` (string), `ending`
(string), `chapters`, `locations`, `puzzles`, `items`, `characters`, `recipes`.
IDs are globally unique within their collection. Chapter IDs: `ch1` … `ch6`.
Location IDs: `ch1_l1` … `ch6_l6`. Puzzle IDs: `p01` … `p60`.

* Chapter: `id`, `title`, `summary`, `intro`, `closing`, `locations` (IDs),
  `final_puzzle` (ID). Chapters unlock when the prior final puzzle is solved.
* Location: `id`, `chapter`, `title`, `description`, `art` (res:// path),
  `hotspots` (array). All locations in an unlocked chapter may be revisited.
* Hotspot: `id`, `label`, `x`, `y` (normalized center coordinates in illustration),
  `text`, optional `item` (ID). Examining records its ID as an evidence clue,
  and awards its item once. Every hotspot remains inspectable. No prerequisites
  on hotspots: access is controlled by chapter. Two to five hotspots per scene.
* Puzzle: `id`, `chapter`, `location`, `title`, `type`, `requires` (puzzle IDs),
  `clues` (hotspot IDs), `items` (inventory IDs required but not consumed),
  `prompt`, `details` (all rules necessary), `options` (strings), `solution`
  (string or ordered array of strings), `rewards` (item IDs), `success`, `hints`
  (three escalating hints), `rationale` (design-only solution explanation).
* Types: `code` (text entry, case/whitespace insensitive); `choice` or
  `deduction` (single option); `order` (arrange all options); `sequence`
  (ordered input, repeated options allowed); `routing` (ordered path, subset of
  options); `hidden` (examine every listed clue then submit `found`);
  `assembly` (requires inventory/recipe result then submit `assembled`).
* Item: `id`, `name`, `description`. Inventory is never destroyed. Recipes use
  `id`, `ingredients` (two item IDs), `result` (item ID), `text`.
* Character: `id`, `name`, `role`, `description` (biography).

The runtime class lives in `scripts/game_state.gd` (`class_name MysteryState`,
`extends RefCounted`). Public fields: `data`, `location_id`, `solved` (array of
IDs), `evidence` (array of hotspot IDs), `inventory` (array of IDs),
`settings` (dictionary), `elapsed_seconds`, `last_error`.
Public functions: `load_content(path = "res://content/game.json") -> bool`,
`new_game()`, `get_location(id) -> Dictionary`, `get_puzzle(id) -> Dictionary`,
`get_item(id) -> Dictionary`, `get_hotspot(id) -> Dictionary`,
`chapter_unlocked(id) -> bool`, `can_solve(id) -> bool`,
`visit(id) -> bool`, `examine(id) -> Dictionary`,
`try_solve(id, answer) -> Dictionary`, `combine(a, b) -> Dictionary`,
`save_game(path = "user://case.json") -> bool`,
`load_game(path = "user://case.json") -> bool`.
Action dictionaries contain `ok` (bool), `text` (string); success may add
`item` or `puzzle`. A wrong answer does not change progression. Locked or
unvisited location evidence cannot be acquired through the state API.
Save loading is transactional and validates IDs, prerequisites, chapter access,
item provenance and schema before changing live state. Keep a backup and use
atomic replacement. Settings: music, sound (0..1), large_text, reduced_motion,
hotspot_labels, fullscreen (bool). Persistent hints never spend resources.

The engine renders presentation and interactions; prose, clue placement,
answers and dependencies stay in JSON. No fabricated playtime claims.
