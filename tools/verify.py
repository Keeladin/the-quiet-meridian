#!/usr/bin/env python3
"""Audit, exercise, export and package The Quiet Meridian development build.

The deterministic solution traversal is not a blind player playthrough. Wine
execution is not native Windows validation. Neither proves the 6–10 hour target.
"""
from pathlib import Path
import datetime
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT_BIN", "/home/jaco/.local/bin/godot4")
BUILDS = ROOT / "builds"
LOGS = BUILDS / "logs"
WORK = ROOT / "work"
CHECKS = []
MODE = sys.argv[1] if len(sys.argv) > 1 else "verify"
SMOKE_MARKER = "QUIET_MERIDIAN_SMOKE_OK"
SOURCE_REVISION = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, check=True, capture_output=True, text=True).stdout.strip()
SOURCE_DIRTY = bool(subprocess.run(["git", "status", "--porcelain"], cwd=ROOT, check=True, capture_output=True, text=True).stdout.strip())
for folder in (BUILDS, LOGS, WORK):
    folder.mkdir(parents=True, exist_ok=True)
for folder in (BUILDS, WORK):
    (folder / ".gdignore").touch()
# Keep editor state inside the repository too. Export templates are only read;
# point the isolated engine data directory at the existing installation.
TEMPLATE_SOURCE = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))) / "godot/export_templates"
TEMPLATE_LINK = WORK / "engine-data/godot/export_templates"
TEMPLATE_LINK.parent.mkdir(parents=True, exist_ok=True)
if TEMPLATE_SOURCE.is_dir() and not TEMPLATE_LINK.exists():
    TEMPLATE_LINK.symlink_to(TEMPLATE_SOURCE, target_is_directory=True)


def environment(extra=None, isolated=False):
    env = os.environ.copy()
    env.update({"XDG_DATA_HOME": str(WORK / ("user-data" if isolated else "engine-data")),
                "XDG_CONFIG_HOME": str(WORK / "config"),
                "XDG_CACHE_HOME": str(WORK / "cache")})
    if extra:
        env.update(extra)
    return env


def run(name, args, marker=None, cwd=None, extra_env=None, isolated=False, timeout=240):
    env = environment(extra_env, isolated)
    try:
        result = subprocess.run(args, cwd=cwd or ROOT, env=env, capture_output=True,
                                text=True, errors="replace", timeout=timeout)
        output = result.stdout + result.stderr
        passed = result.returncode == 0 and "SCRIPT ERROR:" not in output and "ERROR:" not in output
        if marker:
            passed = passed and marker in output
        check = {"check": name, "passed": passed, "exit_code": result.returncode}
    except subprocess.TimeoutExpired as exc:
        output = str(exc.stdout or "") + str(exc.stderr or "") + "\nTIMEOUT"
        check = {"check": name, "passed": False, "timeout_seconds": timeout}
    (LOGS / (name + ".log")).write_text(output)
    CHECKS.append(check)
    print(name + ": " + ("PASS" if check["passed"] else "FAIL"), flush=True)
    if not check["passed"]:
        print(output[-6000:])
        raise RuntimeError(name + " failed; see builds/logs")
    return output


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def package(platform, preset, executable):
    folder = BUILDS / "quiet-meridian" / platform
    folder.mkdir(parents=True, exist_ok=True)
    run("export-" + platform, [GODOT, "--headless", "--path", str(ROOT),
                              "--export-release", preset, str(folder / executable)])
    for filename in (executable, "quiet-meridian.pck"):
        path = folder / filename
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError("Missing export file: " + str(path))
    # Players get the guide and every licence. Development reports stay in the
    # repository and the source archive, where they cannot go stale in a build.
    for source in ("PLAYER_GUIDE.md", "LICENSES.md", "GODOT_NOTICES.txt", "MUSIC_LICENSE.txt",
                   "VOICE_ASR_PROVENANCE.md", "RESTORE_LICENSED_AUDIO.md"):  # cited by LICENSES.md
        shutil.copy2(ROOT / "docs" / source, folder / source)
    shutil.copy2(ROOT / "assets/fonts/LICENSE.txt", folder / "FONT_LICENSE.txt")
    shutil.copy2(ROOT / "assets/audio/foley/LICENSES.txt", folder / "FOLEY_LICENSES.txt")
    (folder / "README.txt").write_text(
        "THE QUIET MERIDIAN — development alpha\n\n"
        "Extract every file into the same directory and run " + executable + ".\n"
        "An offline Godot 4.7.2 game. No editor, account, internet connection or API key is required.\n"
        "Read PLAYER_GUIDE.md for controls and LICENSES.md for attribution.\n\n"
        "This is a development build, not an accepted finished release.\n"
        "The 6–10 hour target has not been measured with blind first-time players.\n"
        "Native Windows gameplay testing and a complete manual playthrough remain required.\n")
    with (folder / "SHA256SUMS.txt").open("w") as stream:
        for path in sorted(folder.iterdir()):
            if path.is_file() and path.name != "SHA256SUMS.txt":
                stream.write(sha256(path) + "  " + path.name + "\n")
    archive_path = BUILDS / ("quiet-meridian-" + platform + "-x86_64.zip")
    with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(folder.iterdir()):
            if path.is_file():
                archive.write(path, arcname="quiet-meridian-" + platform + "/" + path.name)
    with zipfile.ZipFile(archive_path) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("Archive checksum failure: " + str(archive_path))
    CHECKS.append({"check": "package-" + platform, "passed": True,
                   "bytes": archive_path.stat().st_size, "sha256": sha256(archive_path)})
    return archive_path


def source_package():
    # Source only; .gitignore excludes build products, private files and caches.
    result = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
                            cwd=ROOT, check=True, capture_output=True)
    paths = sorted(set(result.stdout.decode().split("\0")) - {""})
    archive_path = BUILDS / "quiet-meridian-source.zip"
    with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
        for relative in paths:
            path = ROOT / relative
            if path.is_file() and not relative.startswith(("assets/audio/licensed-opening/", "assets/audio/licensed-campaign/")):
                archive.write(path, arcname="quiet-meridian-source/" + relative)
    with zipfile.ZipFile(archive_path) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("Source archive checksum failure")
    CHECKS.append({"check": "package-source", "passed": True,
                   "bytes": archive_path.stat().st_size, "sha256": sha256(archive_path)})
    return archive_path


def extracted_smoke(archive_path, platform, executable, launcher=None):
    with tempfile.TemporaryDirectory(prefix="package-check-", dir=WORK) as temporary:
        with zipfile.ZipFile(archive_path) as archive:
            archive.extractall(temporary)
        folder = Path(temporary) / ("quiet-meridian-" + platform)
        path = folder / executable
        path.chmod(0o755)
        args = (launcher or []) + [str(path), "--headless", "--", "--smoke-test"]
        extra = None
        if launcher:
            extra = {"WINEPREFIX": str(WORK / "wine"), "WINEARCH": "win64", "WINEDEBUG": "-all",
                     "WINEDLLOVERRIDES": "winemenubuilder.exe=d"}
        run(platform + "-extracted-package-smoke" + ("-wine" if launcher else ""),
            args, SMOKE_MARKER, cwd=folder, extra_env=extra, isolated=True, timeout=180)


def main():
    if MODE not in {"verify", "export", "test"}:
        raise ValueError("Expected verify, export or test")
    version = run("engine-version", [GODOT, "--version"]).strip()
    CHECKS[-1]["version"] = version
    if not version.startswith("4.7.2."):
        raise RuntimeError("Expected Godot 4.7.2, found " + version)
    run("content-audit", [sys.executable, str(ROOT / "tools/audit_content.py")], "CONTENT_AUDIT_OK")
    run("art-provenance-audit", [sys.executable, str(ROOT / "tests/audit_art.py")], "ART_AUDIT_OK")
    run("puzzle-logic", [sys.executable, str(ROOT / "tools/check_puzzle_logic.py")], "PUZZLE_LOGIC_OK")
    run("route-boards", [sys.executable, str(ROOT / "tools/check_boards.py")], "BOARD_CHECKS_OK")
    run("audio-audit", [sys.executable, str(ROOT / "tools/generate_audio.py"), "--check"], "AUDIO_AUDIT_OK")
    run("score-audit", [sys.executable, str(ROOT / "tests/audit_score.py")], "SCORE_AUDIT_OK")
    run("foley-audit", [sys.executable, str(ROOT / "tests/audit_foley.py")], "FOLEY_AUDIT_OK")
    run("opening-audio-audit", [sys.executable, str(ROOT / "tests/audit_opening_audio.py")], "OPENING_AUDIO_AUDIT_OK")
    run("campaign-audio-audit", [sys.executable, str(ROOT / "tests/audit_campaign_audio.py")], "CAMPAIGN_AUDIO_AUDIT_OK")
    run("voice-production-audit", [sys.executable, str(ROOT / "tests/audit_voice.py")], "VOICE_AUDIT_OK")
    run("voice-audition-preview", [sys.executable, str(ROOT / "tools/build_voice_audition_preview.py")], "VOICE_AUDITION_PREVIEW_OK")
    run("voice-recorder-offline", [sys.executable, str(ROOT / "tests/test_voice_live.py")], "VOICE_LIVE_TESTS_OK")
    run("voice-fidelity-offline", [sys.executable, str(ROOT / "tests/test_voice_fidelity.py")], "VOICE_FIDELITY_TESTS_OK")
    run("voice-review-exceptions", [sys.executable, str(ROOT / "tests/test_voice_review.py")])
    run("import", [GODOT, "--headless", "--editor", "--path", str(ROOT), "--import"])
    if MODE != "export":
        run("state-and-progression", [GODOT, "--headless", "--path", str(ROOT),
                                     "--script", "tests/test_state.gd"], "STATE_TESTS_OK", isolated=True)
        run("ui-progression", [GODOT, "--headless", "--path", str(ROOT),
                              "--script", "tests/test_ui.gd"], "UI_TESTS_OK", isolated=True)
        for name, script, marker in (
                ("detective-state", "tests/test_detective_state.gd", "DETECTIVE_STATE_OK"),
                ("detective-ui", "tests/test_detective_ui.gd", "DETECTIVE_UI_OK"),
                ("city-map", "tests/test_city_map.gd", "CITY_MAP_OK"),
                ("campaign-search-art", "tests/test_campaign_search_art.gd", "CAMPAIGN_SEARCH_ART_OK"),
                ("case-guide", "tests/test_case_guide.gd", "CASE_GUIDE_OK"),
                ("search-layout", "tests/test_search_layout.gd", "SEARCH_LAYOUT_OK"),
                ("campaign-search-state", "tests/test_campaign_search_state.gd", "CAMPAIGN_SEARCH_STATE_OK"),
                ("hidden-object-search", "tests/test_hidden_object.gd", "HIDDEN_OBJECT_TESTS_OK"),
                ("hidden-object-audio", "tests/test_hidden_object_audio.gd", "HIDDEN_AUDIO_TESTS_OK"),
                ("environment-animation", "tests/test_environment.gd", "ENVIRONMENT_TESTS_OK"),
                ("audio-director", "tests/test_audio_director.gd", "AUDIO_DIRECTOR_TESTS_OK"),
                ("hotspot-presentation", "tests/test_hotspots.gd", "HOTSPOT_TESTS_OK"),
                ("interaction-audio", "tests/test_interaction_audio.gd", "INTERACTION_AUDIO_TESTS_OK"),
                ("character-performance", "tests/test_character.gd", "CHARACTER_TESTS_OK"),
                ("av-ui-integration", "tests/test_av_ui.gd", "AV_UI_TESTS_OK")):
            run(name, [GODOT, "--headless", "--path", str(ROOT), "--script", script], marker, isolated=True)
        run("source-smoke", [GODOT, "--headless", "--path", str(ROOT), "--", "--smoke-test"],
            SMOKE_MARKER, isolated=True)
    if MODE == "test":
        return
    linux = package("linux", "Linux x86_64", "quiet-meridian.x86_64")
    windows = package("windows", "Windows x86_64", "quiet-meridian.exe")
    source = source_package()
    audition = BUILDS / "quiet-meridian-voice-auditions.zip"
    natural = BUILDS / "quiet-meridian-natural-voice-audition.zip"
    (BUILDS / "SHA256SUMS.txt").write_text("".join(sha256(p) + "  " + p.name + "\n" for p in (linux, windows, source, audition, natural)))
    if MODE == "verify":
        extracted_smoke(linux, "linux", "quiet-meridian.x86_64")
        wine = shutil.which("wine")
        if wine:
            extracted_smoke(windows, "windows", "quiet-meridian.exe", launcher=[wine])
        else:
            CHECKS.append({"check": "windows-extracted-package-smoke-wine", "status": "not_run", "reason": "Wine unavailable"})
    CHECKS.append({"check": "native-windows-gameplay", "status": "not_run", "reason": "No native Windows test session performed"})
    CHECKS.append({"check": "blind-playthrough-duration", "status": "not_run", "reason": "Requires independent first-time players; automated answer traversal is not a duration test"})


if __name__ == "__main__":
    success = False
    try:
        main()
        success = True
    finally:
        (BUILDS / "verification.json").write_text(json.dumps({
            "utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "mode": MODE,
            "source_revision": SOURCE_REVISION, "source_dirty": SOURCE_DIRTY,
            "automated_checks_passed": success,
            "scope": "Development alpha automation; not release acceptance, native Windows certification, human playthrough or playtime measurement",
            "checks": CHECKS}, indent=2) + "\n")
