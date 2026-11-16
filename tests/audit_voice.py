#!/usr/bin/env python3
"""Audit exact story coverage and offline voice availability, without generation.

Pending lines are legitimate production work, not completed voice acting. A
passing audit reports those counts explicitly. No credentials or provider calls
are needed to validate a source package.
"""
from collections import Counter
from pathlib import Path, PurePosixPath
import hashlib
import json
import math
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def no_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load(relative):
    return json.loads((ROOT / relative).read_text(encoding="utf-8"),
                      object_pairs_hook=no_duplicate_keys)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def audit(game, dialogue, script):
    failures = []
    checks = 0

    def check(condition, message):
        nonlocal checks
        checks += 1
        if not condition:
            failures.append(message)

    expected = {}

    def expect(identifier, speaker, text, context):
        check(identifier not in expected, f"unique story identity: {identifier}")
        expected[identifier] = (speaker, text, context)

    expect("narration_opening", "iona", game["intro"], "Opening letter and arrival")
    expect("narration_ending", "iona", game["ending"], "Final narrative conclusion")
    for chapter in game["chapters"]:
        expect(chapter["id"] + "_intro", "iona", chapter["intro"], "Chapter opening")
        expect(chapter["id"] + "_closing", "iona", chapter["closing"], "Chapter conclusion")
    for conversation in dialogue["conversations"]:
        cid = conversation["id"]
        expect(cid + "_greeting", "iona", conversation["greeting"], "Conversation scene description")
        for index, topic in enumerate(conversation["topics"]):
            expect(f"{cid}_q{index}", "iona", topic["question"], "Player question")
            expect(f"{cid}_r{index}", conversation["character"], topic["reply"], "Character reply")

    lines = script["lines"]
    casting = script["casting"]
    characters = {character["id"] for character in game["characters"]}
    check(script["version"] == 1, "supported voice manifest version")
    check(set(lines) == set(expected), "voice IDs exactly cover the current narrative and conversations")
    expected_counts = Counter(value[2] for value in expected.values())
    check(expected_counts == {"Opening letter and arrival": 1, "Final narrative conclusion": 1,
                             "Chapter opening": 6, "Chapter conclusion": 6,
                             "Conversation scene description": 12, "Player question": 36,
                             "Character reply": 36}, "14 narrations, 12 greetings and 72 question/reply lines")
    check(len(lines) == 98, "98 current voice clips, with no accidental omissions or extras")
    check(set(casting) <= characters, "casting refers only to story characters")
    used_speakers = {value[0] for value in expected.values()}
    check(used_speakers <= set(casting), "every active speaker has casting")
    check(len(used_speakers) == 7, "seven active story voices")
    check(len({casting[speaker]["voice"] for speaker in used_speakers}) == 7,
          "all seven active speakers use distinct preset voices")
    available = 0
    pending = 0
    timed = 0
    total_words = 0
    seen_paths = set()
    for identifier, (speaker, text, context) in expected.items():
        if identifier not in lines:
            continue
        line = lines[identifier]
        check(line.get("speaker") == speaker, f"correct story speaker: {identifier}")
        check(line.get("text") == text, f"exact story text: {identifier}")
        check(isinstance(text, str) and bool(text.strip()), f"nonempty story text: {identifier}")
        check(line.get("context") == context, f"correct line purpose: {identifier}")
        check(line.get("text_sha256") == digest(text.encode("utf-8")), f"text integrity: {identifier}")
        check(line.get("voice") == casting[speaker]["voice"], f"consistent casting: {identifier}")
        check(line.get("direction") == casting[speaker]["direction"] and bool(line.get("direction", "").strip()),
              f"expressive direction supplied: {identifier}")
        check(line.get("spoken_text") == text, f"spoken script contains exact words, no direction tags: {identifier}")
        total_words += len(text.split())
        path = line.get("path")
        duration = line.get("duration")
        subtitles = line.get("subtitles")
        check(isinstance(path, str), f"explicit local path or pending empty path: {identifier}")
        check(isinstance(duration, (float, int)) and not isinstance(duration, bool)
              and math.isfinite(duration) and duration >= 0, f"finite nonnegative duration: {identifier}")
        check(isinstance(subtitles, list), f"subtitle cue array: {identifier}")
        if path == "":
            pending += 1
            check(duration == 0 and subtitles == [], f"pending clip does not invent timing: {identifier}")
            check(line.get("status") in {"awaiting_generation_approval", "awaiting_generation", "generation_failed"},
                  f"unavailable clip clearly remains pending: {identifier}")
            continue
        if not isinstance(path, str):
            continue
        relative = path.removeprefix("res://")
        parts = PurePosixPath(relative).parts
        candidate = ROOT / relative
        safe = (path.startswith("res://assets/audio/voice/") and ".." not in parts
                and "\\" not in path and candidate.suffix.lower() in {".wav", ".ogg", ".mp3"}
                and candidate.resolve().is_relative_to((ROOT / "assets/audio/voice").resolve()))
        check(safe, f"offline voice path confined to the repository: {identifier}")
        check(path not in seen_paths, f"no accidental duplicate recording assignment: {identifier}")
        seen_paths.add(path)
        if not safe:
            continue
        check(candidate.is_file(), f"local recording exists: {identifier}")
        if not candidate.is_file():
            continue
        data = candidate.read_bytes()
        check(len(data) > 128, f"nonempty recording container: {identifier}")
        valid_header = ((candidate.suffix.lower() == ".wav" and data[:4] == b"RIFF" and data[8:12] == b"WAVE")
                        or (candidate.suffix.lower() == ".ogg" and data[:4] == b"OggS")
                        or (candidate.suffix.lower() == ".mp3" and (data[:3] == b"ID3" or data[:1] == b"\xff")))
        check(valid_header, f"audio file has expected container signature: {identifier}")
        check(line.get("audio_sha256") == digest(data), f"recorded audio integrity: {identifier}")
        check(isinstance(duration, (float, int)) and duration > 0, f"produced clip has measured duration: {identifier}")
        check(line.get("status") in {"produced", "reviewed"}, f"produced recording has honest review status: {identifier}")
        provenance = line.get("provenance", {})
        check(isinstance(provenance, dict) and all(isinstance(provenance.get(key), str) and provenance[key].strip()
              for key in ("provider", "model", "request_id", "generated_utc", "terms_record", "commercial_use_basis")),
              f"recording has production and commercial-use provenance: {identifier}")
        if isinstance(subtitles, list):
            previous_end = 0.0
            for cue in subtitles:
                valid = (isinstance(cue, dict) and isinstance(cue.get("start"), (int, float))
                         and isinstance(cue.get("end"), (int, float))
                         and math.isfinite(cue["start"]) and math.isfinite(cue["end"])
                         and previous_end <= cue["start"] < cue["end"] <= duration + 0.05
                         and isinstance(cue.get("text"), str) and bool(cue["text"].strip()))
                check(valid, f"ordered in-range subtitle timing: {identifier}")
                if valid:
                    previous_end = cue["end"]
            if subtitles:
                timed += 1
                caption_text = " ".join(cue.get("text", "") for cue in subtitles if isinstance(cue, dict))
                check(re.sub(r"\s+", " ", caption_text).strip() == re.sub(r"\s+", " ", text).strip(),
                      f"timed subtitles retain the exact story words: {identifier}")
        available += 1
    check(script.get("provider") == "OpenAI API" and script.get("model") == "gpt-live-1",
          "requested OpenAI provider/model; obsolete credit workflow excluded")
    return failures, checks, {"clips": len(lines), "available": available, "pending": pending,
                              "timed": timed, "words": total_words}


def main():
    try:
        failures, checks, counts = audit(load("content/game.json"), load("content/dialogues.json"),
                                         load("content/voice-script.json"))
    except (KeyError, TypeError, ValueError, OSError) as error:
        print("VOICE AUDIT FAIL: malformed or unreadable source:", error)
        return 1
    if failures:
        for failure in failures:
            print("VOICE AUDIT FAIL:", failure)
        return 1
    print(f"VOICE_AUDIT_OK: {checks} checks; {counts['clips']} exact story lines; "
          f"{counts['available']} local recordings, {counts['pending']} pending; "
          f"{counts['timed']} timed subtitle tracks; "
          f"{counts['words']} source words; "
          "script/runtime readiness does not establish voice performance quality")
    return 0


if __name__ == "__main__":
    sys.exit(main())
