# The Quiet Meridian — credits and licenses

The original story, puzzle design, GDScript systems and authored project
content were created for this repository. The title and characters are
fictional. This document records included materials; it does not relicense
third-party components.

## Engine and bundled components

The game uses **Godot Engine 4.7.2**, distributed under the MIT license.
The complete engine license text, component attribution and third-party
license texts extracted from the actual installed engine are included in
`GODOT_NOTICES.txt`. Preserve that file when distributing the binaries.

Godot Engine: https://godotengine.org/

## Fonts

The interface uses bundled DejaVu Sans and DejaVu Serif fonts. Their license
and attribution are preserved in `assets/fonts/LICENSE.txt` in the source
distribution and `FONT_LICENSE.txt` beside the packaged executables.
DejaVu's upstream attribution and the Bitstream Vera permissions apply to
these fonts; the game's artwork or code claims do not replace them.

## Original artwork and audio

Current background music is **Sonder by Purrple Cat**, from *City Nights 2*
(2023), supplied by the owner through Chosic. This third-party track replaces
the active chapter score. Its recording is unchanged; playback repeats and
adjusts volume. See `MUSIC_LICENSE.txt` for the supplied Chosic
CC BY-SA 3.0 credit, confirmed by the owner's screenshot, and the preserved
history of differing artist/catalogue listings. The original authored score below
remains in the source history and is not the selected runtime music.

The city map is original project-authored vector cartography. Its SVG, generator,
licence note and provenance are retained under `assets/map/`; its six districts
and 36 location pins are defined in `content/city-map.json`. It contains no
third-party map tiles, geographic datasets or stock illustrations.

Generated artwork is recorded in `assets/asset-manifest.json` with original
prompts, generation tool, date, source paths, reference provenance and review
status. Generation uses the built-in image tool; source images are kept in
the repository. The setup-key image is an earlier pipeline fixture, not a
claim of final production artwork.

The earlier project-authored procedural audio was generated locally by
`tools/generate_audio.py` using Python's standard library. The six 24-second
ambient loops and two interaction cues contain no sampled recordings.
`assets/audio/manifest.json` records deterministic seeds, synthesis method,
checksums, signal measurements and review status. Review the manifest for the
status of each asset rather than treating an unreviewed asset as final.

The audiovisual pass replaces the runtime music with original compositions
rendered by `tools/compose_score.py`. Nine musical cues, six ambience beds and
twelve effects use project-authored oscillators/noise, envelopes, arrangements
and note events. There are no external recordings, sample libraries or generated
music-provider outputs in these assets. PCM masters, event scores, exact hashes
and tool versions are retained; see `assets/audio/score/manifest.json` and
`SCORE_DESIGN.md`. Development-only numerical/encoding dependencies are listed
in `tools/score-requirements.txt`; their executables are not shipped in the game.

Seven new transparent expression sheets use only the existing original cast as
reference. Their full prompts and output hashes are in
`docs/art-prompts/av-polish/` and `assets/art/characters/manifest.json`.
The OpenAI Terms of Use effective 1 January 2026 assign output rights as between
the user and OpenAI, to the extent permitted by law; output need not be unique.
This records the provider terms, not a guarantee of exclusive copyright.
Source checked 14 November 2026:
https://openai.com/policies/terms-of-use/

The playable game includes **98 AI-generated speech recordings** across seven
fictional character voices, generated through the OpenAI GPT Live API via
Jaco Audio Clips. Exact scripts, performance directions, model/preset identities,
master and encoded hashes, usage receipts and technical selection decisions are
retained in `content/voice-script.json` and `voice-production/`.
Original and replacement WAV masters are preserved under
`assets/audio/voice-masters/`, excluded from runtime import by `.gdignore`.
Only the selected compressed recordings are used in play. Technical checks do
not establish human performance acceptance; see `VOICE_BATCH_REPORT.md`.
The source distribution retains three initial **AI-generated GPT Live audition**
masters, one Mara performance revision and two silent failure captures in an excluded development folder, with
approvals, requests, usage, hashes and review holds. The source-matched script
and fictional preset casting are prepared. Before adding approved provider output,
retain the provider/model/preset, prompt, generation date, local master, hash,
commercial-use terms and listening review. The approved audition workflow uses
OpenAI GPT Live API preset voices for fictional characters, not recordings from
consumer ChatGPT. API output rights are assigned to the customer as between the
parties, subject to applicable law and terms; uniqueness is not guaranteed.
AI-generated voice provenance must remain disclosed with accepted recordings.
Sources checked 14 November 2026:
https://openai.com/policies/services-agreement/
https://openai.com/policies/service-terms/

The optional offline transcription tool and model are development-only and are
not included in playable builds. Their licenses and pinned versions are recorded
in `VOICE_ASR_PROVENANCE.md`. The second independent checking model and its
MIT license are recorded in `voice-production/asr-medium-provenance/`.
No Runway assets or subscriptions were used.

No external paid API setup, purchased stock-art license, online service or
credential is required to play these packages.

## Material Foley recordings

The subsequent interaction-sound pass uses edited and layered **CC0 recordings**
by Kenney and rubberduck. These recordings are third-party material, distinct
from the project's original synthesized score and legacy effects above.

* Kenney, *50 RPG sound effects*: https://opengameart.org/content/50-rpg-sound-effects
* rubberduck, *100 CC0 SFX #2*: https://opengameart.org/content/100-cc0-sfx-2
* CC0 1.0: https://creativecommons.org/publicdomain/zero/1.0/

Creator declarations checked 14 November 2026. Selected original recordings,
archive/member hashes, source URLs, creator declarations and each processing
recipe are retained under `assets/audio/foley/`. See its `manifest.json` and
`LICENSES.txt` (also shipped as `FOLEY_LICENSES.txt` beside both executables).
CC0 permits commercial use and modification; no endorsement is implied. No
subscription, paid call, attribution-dependent account or network connection
is required to use these sounds in the offline game.

## Owner-selected opening recordings

The hidden-object opening retains thirteen owner-selected recordings from the owner's
purchased **Gamemaster Audio Pro Sound Collection v1.3**. Jaco selected each
master; source hashes, processing and runtime hashes are recorded in
`docs/audio-selection/opening-provenance.json`. These are licensed third-party
recordings, distinct from the original synthesized score. Commercial game use
and editing are permitted under the collection EULA. They are not CC0 and this
project does not grant rights to reuse the recordings independently.

The full campaign additionally uses twenty Codex-selected masters from the
same purchased collection. The 36 room mixes and additional interaction cues
are documented in `audio-selection/campaign-provenance.json`, with exact
source hashes, preparation recipes and runtime identities. No rights in the
underlying licensed recordings are transferred by the project.

Only the selected prepared audio is embedded in playable game data. Shareable
source archives exclude those reusable files; see `RESTORE_LICENSED_AUDIO.md`
for restoring them from a licensed collection. No purchased originals are
overwritten or distributed as a library.

https://gamemasteraudio.com/wp-content/uploads/2020/01/Gamemaster-Audio-End-User-License-Agreement.pdf
