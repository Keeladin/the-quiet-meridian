# Revised hidden-object review — 14 November 2026

Owner feedback: the checklist/search loop is correct, but objects should be
more obscure. The owner specifically requested words with multiple visual
meanings (club as a suit symbol, wooden club or wall watermark), and familiar
alternative names (goblet for a wineglass).

## Implemented in the separate preview

The Dispatch Office now has seventeen clues. New artwork uses denser clutter,
partial overlaps and closer colour/shape relationships. The list mixes literal
names with Plume (feather), Timepiece (watch/clock), Knight and Club. Club has
two valid depictions: a faded card pip and a wall stain. Finding either crosses
off the clue once. Additional credible visible matches, such as the second
bottle and timepiece, also count. The hint points to one valid depiction.
Goblet/wineglass is a documented future authoring example, not a claim that a
new goblet was added to this painting.

Each primary and alternative region was mapped to the revised image. Test
observations are recorded separately from runtime polygons. The list now uses
six columns, leaving more room for the image. Found-item feedback can explain
a word's meaning after discovery. Zoom, keyboard search, hints, fullscreen,
score and sound remain available. The revision uses a new preview save file;
the old preview save and main campaign saves remain untouched.

## Validation

108 state and interaction assertions pass headlessly and with native Linux
rendering. Checks cover primary and alternative hits, one award per clue,
invalid alternative geometry, unlisted space, partial and completed saves,
invalid-save transactionality, resized/zoomed clicks, checklist and hint
behaviour, and completion. Native screenshots were inspected at 960×600,
1280×800 and 1920×1080. The whole-project automated verification passes.
Extracted standalone Linux and Windows packages pass startup checks; Windows
was exercised under Wine, not native Windows.

These checks establish working interactions, not a measured difficulty level
or blind playtime. This is still one separate search, not a completed campaign
conversion. The owner has accepted the basic loop; full-game art, search
coverage, story integration and pacing remain unfinished.

## Artwork and reproduction

Art: `assets/art/searches/dispatch-office-v2.png`.
Exact two-step prompt set: `docs/art-prompts/hidden-object-dispatch-v2.txt`.
Provenance: `docs/art-prompts/hidden-object-dispatch-v2-provenance.json` and
`assets/asset-manifest.json`. Both passes used built-in OpenAI image generation.
The original first-version painting and previous packages are preserved.

Rebuild with `python3 tools/build_hidden_object_preview.py`.
Run all project checks with `tools/game.sh verify`.
The branch remains `feature/classic-hidden-object` in
`/home/jaco/Projects/mystery-game/work/classic-hidden-object`.

## Audio revision 3

All thirteen owner-selected opening sounds are now integrated in this isolated
preview. See `OPENING_AUDIO_PREVIEW_REPORT.md` for playback, preparation, tests
and the listening approval still needed. Revision 3 retains the revised art,
seventeen clues and v2 preview save; it adds a separate music switch.
