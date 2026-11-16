#!/usr/bin/env python3
"""Create the project's original ambient beds and interaction cues.

Only Python's standard library is used. No samples, external recordings,
model calls or network resources are involved. Seeds make outputs repeatable.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import random
import struct
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/audio"
RATE = 22050
SECONDS = 24
TAU = 2 * math.pi


def write_wave(name: str, values: list[float]) -> dict:
    # A fixed gain preserves the designed relative level between all cues.
    clipped = sum(abs(value) > 0.98 for value in values)
    if clipped:
        raise ValueError(f"{name}: {clipped} clipped samples")
    samples = [int(max(-0.98, min(0.98, value)) * 32767) for value in values]
    path = DEST / name
    with wave.open(str(path), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(struct.pack("<" + "h" * len(samples), *samples))
    return {"path": "assets/audio/" + name, "sample_rate": RATE, "channels": 1,
            "bits_per_sample": 16, "duration_seconds": len(values) / RATE,
            "peak": round(max(abs(v) for v in values), 6),
            "rms": round(math.sqrt(sum(v * v for v in values) / len(values)), 6),
            "loop_seam_delta": round(abs(values[-1] - values[0]), 6),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def ambient(index: int, pitches: tuple[float, ...]) -> list[float]:
    count = RATE * SECONDS
    rng = random.Random(73190 + index * 911)
    noise = [rng.uniform(-1, 1) for _ in range(count)]
    low, body = 0.0, 0.0
    # Warm the circular filter with the tail. The state then agrees across
    # the loop boundary to much better than 16-bit quantization precision.
    for value in noise[-RATE:]:
        low += 0.018 * (value - low)
        body += 0.17 * (value - body)
    result = []
    cycles = [round(pitch * SECONDS) for pitch in pitches]
    phases = [rng.random() * TAU for _ in pitches]
    for i, value in enumerate(noise):
        low += 0.018 * (value - low)
        body += 0.17 * (value - body)
        fraction = i / count
        tide = 0.64 + 0.22 * math.sin(TAU * (2 * fraction) + index * 0.7)
        wash = (low * 0.8 + body * 0.07) * tide
        air = 0.015 * math.sin(TAU * (7 * fraction) + index)
        pad = 0.0
        for voice, cycle in enumerate(cycles):
            sway = 0.055 * math.sin(TAU * (voice + 1) * fraction)
            amplitude = 0.011 / (voice + 1)
            breath = 0.7 + 0.2 * math.sin(TAU * (voice + 2) * fraction + phases[voice])
            pad += amplitude * breath * math.sin(TAU * cycle * fraction + sway + phases[voice])
        # Restrained periodic ripples: each chapter has its own pace and hue.
        ripple_phase = (fraction * (3 + index)) % 1.0
        ripple_envelope = math.sin(math.pi * ripple_phase) ** 2 * math.exp(-ripple_phase * 11)
        ripple = ripple_envelope * math.sin(TAU * round((360 + index * 39) * SECONDS) * fraction)
        value_out = wash * (0.7 if index in (2, 5) else 1.0) + pad + 0.003 * ripple + air * low
        result.append(value_out)
    # All deterministic layers and ripple envelopes meet at the loop seam.
    return result


def paper() -> list[float]:
    rng = random.Random(426)
    count = int(RATE * 0.24)
    low = 0.0
    result = []
    for i in range(count):
        value = rng.uniform(-1, 1)
        low += 0.28 * (value - low)
        phase = i / (count - 1)
        envelope = math.sin(math.pi * phase) ** 2
        flutter = 0.6 + 0.4 * math.sin(TAU * 27 * i / RATE)
        result.append((value - low) * 0.055 * envelope * flutter)
    return result


def discovery() -> list[float]:
    count = int(RATE * 1.45)
    result = []
    for i in range(count):
        time = i / RATE
        value = 0.0
        for frequency, offset, gain in [(523.25, 0, 0.045), (783.99, 0.13, 0.032), (1046.5, 0.26, 0.021)]:
            local = time - offset
            if local >= 0:
                envelope = (1 - math.exp(-local * 80)) * math.exp(-local * 4.8)
                value += gain * envelope * (math.sin(TAU * frequency * local) + 0.12 * math.sin(TAU * frequency * 2.01 * local))
        end_fade = min(1, (count - i - 1) / (RATE * 0.08))
        result.append(value * end_fade)
    return result


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    definitions = [
        ((110.0, 164.81, 220.0), "Harbor rain and the first distant bell; low A/E motif"),
        ((98.0, 146.83, 196.0), "Air through the waterworks, a restrained G/D foundation"),
        ((130.81, 196.0, 261.63), "Observatory air and glassy C/G overtones"),
        ((146.83, 220.0, 293.66), "Reed wind and tidal shallows, warmer D/A motif"),
        ((123.47, 185.0, 246.94), "Civic interior air with unsettled B/F-sharp resonance"),
        ((130.81, 164.81, 196.0), "Dawn water and a resolved C/E/G harmony"),
    ]
    assets = []
    for index, (pitches, description) in enumerate(definitions, 1):
        entry = write_wave(f"ch{index}.wav", ambient(index, pitches))
        entry.update({"purpose": description, "loop": True, "seed": 73190 + index * 911})
        assets.append(entry)
        print(entry["path"])
    for name, values, purpose in [("paper.wav", paper(), "Soft paper interaction"),
                                   ("discovery.wav", discovery(), "Three-note evidence confirmation")]:
        entry = write_wave(name, values)
        entry.update({"purpose": purpose, "loop": False})
        assets.append(entry)
    manifest = {"created": "2026-11-14", "authoring_method": "Original procedural synthesis in Python standard library",
                "generator": "tools/generate_audio.py", "external_samples": [], "external_references": [],
                "rights": "Original project-authored audio; no third-party samples or recording licenses",
                "review_status": "Signal integrity and clipping checked; subjective listening and final in-game balance require review",
                "assets": assets}
    (DEST / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("AUDIO_GENERATION_OK: 6 ambient loops and 2 interaction cues")


def check():
    manifest = json.loads((DEST / "manifest.json").read_text())
    expected = {f"ch{i}.wav" for i in range(1, 7)} | {"paper.wav", "discovery.wav"}
    actual = {Path(entry["path"]).name for entry in manifest["assets"]}
    if actual != expected:
        raise ValueError("Audio manifest does not cover all six chapters and both cues")
    for entry in manifest["assets"]:
        path = ROOT / entry["path"]
        if hashlib.sha256(path.read_bytes()).hexdigest() != entry["sha256"]:
            raise ValueError(f"Audio provenance checksum mismatch: {path}")
        with wave.open(str(path)) as file:
            if (file.getnchannels(), file.getsampwidth(), file.getframerate()) != (1, 2, RATE):
                raise ValueError(f"Unexpected PCM format: {path}")
            if abs(file.getnframes() / RATE - entry["duration_seconds"]) > 1e-9:
                raise ValueError(f"Unexpected duration: {path}")
            samples = struct.unpack("<" + "h" * file.getnframes(), file.readframes(file.getnframes()))
            if not any(samples) or max(abs(sample) for sample in samples) >= 32766:
                raise ValueError(f"Silent or clipped audio: {path}")
    print("AUDIO_AUDIT_OK: all eight PCM assets match provenance, format and duration; no clipped samples")


if __name__ == "__main__":
    check() if "--check" in sys.argv else main()
