# The Quiet Meridian

A story-driven hidden-object mystery set in the canal city of Leth.

Seven years after a devastating flood, paper conservator Iona Vale returns home
when her friend Mara disappears. Search the city, follow Mara's evidence, and
discover what really happened to the flood that destroyed her father's reputation.

## Download and play

**[Download the Windows or Linux game](https://github.com/Keeladin/the-quiet-meridian/releases/tag/campaign-v4)**

Download the ZIP for your operating system, extract it, and keep the executable
and `.pck` file together. Run `quiet-meridian.exe` on Windows or
`quiet-meridian.x86_64` on Linux. On Linux, allow the executable to run if your
archive manager does not preserve permissions. The game runs offline; no Godot
editor, account, API key or additional sound-library purchase is needed to play.

## Current campaign

- Six chapters and 36 illustrated hidden-object rooms, with 507 finds.
- A city map, chapter investigations, evidence, inventory and item combinations.
- Timed Detective searches, limited hints, penalties and useful Insight rewards.
- Automatic saving, fullscreen support, accessibility and separate audio controls.
- 98 recorded dialogue and narration lines across seven fictional voices, with
  timed subtitles, replay, skipping and dialogue-aware audio mixing.
- Original AI-generated illustrations, environmental animation and licensed audio.

This is **Campaign v4, a playable development alpha**. The original source revision
is `dc0111fb50225af6f619a37816da20a3982b1255`. Its full verification passed 41
checks, including extracted native Linux and Windows-under-Wine package checks.
Native Windows gameplay, blind playtesting, measured duration and final acting
and sound review remain open. The intended 6–10 hour duration is not yet measured.

See the [player guide](docs/PLAYER_GUIDE.md),
[production plan](docs/PRODUCTION_PLAN.md), and
[voice integration report](docs/VOICE_BATCH_REPORT.md).

## Source and development

Godot **4.7.2**, GDScript, Compatibility renderer; Windows/Linux x86_64.
Open `project.godot` in Godot. Read `AGENTS.md` and `DEVELOPMENT_BRIEF.md` before
changing the project. Narrative and puzzles live in `content/`; game systems
live in `scripts/`; illustrations, voices and other assets live in `assets/`.
Story and puzzle documents contain spoilers.

**The public source intentionally excludes the purchased Gamemaster Audio files.**
The ready-to-play downloads include those sounds within the game. To reproduce
the complete build from source, restore them from your own licensed collection
using [the restoration guide](docs/RESTORE_LICENSED_AUDIO.md). Source audio checks
will fail until those files are restored; this is not a self-contained sound pack.

Set `GODOT_BIN` to your installed engine when using the helper commands:

```sh
GODOT_BIN=/path/to/godot tools/game.sh run
GODOT_BIN=/path/to/godot tools/game.sh test
GODOT_BIN=/path/to/godot tools/game.sh verify
```

The original development workspace used local editor paths; adjust the Godot
executable in VS Code to match your installation. Engine export templates and
the development-only dependencies documented by the tools are required for
packaging. The live speech-production tools are optional developer tools and
require the developer's private records and authorization; they are not needed
to play or to use the existing recorded voices.

## Publication and rights

This is a fresh public source snapshot. The complete local development history
has been retained privately rather than publishing earlier commits containing
licensed reusable recordings. Raw production billing receipts, private ledgers,
credentials, local caches, player saves and build folders are not included.
See [publication details](docs/PUBLICATION.md).

Making the repository public does not grant a blanket open-source or asset-reuse
licence. Third-party materials retain their respective licences; see
[credits and licences](docs/LICENSES.md). AI-generated artwork and speech are
identified in the asset and voice provenance records.

Music: **Sonder by Purrple Cat** — https://purrplecat.com/  
Music promoted by https://www.chosic.com/free-music/all/  
Creative Commons CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0/  
Full details: [music attribution](docs/MUSIC_LICENSE.txt).
