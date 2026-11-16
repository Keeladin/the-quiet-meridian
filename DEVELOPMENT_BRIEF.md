# PROJECT: THE COMPLETE MYSTERY GAME CHALLENGE

## Your Mission

You are an independent game development studio responsible for creating a complete, original, professionally presented 2D mystery adventure game.

Your assignment is to **design, develop, test, and package the entire game from beginning to end.**

This is not a request for a prototype, technical demonstration, vertical slice, or proof of concept.

The intended deliverable is a fully playable, standalone game for Windows and Linux.

## 1. Creative Direction

Create an original hidden-object and point-and-click mystery adventure.

The game should feature an intriguing overarching mystery, exploration, discoveries, interconnected clues, interactive environments, inventory management, and a satisfying narrative conclusion.

You have complete creative freedom regarding the setting, title, storyline, characters, atmosphere, and artistic direction.

Your objective is to produce a game that players genuinely want to finish.


### Player clarification — 14 November 2026

The owner has played the current alpha and explicitly selected **classic
hidden-object searches as the main activity**. Three story clues per room do
not satisfy this direction. A search must show an actual item checklist and
let the player find the depicted objects in a detailed illustration. Object
names cross off as they are found; completing the search yields useful story
progress or an inventory item. Dialogue, travel and shorter puzzles support
this central loop. See `docs/HIDDEN_OBJECT_REDESIGN.md` for the required
conversion and the isolated opening review scene. The existing alpha is not
accepted against this clarified gameplay requirement.

The owner accepted the search/checklist direction but asked for much stronger
concealment: subtle colour/shape camouflage, partial overlaps, and targets
worked into the scenery. Clue words can have several meanings. Their example
was **club**: a playing-card symbol, a wooden club, or a club-shaped watermark
on a wall. Use these visual interpretations deliberately. If more than one
visible thing reasonably satisfies a clue, accept either once or make the
wording more specific; never reject a valid interpretation arbitrarily.
Familiar alternative names also belong in the clues: the owner suggested
**goblet** for a wineglass. Use accurate synonyms, such as plume/feather or
timepiece/watch, without relying on obscure vocabulary.

### Chapter stories and search rewards

The owner wants each exciting chapter to tell a smaller, complete story that
contributes to the overall mystery. Each chapter has several map areas, with
a couple of hidden-object rooms or close-ups per area. Clearing each required
search gives a useful clue or item that helps solve that room or the chapter.
Room discoveries feed chapter deductions; chapter resolutions progressively
complete the overarching storyline. See `docs/CHAPTER_SEARCH_STRUCTURE.md`
for the proposed area groups, room rewards and chapter purposes. This is the
required campaign direction; the standalone search preview has not implemented it.

## 2. Scope and Duration

Target approximately **6–10 hours of meaningful gameplay** for a typical first-time player.

Plan for:

- 5–8 substantial chapters.
- Approximately 30–50 illustrated environments.
- At least 60 varied puzzles and investigative challenges.
- Recurring characters and interconnected storylines.
- A coherent narrative arc with a definitive ending.
- Progressive difficulty and a balanced learning curve.

These are production targets, not permission to fabricate content or artificially inflate playtime.

Avoid repetitive filler, excessive backtracking, and arbitrary puzzle solutions.

## 3. Artwork and Presentation

You are responsible for generating and integrating all visual assets.

This includes:

- Detailed, original 2D backgrounds.
- Interactive objects and collectible items.
- Character illustrations and portraits.
- Inventory icons and puzzle interfaces.
- Menus, transitions, and interface elements.
- Visual effects and environmental details.

Maintain a consistent, polished artistic identity throughout the game.

Do not substitute generic placeholder graphics for finished artwork.

All assets must be original or explicitly licensed for distribution.

## 4. Game Systems

Implement complete, functioning systems for:

- Point-and-click movement and interaction.
- Hidden-object discovery and collection.
- Inventory storage, inspection, use, and item combinations.
- Environmental puzzles and logical deduction.
- Dialogue and narrative progression.
- Chapter and location transitions.
- Persistent game state and save/load functionality.
- Contextual hints to prevent unreasonable frustration.
- Sound settings, display settings, and basic accessibility options.

Puzzle solutions must follow understandable logic, with clues discoverable through normal gameplay.

### Purchased sound-effects source

The owner has purchased Gamemaster Audio Pro Sound Collection v1.3 to improve
the current weak effects. Use the supplied recordings as the preferred source
for suitable material, action and ambience effects, with careful selection,
variation and mixing. See `docs/GAMEMASTER_AUDIO_REVIEW.md` for the available
formats, reviewed guides and remaining listening/integration work. Preserve
the licensed library and include only the game's selected sounds in runtime
packages. Source availability is not evidence that audio quality is finished.

### Sound selection and atmosphere

After selecting the opening recordings, the owner delegated routine sound
selection and mixing to Codex. The owner need not review every recording;
choose appropriate library material, document each choice and use occasional
whole-room feedback to refine the atmosphere. Preserve the owner's explicit
choices and accept later overrides. Use `docs/SOUND_SELECTION_BRIEF.md` and
`docs/audio-selection/requests.json`. Technical audio analysis does not amount
to subjective listening; do not claim to have heard a mix without doing so.
The larger library should support a rich, varied soundscape: distinct room
ambiences, occasional environmental details, mechanical start/move/stop states,
material interactions and expressive story payoffs. There is no arbitrary cap
on the number of effects. Choose and balance layers to establish the setting
and respond to events while keeping important clues and dialogue intelligible.

## 5. Technical Requirements

Prefer Godot 4 unless another engine offers a compelling technical advantage.

The final game must:

- Run locally without an internet connection.
- Support Windows and Linux.
- Have a suitable graphical interface and scalable display.
- Load all required assets from its packaged distribution.
- Preserve player progress reliably.
- Require no developer tools or manual dependency installation by the player.
- Handle unexpected player interactions without corrupting progression.

## 6. Quality Assurance

Create and maintain a complete puzzle dependency map.

Verify that:

- Every chapter is accessible.
- Every essential object is obtainable.
- No puzzle requires an undiscoverable clue.
- No action can accidentally make the game impossible to complete.
- Every inventory interaction produces the intended result.
- Save/load works throughout the story.
- The game can be completed from its opening scene through its final ending.

Use automated testing wherever practical, supplemented by actual game execution and inspection.

Document which tests were completed and any remaining limitations.

## 7. Final Deliverables

Produce:

1. A complete Windows game distribution.
2. A complete Linux game distribution.
3. The complete game project and source code.
4. All required visual and audio assets.
5. A concise installation and gameplay guide.
6. A development report describing architecture, features, testing, and any known issues.

Packages should be ready to extract and play.

A project that has not been successfully packaged and tested must not be described as a finished release.

## 8. Autonomy

You are responsible for the creative and engineering decisions.

Do not ask me to write the story, design puzzles, create artwork, or implement gameplay systems.

Develop a production plan, execute it in manageable stages, evaluate your own work, and correct deficiencies as you discover them.

You may use the available development, asset-generation, build, and testing tools.

Do not silently reduce the scope to a short demonstration. If a requirement cannot be completed, report the limitation accurately rather than presenting incomplete functionality as finished.

## 9. Acceptance Criteria

The project succeeds when a player can install the game, begin a new adventure, explore its world, uncover its mystery, solve its puzzles, save progress, and reach the intended conclusion without requiring intervention from the developer.

**The final result matters more than the amount of code produced.**

Your mission is not to demonstrate that you can create a game.

**Your mission is to create one.**

Begin by independently establishing the game's creative concept, technical architecture, puzzle structure, and production plan. Then proceed with implementation.
