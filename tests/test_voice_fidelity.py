#!/usr/bin/env python3
"""Adversarial, entirely offline checks of voice-candidate validation."""
from __future__ import annotations

import importlib.util
import json
import math
from pathlib import Path
import struct
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("voice_fidelity", ROOT / "tools/voice_fidelity.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
compare_text = module.compare_text
analyze_pcm = module.analyze_pcm


def tone(seconds=0.4, amplitude=0.3, tail=0.15, rate=24000):
    samples = [round(32767 * amplitude * math.sin(2 * math.pi * 437 * index / rate))
               for index in range(round(seconds * rate))]
    samples += [0] * round(tail * rate)
    return struct.pack("<" + "h" * len(samples), *samples)


class TranscriptTests(unittest.TestCase):
    def test_exact_text_is_still_pending_listening(self):
        result = compare_text("The record belongs to everyone.", "The record belongs to everyone.")
        self.assertTrue(result["passed"])
        self.assertEqual(result["status"], "pending_listening")
        self.assertFalse(result["audio_fidelity_verified"])
        self.assertEqual(result["reasons"], [])

    def test_typography_case_and_whitespace_are_not_new_words(self):
        result = compare_text("“I don’t know”—Mara said. Café.", "I DON'T KNOW, Mara said! Cafe\u0301.")
        self.assertTrue(result["passed"])
        self.assertEqual(result["expected_tokens"], ["i", "don't", "know", "mara", "said", "café"])
        self.assertTrue(compare_text("Twenty-three names.", "twenty three names")["passed"])
        self.assertTrue(compare_text("Ｍａｒａ", "Mara")["passed"])

    def test_all_user_requested_adversarial_failures(self):
        source = "I did not know that the lower gate was shut."
        candidates = {
            "missing negation": "I did know that the lower gate was shut.",
            "missing object": "I did not know that the gate was shut.",
            "preamble": "Certainly, here is the line. I did not know that the lower gate was shut.",
            "paraphrase": "I was unaware that the lower gate was closed.",
            "truncated": "I did not know that the lower gate",
            "duplicated": "I did not know know that the lower gate was shut.",
            "speaker label": "Rowan: I did not know that the lower gate was shut.",
            "spoken direction": "[sighs] I did not know that the lower gate was shut.",
            "continuation": "I did not know that the lower gate was shut. Shall I continue?",
        }
        for label, candidate in candidates.items():
            with self.subTest(label=label):
                result = compare_text(source, candidate)
                self.assertFalse(result["passed"])
                self.assertEqual(result["status"], "rejected_transcript")
                self.assertTrue(result["reasons"])

    def test_no_contraction_number_homophone_or_diacritic_rewrites(self):
        for source, candidate in [
            ("I don't know", "I do not know"),
            ("I don't know", "I dont know"),
            ("seventeen years", "17 years"),
            ("twenty-three names", "23 names"),
            ("their boat", "there boat"),
            ("Mara read the résumé", "Mara read the resume"),
            ("the lower gate", "the upper gate"),
        ]:
            with self.subTest(source=source, candidate=candidate):
                self.assertFalse(compare_text(source, candidate)["passed"])

    def test_diff_reports_missing_extra_and_substituted_words(self):
        result = compare_text("That was not the truth.", "That was the truth.")
        self.assertEqual(result["missing"], ["not"])
        result = compare_text("Ask me what I saw.", "Please ask me what I saw.")
        self.assertEqual(result["extra"], ["please"])
        result = compare_text("the lower footway", "the upper footway")
        self.assertEqual(result["substitutions"][0]["expected"], ["lower"])
        self.assertEqual(result["substitutions"][0]["observed"], ["upper"])

    def test_empty_or_only_punctuation_never_passes(self):
        for source, candidate in [("", ""), ("...", "!!!"), ("Speak.", ""), ("", "Speak.")]:
            with self.subTest(source=source, candidate=candidate):
                self.assertFalse(compare_text(source, candidate)["passed"])
        with self.assertRaises(TypeError):
            compare_text("Speak.", None)

    def test_selected_full_source_lines_are_not_normalized_away(self):
        script = json.loads((ROOT / "content/voice-script.json").read_text())
        for identifier in ["ch1_closing", "rowan_kitchen_r2", "mara_refuge_r0"]:
            text = script["lines"][identifier]["text"]
            with self.subTest(identifier=identifier):
                self.assertTrue(compare_text(text, text)["passed"])
                self.assertFalse(compare_text(text, "Here is the requested recording. " + text)["passed"])
                self.assertFalse(compare_text(text, text.rsplit(" ", 1)[0])["passed"])


class SignalTests(unittest.TestCase):
    def test_tone_passes_signal_integrity_but_never_claims_speech(self):
        result = analyze_pcm(tone())
        self.assertTrue(result["passed"])
        self.assertEqual(result["status"], "pending_listening")
        self.assertFalse(result["audio_fidelity_verified"])
        self.assertAlmostEqual(result["duration_seconds"], 0.55)
        self.assertGreater(result["tail_silence_seconds"], 0.14)
        self.assertLess(result["peak"], 0.31)
        self.assertGreater(result["peak"], 0.29)
        json.dumps(result, allow_nan=False)

    def test_empty_silent_incomplete_and_stuck_signals_are_rejected(self):
        for label, pcm in [
            ("empty", b""),
            ("silent", bytes(24000)),
            ("partial sample", tone() + b"\xff"),
            ("stuck positive", struct.pack("<h", 1234) * 2400),
        ]:
            with self.subTest(label=label):
                result = analyze_pcm(pcm)
                self.assertFalse(result["passed"])
                self.assertEqual(result["status"], "rejected_signal")
                self.assertTrue(result["reasons"])
                json.dumps(result, allow_nan=False)

    def test_clipped_samples_are_rejected(self):
        samples = [32767, -32768] * 1000 + [0] * 2400
        result = analyze_pcm(struct.pack("<" + "h" * len(samples), *samples))
        self.assertFalse(result["passed"])
        self.assertGreater(result["clipped_fraction"], 0.4)
        self.assertEqual(result["peak"], 1.0)

    def test_short_tail_and_unusual_duration_warn_without_certifying_content(self):
        result = analyze_pcm(tone(tail=0), expected_text=" ".join(["word"] * 60))
        self.assertTrue(result["passed"])
        self.assertTrue(any("final word" in warning for warning in result["warnings"]))
        self.assertTrue(any("pacing" in warning for warning in result["warnings"]))
        self.assertEqual(result["expected_word_count"], 60)
        self.assertFalse(result["audio_fidelity_verified"])

    def test_metadata_is_supplied_not_inferred(self):
        pcm = tone(rate=24000)
        at_24k = analyze_pcm(pcm, rate=24000)
        at_48k = analyze_pcm(pcm, rate=48000)
        self.assertEqual(at_24k["duration_seconds"], at_48k["duration_seconds"] * 2)
        self.assertEqual(at_24k["assumed_format"], "s16le_mono")
        for rate in [0, -1, True, 24000.0, 999999]:
            with self.subTest(rate=rate), self.assertRaises(ValueError):
                analyze_pcm(pcm, rate=rate)
        with self.assertRaises(TypeError):
            analyze_pcm("not audio")


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print(f"VOICE_FIDELITY_TESTS_OK: {result.testsRun} test cases; transcript mutations and PCM integrity; no acoustic-fidelity or acting-quality claim")
    raise SystemExit(0 if result.wasSuccessful() else 1)
