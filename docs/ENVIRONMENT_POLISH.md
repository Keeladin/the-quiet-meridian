# Illustrated environment motion — audiovisual alpha

The environmental pass animates the existing original paintings in place. It adds local water and reflections, drifting mist, warm lamp flicker, rain or floating dust, kettle steam, small mechanical movements and expanding interaction feedback. The paintings no longer depend on camera drift to appear alive. All 36 locations have an authored profile in `content/environment-effects.json`; this does not change the narrative, puzzle dependencies or six-chapter scope.

## Implementation and art direction

`scripts/environment_stage.gd` owns a non-interactive illustration layer and a non-interactive effects layer. `shaders/environment_water.gdshader` runs in Godot 4.7.2's Compatibility renderer. Normalized placements stay independent of the viewport size. The stage and both children ignore mouse input so gameplay hotspots remain accessible.

Water distortion and glints apply only to small surface regions. Window mullions, canal railings, books and equipment are deliberately outside the masks. The ferry landing has additional foreground exclusions for its posts and rails. A native render test compares water-only frames and requires pixels outside the water masks and inside the protected post regions to remain exactly unchanged. Displacement is restrained; this is illustrated water rather than a simulation of the entire canal.

Lamp halos sit on depicted fixtures. Fog occupies authored background bands. Dust and rain use deterministic seeded positions; no network or particle texture is required. Steam rises from depicted kettle/machinery regions. Selected ropes, a pendulum, hanging signal cloth, paper, a piston and indicators move in localized regions. The machine-room flywheel has moving rim highlights; its painted spokes are not a fully separated rotating sprite. The Gate Crown's safety mechanism stays still, and evidence clock faces and puzzle signal patterns are not changed for decoration.

Interaction rings expire after 0.85 seconds and are capped at eight. The application chooses the position and color; the stage has no knowledge of solutions, inventory or save state.

## Reduced motion and offline operation

Reduced motion stops the ambient clock, clears interaction rings and disables shader motion, particles, steam and mechanical overlays. It restores the original static painting. Turning animation back on resumes the existing stage. Four native preview pairs verify that reduced-motion frames stay pixel-identical after attempted advancement.

All effects are GDScript, shader code and local JSON. They introduce no runtime service, account, API, codec package or remote dependency. Windows and Linux use the same local assets and Compatibility-renderer implementation. Full export and package results belong to `builds/verification.json`, not to the environmental test alone.

## Tests and previews

`tests/test_environment.gd` passes 1,166 headless assertions across all 36 profiles: bounded normalized placements, effect budgets, deterministic reduced motion, input passthrough, resuming motion, pulse creation and pulse expiry. The native mode passes 1,189 assertions and additionally renders the ferry landing, machine room, reed jetty and memory room at 1280 × 720, compares animated frames, compares static accessibility frames and checks water-mask isolation.

Run the headless suite with the repository's isolated Godot environment. For renderer previews, run the same script without `--headless` and add `-- --preview-dir=/absolute/path/to/mystery-game/work/environment-preview`. The destination must remain under this repository's ignored `work/` directory. Preview files are named by location and pose time; the ferry also produces a 48-frame sequence. The combined audiovisual preview is captured separately by `tools/capture_av_preview.gd`.

`tools/verify.py` now runs the environmental, audio director, character and audiovisual UI suites, plus score and voice provenance audits, and includes this document and the score, voice and audiovisual reports in both player packages.

## Provenance and remaining quality work

This pass creates no new borrowed raster art. The original source paintings and their generation/licensing records remain under `assets/art/`; they are not rewritten. All effect code, placements, deterministic seeds and configuration are retained in this repository. There are no imported particle packs, footage or third-party shader assets.

Original paintings were reviewed while placing the effects, and four representative native scenes receive image comparisons. The remaining 32 scenes have structural/runtime coverage but have not received a complete manual moving-scene review on both target operating systems. Rectangular surface masks and small image displacements remain a practical limitation around complex silhouettes. The pass is not full hand-separated cinematic scene animation. Further work should include long-session comfort/performance checks, manual inspection at varied resolutions, more expressive cut-out mechanisms and external player review. These tests do not constitute a blind playthrough, native Windows acceptance, a measured 6–10 hour duration or finished-game presentation approval.

## Subsequent all-location placement review

`ENVIRONMENT_FULL_REVIEW.md` supersedes the earlier four-scene sampling gap for
placement coverage: all 36 locations were rendered and inspected, with eight
confirmed water/fog/light corrections and scoped native recaptures. All reduced-
motion pairs are byte-identical. Continuous motion, comfort, minimum hardware,
other display configurations and native Windows remain separate quality gates.
