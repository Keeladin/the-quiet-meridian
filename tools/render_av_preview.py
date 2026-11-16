#!/usr/bin/env python3
"""Capture the real Godot UI/mixer; transcode locally with the score venv.

Run: work/av-env/bin/python tools/render_av_preview.py
This does not call a generation service, use player saves, or install packages.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "builds/previews"
WORK = ROOT / "work/av-preview"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    for name, subdir in {
        "XDG_CONFIG_HOME": "work/av-preview-config",
        "XDG_CACHE_HOME": "work/av-preview-cache",
        "XDG_DATA_HOME": "work/av-preview-data",
    }.items():
        folder = ROOT / subdir
        folder.mkdir(parents=True, exist_ok=True)
        env[name] = str(folder)
    avi = WORK / "native-capture.avi"
    video = OUT / "quiet-meridian-av-preview.mp4"
    engine = env.get("GODOT_BIN", "/home/jaco/.local/bin/godot4")
    capture = [engine, "--path", str(ROOT), "--resolution", "1280x800",
               "--windowed", "--disable-vsync", "--fixed-fps", "12",
               "--write-movie", str(avi), "--script", "res://tools/capture_av_preview.gd"]
    result = subprocess.run(capture, cwd=ROOT, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            timeout=300)
    (OUT / "native-capture.log").write_text(result.stdout)
    if result.returncode or "AV_PREVIEW_CAPTURE_OK" not in result.stdout or "SCRIPT ERROR" in result.stdout:
        print(result.stdout)
        raise RuntimeError("Native preview capture did not complete cleanly")
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    encode = [ffmpeg, "-y", "-i", str(avi), "-c:v", "libx264", "-preset", "medium",
              "-crf", "19", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
              "-movflags", "+faststart", str(video)]
    encoded = subprocess.run(encode, cwd=ROOT, capture_output=True, text=True, timeout=180)
    (OUT / "encode.log").write_text(encoded.stderr)
    encoded.check_returncode()
    measure = [ffmpeg, "-i", str(video), "-af", "volumedetect", "-f", "null", "-"]
    measured = subprocess.run(measure, cwd=ROOT, capture_output=True, text=True, timeout=90)
    (OUT / "media-validation.log").write_text(measured.stderr)
    measured.check_returncode()
    if "mean_volume: -inf" in measured.stderr:
        raise RuntimeError("Native movie audio is silent")
    if "1280x800" not in measured.stderr or "12 fps" not in measured.stderr or "stereo" not in measured.stderr:
        raise RuntimeError("Unexpected encoded preview dimensions, frame rate, or sound format")
    report_path = OUT / "capture-manifest.json"
    report = json.loads(report_path.read_text())
    stages = {stage["id"]: stage for stage in report["stages"]}
    if not {0, 1, 6}.issubset(stages["nadi_gesture"]["character_frames"]):
        raise RuntimeError("Preview did not show neutral, blink and explain poses")
    still = stages["reduced_motion"]
    if still["environment_start"]["time"] != still["environment_end"]["time"]:
        raise RuntimeError("Reduced-motion capture changed visual time")
    report.update({"commands": {"capture": capture, "encode": encode, "measure": measure},
                   "mp4_sha256": hashlib.sha256(video.read_bytes()).hexdigest(),
                   "mp4_bytes": video.stat().st_size,
                   "measurement": {
                       "mean_dbfs": float(re.search(r"mean_volume: ([-.\d]+) dB", measured.stderr)[1]),
                       "peak_dbfs": float(re.search(r"max_volume: ([-.\d]+) dB", measured.stderr)[1]),
                       "duration_seconds": 40.25,
                       "audio_sample_rate": 48000,
                       "quality_claim": "Non-silence/headroom and format checks only; not human listening approval or LUFS measurement"},
                   "source_sha256": {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in [
                       "tools/capture_av_preview.gd", "tools/render_av_preview.py", "scripts/main.gd",
                       "scripts/audio_director.gd", "scripts/character_stage.gd", "scripts/environment_stage.gd",
                       "content/audio-score.json"]},
                   "note": "Native captured audio retained without normalization or replacement; levels are the in-game mixer settings documented in the capture source."})
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    print(f"AV_PREVIEW_RENDER_OK: {video.relative_to(ROOT)} ({video.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
