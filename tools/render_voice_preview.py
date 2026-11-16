#!/usr/bin/env python3
"""Capture a native local audition preview. No API, promotion, or installation.

Run with work/av-env/bin/python tools/render_voice_preview.py.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import wave

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "builds/previews/voice-audition"
WORK = ROOT / "work/voice-preview"
AUDITION = ROOT / "assets/audio/auditions/2026-11-14/mara_refuge_r0-56e17e6bda42440c93a80b5508e108e5"


def audition_subtitles(script):
    """One audition-only mapping; it does not align or approve production clips."""
    line = script["lines"]["mara_refuge_r0"]
    review_path = AUDITION / "review/mara-bounded.json"
    review = json.loads(review_path.read_text())
    assert review["source_text_sha256"] == line["text_sha256"]
    assert review["comparison"]["passed"] and review["accepted_for_game"] is False
    bounded = AUDITION / "review/mara-audio-bounded.wav"
    assert hashlib.sha256(bounded.read_bytes()).hexdigest() == review["audio_sha256"]
    with wave.open(str(bounded)) as cut, wave.open(str(AUDITION / "candidate.wav")) as full:
        assert cut.getparams()[:3] == full.getparams()[:3]
        length = cut.getnframes()
        assert cut.readframes(length) == full.readframes(length), "ASR timings require an exact unshifted source prefix"
    words = [word for segment in review["transcription"]["segments"] for word in segment["words"]]
    sentences = re.findall(r"[^.!?]+[.!?](?:\s+|$)", line["text"])
    assert " ".join(sentence.strip() for sentence in sentences) == line["text"]
    cues = []
    offset = 0
    for sentence in sentences:
        sentence = sentence.strip()
        tokens = re.findall(r"\w+", sentence.casefold())
        spoken = words[offset:offset + len(tokens)]
        assert [re.sub(r"[^\w]", "", word["word"].casefold()) for word in spoken] == tokens
        cues.append({"start": spoken[0]["start"], "end": spoken[-1]["end"], "text": sentence})
        offset += len(tokens)
    assert offset == len(words) == 59 and len(cues) == 6
    result = {"cues": cues, "status": "Approximate independent-ASR sentence timing, unreviewed and audition-only",
              "approved": False, "production_manifest_modified": False,
              "source_review": str(review_path.relative_to(ROOT)),
              "review_sha256": hashlib.sha256(review_path.read_bytes()).hexdigest(),
              "alignment": "Canonical sentence words exactly match 59 ASR tokens; ASR input verified as the unshifted prefix of the original take. First/last word estimates retained without claiming perceptual alignment."}
    (WORK / "audition-subtitles.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    for key, name in (("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache"), ("XDG_DATA_HOME", "data")):
        directory = WORK / name
        directory.mkdir(exist_ok=True)
        env[key] = str(directory)
    manifest_path = ROOT / "content/voice-script.json"
    original_manifest = manifest_path.read_bytes()
    subtitles = audition_subtitles(json.loads(original_manifest))
    avi = WORK / "native-audition.avi"
    video = OUT / "mara-unapproved-audition.mp4"
    command = [env.get("GODOT_BIN", "/home/jaco/.local/bin/godot4"), "--path", str(ROOT),
               "--resolution", "1280x800", "--windowed", "--disable-vsync", "--fixed-fps", "24",
               "--write-movie", str(avi), "--script", "res://tools/capture_voice_preview.gd"]
    capture = subprocess.run(command, cwd=ROOT, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             text=True, timeout=300)
    (OUT / "native-capture.log").write_text(capture.stdout)
    if capture.returncode or "VOICE_PREVIEW_CAPTURE_OK" not in capture.stdout or "SCRIPT ERROR" in capture.stdout:
        raise RuntimeError(capture.stdout)
    assert manifest_path.read_bytes() == original_manifest, "Production voice manifest changed"
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    encoding = [ffmpeg, "-y", "-i", str(avi), "-c:v", "libx264", "-preset", "medium", "-crf", "19",
                "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(video)]
    result = subprocess.run(encoding, cwd=ROOT, capture_output=True, text=True, timeout=180)
    (OUT / "encode.log").write_text(result.stderr)
    result.check_returncode()
    measurement = subprocess.run([ffmpeg, "-i", str(video), "-af", "volumedetect", "-f", "null", "-"],
                                 capture_output=True, text=True, timeout=90)
    (OUT / "measurement.log").write_text(measurement.stderr)
    measurement.check_returncode()
    report_path = OUT / "capture-manifest.json"
    report = json.loads(report_path.read_text())
    samples = report["samples"]
    words = [s for s in samples if s["section"] == "full-take" and 1.1 < s["voice_position"] < 23]
    tail = [s for s in samples if s["section"] == "full-take" and 25 < s["voice_position"] < 30]
    intro = [s for s in samples if s["section"] == "ready"]
    reduced = [s for s in samples if s["section"] == "reduced-motion"]
    assert any(s["active"] and s["pose"]["speaking"] for s in words), "Speech did not drive the portrait"
    assert len(tail) > 24 and all(not s["active"] and not s["pose"]["speaking"] for s in tail), "Silent tail moved the mouth"
    assert all(not s["pose"]["speaking"] for s in intro), "Music-only intro moved the mouth"
    assert all(s["pose"]["reduced_motion"] for s in reduced), "Reduced-motion stage was not enabled"
    assert len({s["pose"]["time"] for s in reduced}) == 1 and len({s["pose"]["frame"] for s in reduced}) == 1, "Reduced-motion portrait moved"
    assert min(s["duck"] for s in words) <= .26 and all(s["duck"] <= .26 for s in tail), "Dialogue ducking pumped during silence"
    shown_captions = {sample["subtitle"] for sample in samples if sample["section"] == "full-take" and sample["subtitle"]}
    assert shown_captions == {cue["text"] for cue in subtitles["cues"]}, "Preview did not display all six exact sentence captions"
    mean = float(re.search(r"mean_volume: ([-.\d]+) dB", measurement.stderr)[1])
    peak = float(re.search(r"max_volume: ([-.\d]+) dB", measurement.stderr)[1])
    assert -65 < mean < -5 and peak < 0, "Preview audio is silent or clips"
    source = ROOT / report["source"].removeprefix("res://")
    report.update({"source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                   "production_manifest_unchanged_sha256": hashlib.sha256(original_manifest).hexdigest(),
                   "mp4_sha256": hashlib.sha256(video.read_bytes()).hexdigest(), "mp4_bytes": video.stat().st_size,
                   "signal_measurement": {"mean_dbfs": mean, "peak_dbfs": peak, "quality_claim": "Format/signal evidence only, not listening approval"},
                   "activity_validation": {"speech_samples": len(words), "silent_tail_samples": len(tail),
                                           "reduced_motion_samples": len(reduced), "passed": True},
                   "subtitles": subtitles,
                   "implementation_sha256": {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in
                       ("scripts/main.gd", "scripts/audio_director.gd", "scripts/character_stage.gd",
                        "tools/capture_voice_preview.gd", "tools/render_voice_preview.py")},
                   "commands": {"capture": command, "encode": encoding}})
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    print("VOICE_PREVIEW_RENDER_OK:", video.relative_to(ROOT), "UNAPPROVED AUDITION; native mixer audio retained")


if __name__ == "__main__":
    main()
