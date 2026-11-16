# Mystery game desktop setup

Prepared on **14 November 2026** on **jaco-desktop**, Ubuntu 26.04.1 LTS, x86_64.
The development environment is ready. Full game production has not started.

## Project and starting point

- Project: `/home/jaco/Projects/mystery-game`
- VS Code is open on this project. Workspace trust was accepted by the user.
- `START_HERE.md` contains the ready-to-paste development request.
- `DEVELOPMENT_BRIEF.md` preserves the full challenge recovered from
  **Conversation opening**: 6–10 hours, 5–8 chapters, 30–50 environments,
  at least 60 puzzles, original artwork, complete Windows/Linux delivery.
- `docs/PRODUCTION_PLAN.md` gives milestones and acceptance gates, and
  `docs/PUZZLE_DEPENDENCIES.md` is ready for the future dependency map.
- Local Git repository: branch `main`, with a setup checkpoint and no remote.
  A repository-only technical identity, `Mystery Game Development
  <mystery-game@localhost>`, enables local checkpoints without inventing a personal
  email address or changing global Git settings.

## Installed and configured

| Component | What changed |
| --- | --- |
| Godot | Installed official **4.7.2 stable**, standard GDScript build, at `/home/jaco/.local/opt/godot/4.7.2/godot`. SHA-256 verified against the official GitHub release metadata before use. |
| Godot command | Added `/home/jaco/.local/bin/godot4`, pointing to the versioned executable. |
| Export templates | Installed matching **4.7.2.stable** Linux and Windows **x86_64**, both debug and release, plus `version.txt`, in `/home/jaco/.local/share/godot/export_templates/4.7.2.stable`. Other platform templates were not installed. |
| VS Code Godot tools | Installed `geequlim.godot-tools` **2.7.1**. Configured the executable, automatic headless language server, F5 debug launch, run/editor/export tasks and build verification. |
| Codex project settings | Selected `gpt-6-astra`, Extra High reasoning, project write access, and requests for approval when needed. Verified the effective configuration through the installed extension's engine. |
| Codex trust | Added only this exact project folder as trusted in `/home/jaco/.codex/config.toml`. The original file was backed up, and all other existing values were verified unchanged. |
| Desktop menu | Added **Mystery Game Development** and **Godot 4.7.2** application entries under `/home/jaco/.local/share/applications/`. |
| Project | Created the Godot project, original-art test scene, asset directories, Git exclusions, editor settings, export presets, repeatable checks and production documentation. |

Settings are recorded in both the folder's `.vscode/settings.json` and
`Mystery Game.code-workspace`, so opening either entry point works. The initial
multi-root workspace lookup issue shown in the screenshot was corrected; the
Godot extension subsequently logged a successful language-server connection.
The language server is a local editor child process, not an installed service.

## Already present and reused

- **VS Code 1.145.2** — not installed or upgraded by this setup.
- **OpenAI Codex extension** — already installed. VS Code updated it during this
  session from 26.1021.22027 to **26.1111.21308**. Its bundled engine reports
  **codex-cli 0.169.0-alpha.11.1**. The separate desktop-bundled CLI remains
  **0.167.0-alpha.3.2**; no additional CLI installation was needed.
- **ChatGPT authentication** — already active and verified using the extension's
  own engine. No credentials were copied into the project.
- **Astra access** — confirmed in the extension engine's available-model list.
  The existing global model preference was already Astra; project settings also
  explicitly select it. No game-development request has been submitted yet.
- **Git 2.53.0, Python 3, curl, unzip and Wine 10.0** — reused without system changes.

## Original artwork

Built-in image generation and the `imagegen` skill are available. The extension's
engine reports the capability enabled. A fresh image was successfully generated
in this desktop Codex session, saved to `assets/art/setup-key.png`, inspected, and
loaded into Godot and the exported packages. It is a 1254 × 1254 RGBA PNG with
real transparency, used only as a setup fixture. Its prompt and provenance are
saved in `docs/ARTWORK_WORKFLOW.md` and `assets/asset-manifest.json`.

No API key, paid API workflow, local image model, GPU service or Python image API
environment was provisioned. Built-in generation uses the existing Codex account.
An image request from the VS Code sidebar itself has not been exercised, although
the extension engine's capability and skill are enabled. See the official
[image-generation documentation](https://learn.chatgpt.com/docs/image-generation).

## Verification completed

- Official Godot editor and template archive checksums verified.
- Godot project import and GDScript parsing passed.
- Source scene loaded the original image and passed a test storage round trip.
- Linux and Windows release exports produced real x86_64 executables and PCKs.
- Both setup ZIP packages passed archive integrity checks.
- Extracted Linux package passed its startup/resource/storage checks outside the
  source folder. The graphical Linux build also ran on the RTX 5070 and produced
  an inspected screenshot.
- Extracted Windows package passed its startup/resource/storage checks under
  Wine in a dedicated temporary prefix. This is **not native Windows testing**.
- The trusted VS Code window activated Codex and Godot Tools. Godot's language
  server connected successfully on loopback. The F5 configuration is supplied;
  a click-through F5 debugger session was not separately exercised.
- No direct edits were made to VS Code's global settings. Its checksum changed
  while VS Code was running; the source of that change was not established, so
  those settings were preserved rather than reverted. The only intentional global
  Codex configuration difference is the exact project's trust entry.

Repeat the engine checks with `tools/game.sh verify`, or press Ctrl+Shift+B in
VS Code. F5 runs the project; the **Game: open Godot** task opens the visual editor.
Verification excludes scratch folders from Godot and directs test saves into the
project's `work/` directory. An initial recheck followed Wine's filesystem mapping
during scanning; that importer was stopped, scratch folders were excluded, the
temporary prefix was removed, and the clean verification then passed.

Evidence is saved in `docs/SETUP_VERIFICATION.json`, `builds/verification.json`,
`builds/windows-wine-check.json`, and `builds/logs/`. The screenshot is
`builds/linux-scene.png`.

## Remaining work and limits

There is no known blocking installation or sign-in issue for starting development.
The full game, story, puzzles and finished art still need to be developed from the
brief. The existing checks validate only the setup scene; they do not validate a
future game's gameplay, saves, playtime or opening-to-ending completion.

Native Windows playtesting remains outstanding. The Windows exports are unsigned;
code-signing certificates and publishing were not part of this setup. No GitHub
repository or remote backup was created. Standard built-in artwork generation
remains subject to the account's available usage.

Setup-only packages are in `builds/mystery-game-setup-linux-x86_64.zip` and
`builds/mystery-game-setup-windows-x86_64.zip`. They are environment-validation
builds, not the requested finished mystery game.

## Reversibility and scope

All installations are user-local. No administrator-level packages, Atlas/GCC
configuration, production-server services, firewall rules or GPU drivers were
changed. Existing unrelated VS Code extensions were not intentionally altered.
Godot generated its normal user configuration/cache, and the test run created a
dedicated `mystery-game-development` player-data directory. Large download archives
and the temporary Wine environment were removed after verification.

To undo this setup later: preserve any game work first, then remove the new project,
Godot 4.7.2 directory and command link, the 4.7.2.stable template directory, and the
two new desktop entries. Uninstall only `geequlim.godot-tools` if it is no longer
needed. Remove only this project's trust entry from the user Codex configuration;
do not replace the entire file if other preferences have changed since setup.
The pre-change backup is stored privately at
`/home/jaco/Documents/Codex/2026-11-14/referenced-chatgpt-conversation-this-is-an/work/codex-config-before-project-trust.toml`.

Official setup references: [Godot downloads](https://godotengine.org/download/linux/),
[Godot Tools](https://github.com/godotengine/godot-vscode-plugin),
[Codex IDE extension](https://learn.chatgpt.com/docs/codex/ide),
[Codex project configuration](https://learn.chatgpt.com/docs/config-file/config-advanced).
