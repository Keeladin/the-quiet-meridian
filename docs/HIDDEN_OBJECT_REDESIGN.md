# Classic hidden-object gameplay correction

Owner decision, 14 November 2026: **Main activity: classic hidden-object game.**

The owner played the alpha and found only three clue hotspots in each scene,
with no lists of hidden objects to find. Investigation reachability, item
counts and better sound do not remedy that genre mismatch.

## Current implementation

All 36 campaign rooms now contain visible search lists, 507 total finds,
original paintings, persistent progress, hints, zoom and keyboard selection.
Room completion awards story evidence; chapter gates require all six rooms.
See `CAMPAIGN_SEARCH_REPORT.md` for checks and remaining acceptance work.
The requirements below remain the creative standard, especially concealment,
variety and the balance between searching and additional deductions.

## Required player experience

* The main loop is: enter a detailed search scene, read a visible object list,
  locate those objects, earn a useful story item or discovery, then advance.
* Organise each chapter into map areas with a couple of search rooms or
  close-ups per area. `CHAPTER_SEARCH_STRUCTURE.md` proposes three areas of
  two rooms using the existing locations; this is a working plan, not an owner
  quota. Use roughly 12–20 targets where the artwork supports that density.
  Avoid repeating a generic object arrangement to satisfy a count.
* Give every chapter its own exciting smaller story, question and resolution.
  Each cleared core search awards evidence or an item that solves a room or
  advances the chapter deduction. Each chapter's answer supplies part of the
  overarching mystery. Search completion alone is not a narrative payoff.
* Make searches most of the player's active time. Curate and shorten the
  existing dialogue and abstract puzzle workload when it competes with this
  focus. The original 60-challenge target can include substantive searches;
  it must not force 60 additional abstract puzzles beside them.
* Objects must really be drawn into the scene, with coherent scale, lighting,
  contact shadows and useful visual camouflage. Do not use named buttons,
  marker circles or floating inventory icons as substitutes for search art.
* Keep each list visible. Cross off finds immediately, give restrained sound
  and a brief visual response, and preserve progress on exit and save/load.
  Do not cover the completed illustration in persistent circles.
* Use clear names and object-shaped click regions. Avoid impossible pixel
  targets, a changed cursor that reveals all objects, arbitrary click penalties
  and misleading decorative duplicates. Offer zoom, a contextual hint with a
  gentle cooldown, keyboard access and usable text at small window sizes.
* Increase difficulty through composition and a few clearly signposted
  interactions, not darkness, unfair ambiguity or unnecessary backtracking.
  Every listed object must be obtainable before a search is offered.
* Give each completed search a relevant narrative discovery or inventory
  reward, integrate it with the dependency map, and prevent duplicate awards.
  Preserve old saves with an explicit, tested migration when integration lands.

## Concealment and word interpretation — owner feedback

The owner confirmed that the first preview has the correct basic search loop,
but its targets were too obvious. The next pass must feel like finding hidden
forms within a scene, not selecting objects presented on a display shelf.

* Mix easy, medium and difficult finds. Use overlapping props, limited visible
  outlines, matching colours/textures, varied orientation and embedded motifs.
  Maintain readable exposure and enough identifiable detail to be fair.
* List concise words that permit interpretation when appropriate. **Club** can
  be a wooden club, a playing-card suit symbol, or a club-shaped water stain.
  Other authored examples might be a crown motif, a bell-shaped silhouette,
  a chess knight or a shell decoration. Each depiction still has to be clear
  enough for a player to recognise after finding it.
* Search targets may be physical objects, carvings, embroidery, print, wear
  patterns or wall marks. They need not all be loose inventory items.
* Avoid adjectives such as a colour or exact object type when those would
  unnecessarily give away the intended interpretation. Use specificity when
  several otherwise valid matches cannot all be supported.
* If a clue has multiple credible visible matches, accept any one and cross
  the clue off exactly once. Finding another match must not duplicate rewards.
* Inspect the complete picture for unintended valid answers. Add their click
  regions or revise the art/clue. Decorative ambiguity must not become unfair
  invisible rules. Hints should explain a possible meaning only when requested.

The owner also requested familiar alternative names, such as **goblet** for a
wineglass. Keep synonyms semantically accurate: a goblet is a stemmed drinking
vessel, not any mug. The revised preview uses **Plume** for a feather and
**Timepiece** for a watch or clock, alongside **Club** as a suit symbol. Mix
these with literal clues; do not turn every item into an obscure vocabulary test.

## Isolated opening review

Branch: `feature/classic-hidden-object`.
Worktree: `/home/jaco/Projects/mystery-game/work/classic-hidden-object`.
Scene: `scenes/hidden_object_preview.tscn`.
Content: `content/hidden-object-dispatch.json`.

The revised Dispatch Office has seventeen clues, including a club symbol
with two valid depictions, and an explicit list. The first sixteen-object
preview is preserved in Git and its previously exported packages. The reusable controller supports polygon hit detection, hints, zoom and
panning, keyboard search, found-item state and transactional save/load. The
receipt completion is currently a preview narrative panel, not an integrated
campaign inventory award. The independent preview save cannot alter the
existing campaign save.

The owner accepted the opening loop but requested stronger concealment and
word-meaning clues. Revise those before scaling the artwork across the campaign.
The existing campaign remains available. Do not present this review as the
full requested game, or report 36 searches when only one is playable.

## Completion gates

1. Owner review of the playable opening search and the intended search density.
2. Complete authored search content across the campaign, with visual inspection
   of every target and its hit region at supported display sizes.
3. Integrate search rewards and gating with story, inventory, travel and saves;
   update the puzzle dependency map and test old-save migration and recovery.
4. Test all searches, hints, repeat clicks, leaving/re-entering, incorrect
   clicks, save/load mid-search, reward idempotency and full-case reachability.
5. Independent first-time playtests must establish actual search time,
   fairness, variety and the 6–10 hour goal. Automated known answers cannot.
6. Export and test complete Windows/Linux packages; keep native Windows testing
   distinct from Wine. Audiovisual and voice acceptance gates also remain.
