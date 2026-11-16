"""Local checks for development voice candidates; no network or model calls.

A matching returned transcript is not proof that its audio contains those
words. These helpers cannot promote a recording to reviewed game dialogue.
Independent acoustic review and the user's audition approval remain necessary.
"""
from __future__ import annotations

from array import array
from difflib import SequenceMatcher
import math
import sys
import unicodedata


_APOSTROPHES = str.maketrans({
    "\u2018": "'", "\u2019": "'", "\u02bc": "'", "\uff07": "'",
})


def _word_tokens(text: str) -> list[str]:
    """Preserve lexical content; ignore only case and punctuation formatting.

    Internal apostrophes remain part of words. Diacritics are retained. Neither
    homophones nor numbers nor contractions are expanded or rewritten. Hyphens
    and dashes delimit words, as does ordinary whitespace.
    """
    if not isinstance(text, str):
        raise TypeError("Voice transcript must be a string")
    normalized = unicodedata.normalize("NFKC", text).translate(_APOSTROPHES).casefold()
    result: list[str] = []
    current: list[str] = []
    for index, character in enumerate(normalized):
        category = unicodedata.category(character)[0]
        if category in {"L", "N"} or (category == "M" and current):
            current.append(character)
        elif (character == "'" and current and index + 1 < len(normalized)
              and unicodedata.category(normalized[index + 1])[0] in {"L", "N"}):
            current.append(character)
        else:
            if current:
                result.append("".join(current))
                current = []
    if current:
        result.append("".join(current))
    return result


def compare_text(expected: str, observed: str) -> dict:
    """Compare source text to a transcript without accepting paraphrases.

    ``passed`` means only that normalized lexical sequences are identical and
    nonempty. ``opcodes`` exposes every aligned range, including equal ranges;
    missing/extra contain pure deletions/insertions, while replacements are
    recorded as substitution blocks. No result establishes acoustic fidelity.
    """
    expected_tokens = _word_tokens(expected)
    observed_tokens = _word_tokens(observed)
    reasons: list[str] = []
    if not expected_tokens:
        reasons.append("The expected script contains no spoken words.")
    if not observed_tokens:
        reasons.append("The returned transcript contains no spoken words.")
    opcodes: list[dict] = []
    missing: list[str] = []
    extra: list[str] = []
    substitutions: list[dict] = []
    for operation, start, end, actual_start, actual_end in SequenceMatcher(
            a=expected_tokens, b=observed_tokens, autojunk=False).get_opcodes():
        wanted = expected_tokens[start:end]
        actual = observed_tokens[actual_start:actual_end]
        opcodes.append({
            "operation": operation,
            "expected_start": start, "expected_end": end,
            "observed_start": actual_start, "observed_end": actual_end,
            "expected": wanted, "observed": actual,
        })
        if operation == "delete":
            missing.extend(wanted)
            reasons.append(f"Missing source words at expected tokens {start}:{end}.")
        elif operation == "insert":
            extra.extend(actual)
            reasons.append(f"Extra spoken words at observed tokens {actual_start}:{actual_end}.")
        elif operation == "replace":
            substitutions.append({"expected": wanted, "observed": actual,
                                  "expected_start": start, "observed_start": actual_start})
            reasons.append(f"Changed source words at expected tokens {start}:{end}.")
    passed = bool(expected_tokens) and expected_tokens == observed_tokens
    return {
        "passed": passed,
        "status": "pending_listening" if passed else "rejected_transcript",
        "scope": "transcript_comparison_only",
        "audio_fidelity_verified": False,
        "expected_tokens": expected_tokens,
        "observed_tokens": observed_tokens,
        "opcodes": opcodes,
        "missing": missing,
        "extra": extra,
        "substitutions": substitutions,
        "reasons": reasons,
        "normalization": "Unicode NFKC, case folding, typographic apostrophes and punctuation boundaries only; no lexical, numeric or contraction rewrites",
    }


def _dbfs(amplitude: float) -> float | None:
    # None is JSON-safe silence; negative infinity is not valid strict JSON.
    return 20.0 * math.log10(amplitude) if amplitude > 0 else None


def analyze_pcm(pcm: bytes, rate: int = 24000, *, expected_text: str | None = None) -> dict:
    """Inspect bytes assumed to be signed 16-bit little-endian mono PCM.

    The caller must obtain rate/channel/encoding metadata from capture. Raw PCM
    cannot reveal whether those supplied assumptions are correct. ``passed``
    checks frame integrity, non-silence, a stuck signal and material clipping;
    timing/tail checks merely warn. A tone can pass these checks without being
    speech, so every passing result remains pending listening.
    """
    if not isinstance(pcm, (bytes, bytearray, memoryview)):
        raise TypeError("PCM must be a bytes-like object")
    if type(rate) is not int or rate <= 0 or rate > 384000:
        raise ValueError("Sample rate must be a positive integer no greater than 384000")
    if expected_text is not None and not isinstance(expected_text, str):
        raise TypeError("expected_text must be a string or None")
    raw = bytes(pcm)
    partial_bytes = len(raw) % 2
    reasons: list[str] = []
    warnings: list[str] = []
    if partial_bytes:
        reasons.append("PCM ends with an incomplete 16-bit sample; capture is rejected.")
    samples = array("h")
    samples.frombytes(raw[:len(raw) - partial_bytes])
    if sys.byteorder != "little":
        samples.byteswap()
    count = len(samples)
    duration = count / rate
    # -60 dBFS is a signal-detection threshold, not a speech recognizer.
    silence_threshold = 32
    clipping_threshold = 32760
    peak_value = 0
    total = 0
    squares = 0
    silent_count = 0
    clipped_count = 0
    clipped_run = 0
    longest_clipped_run = 0
    first_active = None
    last_active = None
    minimum = 32767
    maximum = -32768
    for index, sample in enumerate(samples):
        magnitude = abs(sample)
        peak_value = max(peak_value, magnitude)
        minimum = min(minimum, sample)
        maximum = max(maximum, sample)
        total += sample
        squares += sample * sample
        if magnitude <= silence_threshold:
            silent_count += 1
        else:
            if first_active is None:
                first_active = index
            last_active = index
        if magnitude >= clipping_threshold:
            clipped_count += 1
            clipped_run += 1
            longest_clipped_run = max(longest_clipped_run, clipped_run)
        else:
            clipped_run = 0
    if not count:
        reasons.append("No complete PCM samples were captured.")
    elif first_active is None:
        reasons.append("Captured audio is silent at the -60 dBFS detection threshold.")
    elif minimum == maximum:
        reasons.append("Captured audio is a constant nonzero signal, not usable speech.")
    clipped_fraction = clipped_count / count if count else 0.0
    if count and (clipped_fraction >= 0.001 or longest_clipped_run >= 6):
        reasons.append("Material near-full-scale clipping detected; retain the master and reject the take.")
    peak = peak_value / 32768.0
    rms = math.sqrt(squares / count) / 32768.0 if count else 0.0
    mean = total / count / 32768.0 if count else 0.0
    leading = first_active / rate if first_active is not None else duration
    trailing = (count - 1 - last_active) / rate if last_active is not None else duration
    active_span = ((last_active - first_active + 1) / rate
                   if first_active is not None and last_active is not None else 0.0)
    if first_active is not None and trailing < 0.08:
        warnings.append("Less than 80 ms below the signal threshold follows the final activity; listen for a cut-off final word.")
    if rms and abs(mean) > 0.01 and abs(mean) / rms > 0.5:
        warnings.append("Large DC offset may indicate an encoding/capture problem.")
    words = len(_word_tokens(expected_text)) if expected_text is not None else None
    inferred_wpm = words * 60.0 / active_span if words and active_span > 0 else None
    if inferred_wpm is not None and (inferred_wpm > 350 or inferred_wpm < 60):
        warnings.append("Source length versus active signal span is unusual; review pacing and completeness, without inferring a transcript from duration.")
    passed = not reasons
    return {
        "passed": passed,
        "status": "pending_listening" if passed else "rejected_signal",
        "scope": "pcm_signal_integrity_only",
        "audio_fidelity_verified": False,
        "reasons": reasons,
        "warnings": warnings,
        "sample_rate": rate,
        "assumed_format": "s16le_mono",
        "channels": 1,
        "byte_count": len(raw),
        "sample_count": count,
        "incomplete_sample_bytes": partial_bytes,
        "duration_seconds": duration,
        "peak": peak,
        "peak_dbfs": _dbfs(peak),
        "rms": rms,
        "rms_dbfs": _dbfs(rms),
        "dc_offset": mean,
        "silence_fraction": silent_count / count if count else 1.0,
        "leading_silence_seconds": leading,
        "tail_silence_seconds": trailing,
        "active_span_seconds": active_span,
        "clipped_fraction": clipped_fraction,
        "longest_clipped_run_samples": longest_clipped_run,
        "expected_word_count": words,
        "source_words_per_active_minute": inferred_wpm,
        "criteria": {
            "silence_threshold_integer": silence_threshold,
            "clipping_threshold_integer": clipping_threshold,
            "reject_clipped_fraction_at_least": 0.001,
            "reject_clipped_run_samples_at_least": 6,
            "short_tail_warning_seconds": 0.08,
            "duration_warning_wpm_outside": [60, 350],
            "limits": "Signal activity is not speech recognition. Provider completion, exact transcript and independent acoustic/listening review remain separate requirements.",
        },
    }
