#!/usr/bin/env python3
"""Transcribe saved audition audio locally, without giving ASR the script.

Development-only dependencies/model stay under work/. No network, API key,
Atlas process, paid transcription endpoint or model is needed by the game.
Exit 0: transcription matches, still pending listening. Exit 2: mismatch/hold.
Exit 1: tool or capture error. No exit status accepts dialogue into the game.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import sys

from voice_fidelity import compare_text

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "work/voice-asr-model"


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def inside(path: Path, parent: Path, description: str) -> Path:
    resolved = path.resolve()
    if not resolved.is_relative_to(parent.resolve()):
        raise ValueError(f"{description} must stay inside {parent.relative_to(ROOT)}")
    return resolved


def verify_model() -> dict:
    model = inside(MODEL, ROOT / "work", "Model directory")
    manifest_path = model / "download-manifest.json"
    if not manifest_path.is_file():
        raise ValueError("Local ASR model is not provisioned; see docs/VOICE_ASR_PROVENANCE.md")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    for entry in manifest["files"]:
        path = inside(model / entry["name"], model, "Model file")
        if not path.is_file() or digest(path) != entry["sha256"]:
            raise ValueError(f"Local ASR model hash mismatch: {entry['name']}")
    for required in ["model.bin", "config.json", "tokenizer.json", "vocabulary.txt"]:
        if not (model / required).is_file():
            raise ValueError(f"Missing offline ASR resource: {required}")
    return manifest


def transcribe_saved_audio(audio: Path, cpu_threads: int) -> dict:
    """This function deliberately accepts no script, names, prompt or hotwords."""
    # Set before importing hub/model modules; local_files_only further prevents
    # a missing tokenizer/model from causing an implicit online download.
    os.environ["HF_HUB_OFFLINE"] = "1"
    os.environ["TRANSFORMERS_OFFLINE"] = "1"
    os.environ["HF_HUB_DISABLE_TELEMETRY"] = "1"
    os.environ["HF_HUB_DISABLE_IMPLICIT_TOKEN"] = "1"
    os.environ["HF_HOME"] = str(MODEL / ".hf-home")
    os.environ["HF_HUB_CACHE"] = str(MODEL / ".hf-cache")
    from faster_whisper import WhisperModel

    model = WhisperModel(str(MODEL), device="cpu", compute_type="int8",
                         cpu_threads=cpu_threads, num_workers=1, local_files_only=True)
    stream, info = model.transcribe(
        str(audio), language="en", task="transcribe", beam_size=5,
        temperature=0.0, condition_on_previous_text=False,
        initial_prompt=None, prefix=None, hotwords=None,
        vad_filter=False, word_timestamps=True,
    )
    segments = []
    for segment in stream:
        segments.append({
            "start": segment.start, "end": segment.end, "text": segment.text,
            "avg_logprob": segment.avg_logprob,
            "no_speech_probability": segment.no_speech_prob,
            "compression_ratio": segment.compression_ratio,
            "words": [{"start": word.start, "end": word.end, "word": word.word,
                       "probability": word.probability} for word in (segment.words or [])],
        })
    return {
        "text": " ".join(segment["text"].strip() for segment in segments).strip(),
        "segments": segments,
        "language": info.language,
        "language_probability": info.language_probability,
        "decoded_duration_seconds": info.duration,
        "settings": {
            "device": "cpu", "compute_type": "int8", "cpu_threads": cpu_threads,
            "beam_size": 5, "temperature": 0.0, "condition_on_previous_text": False,
            "initial_prompt": None, "prefix": None, "hotwords": None,
            "vad_filter": False, "word_timestamps": True,
            "local_files_only": True, "offline_environment": True,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audio", required=True, type=Path, help="Saved candidate file inside this repository")
    parser.add_argument("--script-id", required=True, help="Source ID, used only for comparison after ASR")
    parser.add_argument("--output", type=Path, help="JSON report path under work/; default uses audio hash")
    parser.add_argument("--cpu-threads", type=int, default=4)
    parser.add_argument("--overwrite", action="store_true", help="Replace this report only; never changes audio")
    args = parser.parse_args()
    if not 1 <= args.cpu_threads <= 32:
        raise ValueError("Choose 1–32 CPU threads")
    audio = inside(args.audio, ROOT, "Candidate audio")
    if not audio.is_file() or audio.suffix.lower() not in {".wav", ".ogg", ".mp3", ".flac"}:
        raise ValueError("Candidate must be an existing local WAV/Ogg/MP3/FLAC file")
    source = json.loads((ROOT / "content/voice-script.json").read_text(encoding="utf-8"))
    if args.script_id not in source["lines"]:
        raise ValueError("Unknown source script ID")
    audio_hash = digest(audio)
    destination = args.output or (ROOT / "work/voice-asr-reports" / f"{audio.stem}-{audio_hash[:12]}.json")
    destination = inside(destination, ROOT / "work", "ASR report")
    if destination.exists() and not args.overwrite:
        raise ValueError("Report exists; choose another path or explicitly use --overwrite")
    if destination == audio:
        raise ValueError("Report must not replace candidate audio")
    model_manifest = verify_model()
    # The expected words have not been passed to this acoustic function.
    transcription = transcribe_saved_audio(audio, args.cpu_threads)
    if digest(audio) != audio_hash:
        raise ValueError("Candidate audio changed during transcription; result is discarded")
    expected = source["lines"][args.script_id]["text"]
    comparison = compare_text(expected, transcription["text"])
    report = {
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "script_id": args.script_id,
        "source_text_sha256": hashlib.sha256(expected.encode("utf-8")).hexdigest(),
        "audio": str(audio.relative_to(ROOT)), "audio_sha256": audio_hash,
        "model": {"repository": model_manifest["repository"], "revision": model_manifest["revision"],
                  "license": model_manifest["license"], "files": model_manifest["files"]},
        "packages": {name: importlib.metadata.version(name) for name in
                     ["faster-whisper", "ctranslate2", "av", "tokenizers", "huggingface-hub", "onnxruntime"]},
        "transcription": transcription,
        "comparison": comparison,
        "status": "pending_listening" if comparison["passed"] else "asr_mismatch_hold",
        "accepted_for_game": False,
        "human_listening_required": True,
        "paid_api_calls": 0,
        "limitations": [
            "A separate ASR pass is evidence, not a guarantee that every spoken word is correct.",
            "Fictional names and punctuation/numbers can be misrecognized. No names, source text or phonetic hints were supplied to ASR; no mismatch is automatically corrected.",
            "Segment/word timestamps describe ASR recognition and are not approved subtitle timing or forced alignment of the source script.",
            "Listen to the complete recording against the script, including its opening and fully released final word; record mismatch resolutions explicitly.",
            "User audition approval remains required before full-batch voice production.",
        ],
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    temporary.write_text(json.dumps(report, indent=2, ensure_ascii=False, allow_nan=False) + "\n", encoding="utf-8")
    temporary.replace(destination)
    print(json.dumps({"report": str(destination.relative_to(ROOT)), "status": report["status"],
                      "independent_transcript": transcription["text"], "reasons": comparison["reasons"],
                      "accepted_for_game": False}, indent=2, ensure_ascii=False))
    return 0 if comparison["passed"] else 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, ImportError, KeyError) as error:
        print(f"VOICE_ASR_ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
