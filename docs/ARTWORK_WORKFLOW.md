# Original artwork workflow

Built-in image generation is available in this Codex desktop session. The
installed VS Code Codex engine also reports image_generation enabled, and the
shared imagegen skill is present. ChatGPT sign-in is active. No separate API
key or local diffusion service was installed or configured.

In the Codex extension, ask for artwork or explicitly invoke `$imagegen`.
Generate backgrounds, portraits, inventory art and interface assets using a
consistent style guide and approved reference images. Keep reusable prompts,
aspect ratios, palette and character details in this directory as production
develops. Request genuine transparency for isolated objects.

Always copy selected originals from the tool's output into `assets/art/` and
record prompt, tool, date, source/reference provenance, intended use and review
status in `assets/asset-manifest.json`. Preserve originals. Add derivatives
only when needed by the game and review them in Godot at the intended scale.
Review distribution rights for external references, fonts and audio separately.

`assets/art/setup-key.png` is an original test icon generated successfully on
2026-11-14 through the built-in image tool. It is a pipeline fixture, not a
requirement for the game's story or final art direction. The desktop generation
and its Godot import were tested; an image request from the VS Code sidebar
itself has not been exercised in this setup. Service/account limits still apply.

Test prompt:
Create one small original 2D mystery-adventure inventory icon to validate an
artwork pipeline, not to establish the game's final art direction: an ornate
brass key with a circular bow and a dark teal enamel inset. Painterly illustration
with clean readable silhouette, subtle wear and polished highlights, centered
isolated object filling most of a square composition. Transparent background.
No text, logos, watermark, border or extra objects.

Reference: https://learn.chatgpt.com/docs/image-generation

## The Quiet Meridian production set

The selected direction uses gouache and fine ink, petroleum teal shadows,
amber light, ivory paper, tarnished brass and restrained coral. All characters
and settings are fictional. Original backgrounds are separate PNGs under
`assets/art/locations/`; the cast, inventory and evidence sprites are preserved
as original atlases and addressed through Godot texture regions.

The complete prompt set is in `docs/art-prompts/`. The central ledger is
`assets/asset-manifest.json`, including SHA-256 hashes and links to the original
generation provenance. There are no external artist reference images. Selected
originals remain in the repository; source tool-cache paths are provenance only.

`content/presentation.json` maps portrait/item/evidence IDs to atlas cells.
`content/hotspot-layout.json` contains all 108 reviewed interaction anchors.
The `ART_REVIEW_CH*.md` documents distinguish painted scene detail, overlaid
original sprites, inspector text and remaining correspondence concerns.

The application icon is an original brass meridian seal generated with the
built-in tool. Procedural audio has a separate source/seed/hash ledger in
`assets/audio/manifest.json`. See `LICENSES.md` for engine and font notices.
