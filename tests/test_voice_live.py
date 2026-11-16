#!/usr/bin/env python3
"""Offline fake-transport tests. No API credential, network or generated voice."""
from __future__ import annotations

import asyncio
import base64
from contextlib import asynccontextmanager
from decimal import Decimal
import io
import json
import math
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import voice_live as live


def tone() -> bytes:
    # Test fixture only, deliberately not claimed as speech.
    samples = [0] * 1200 + [int(math.sin(i * .16) * 5000) for i in range(2400)] + [0] * 2400
    return struct.pack("<" + "h" * len(samples), *samples)


class FakeSocket:
    def __init__(self, text: str, *, receipt=True, malformed=False,
                 delegation=False, stall=False, provider_error=False, early_text="",
                 premature_close=False):
        self.text, self.receipt, self.malformed = text, receipt, malformed
        self.delegation, self.stall, self.provider_error = delegation, stall, provider_error
        self.early_text, self.premature_close = early_text, premature_close
        self.events = asyncio.Queue()
        self.sent = []
        self.closed = False
        self.started_delivered = False

    def __aiter__(self):
        return self

    async def __anext__(self):
        value = await self.events.get()
        if value is None:
            raise StopAsyncIteration
        if value.get("type") == "session.started":
            self.started_delivered = True
        return json.dumps(value)

    async def send(self, raw):
        event = json.loads(raw)
        self.sent.append(event)
        if event["type"] == "session.start":
            if self.early_text:
                self.events.put_nowait({"type": "session.output_transcript.delta", "delta": self.early_text})
                self.events.put_nowait({"type": "session.output_audio.delta", "delta":
                                       base64.b64encode(tone()[:2400]).decode()})
            self.events.put_nowait({"type": "session.started", "session": {"id": "live_test"}})
        if event["type"] == "session.instructions.append":
            # Accepted context does not require the model to produce speech.
            self.events.put_nowait({"type": "session.instructions.appended"})
        if event["type"] == "session.commentary.append":
            # The documented speak-first sequence requires active audio after
            # started, a unique event identifier, and required nullable context.
            if "delegation_id" not in event:
                self.events.put_nowait({"type": "error", "error": {
                    "code": "missing_required_parameter", "param": "delegation_id"}})
                return
            if not self.started_delivered or not event.get("event_id") or not any(
                    e["type"] == "session.input_audio.append" for e in self.sent[:-1]):
                self.events.put_nowait({"type": "error", "error": {"code": "invalid_trigger_sequence"}})
                return
            self.events.put_nowait({"type": "session.commentary.appended"})
            if self.stall:
                return
            self.events.put_nowait({"type": "session.output_transcript.delta", "delta": self.text,
                                   "start_ms": 0, "end_ms": 450})
            self.events.put_nowait({"type": "session.output_audio.delta", "delta":
                "not base64!" if self.malformed else base64.b64encode(tone()).decode()})
            for seconds in (1, 2):
                self.events.put_nowait({"type": "session.usage.updated", "usage": {"seconds": seconds}})
            if self.delegation:
                self.events.put_nowait({"type": "session.delegation.created", "delegation": {"id": "unused"}})
            if self.provider_error:
                self.events.put_nowait({"type": "error", "error": {
                    "code": "invalid_event", "message": "SECRET must never be persisted", "Authorization": "SECRET"}})
            if self.premature_close:
                self.events.put_nowait({"type": "session.closed", "reason": "interrupted", "usage": {"seconds": 3}})
        if event["type"] == "session.close":
            self.closed = True
            if self.receipt:
                self.events.put_nowait({"type": "session.closed", "reason": "close_requested",
                                       "usage": {"seconds": 3}})


class FakeConnector:
    def __init__(self, socket: FakeSocket):
        self.socket = socket
        self.calls = 0
        self.arguments = None

    @asynccontextmanager
    async def __call__(self, *args, **kwargs):
        self.calls += 1
        self.arguments = (args, kwargs)
        yield self.socket


class RecorderTests(unittest.TestCase):
    def setUp(self):
        self.plan, self.digest = live.load_plan()
        self.sample = self.plan["samples"][0]
        self.temp = tempfile.TemporaryDirectory(prefix="voice-live-tests-", dir=ROOT / "work")
        self.directory = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def approval(self, **updates):
        value = {"approved": True, "scope": live.SCOPE, "manifest_sha256": self.digest,
                 "cap_usd": self.plan["spending_cap_usd"]}
        value.update(updates)
        return value

    def replacement_approval(self, **updates):
        value = {"approved": True, "scope": live.REPLACEMENT_SCOPE,
                 "manifest_sha256": self.digest, "cap_usd": .25,
                 "line_id": live.REPLACEMENT_LINE,
                 "replaces_attempt_id": live.REPLACEMENT_ATTEMPT,
                 "max_additional_attempts": 1}
        value.update(updates)
        return value

    def seed_zero_usage_original(self, ledger):
        original = ledger.reserve(live.REPLACEMENT_LINE, self.plan, Decimal(".25"))
        original["attempt_id"] = live.REPLACEMENT_ATTEMPT
        ledger.settle(original, live.CaptureResult(final_seconds=0,
            reasons=["provider_error:missing_required_parameter"]), .05)
        return original

    def natural_revision(self):
        frozen = self.directory / "frozen-ledger.json"
        entries = [{"attempt_id": "prior_" + str(index), "billing_state": "final_receipt",
                    "usage_seconds": seconds, "actual_usd": str(live.money(seconds))}
                   for index, seconds in enumerate((60, 57, .0012))]
        live.atomic_json(frozen, {"attempts": entries})
        plan = json.loads(json.dumps(self.plan))
        output = self.directory / "natural-take"
        plan.update(performance_style="natural_in_scene_v1", recordable_line_ids=["mara_refuge_r0"],
                    max_attempts_total=1, max_attempts_per_line=1, session_limit_seconds=60,
                    close_grace_seconds=10, quiet_tail_seconds=8,
                    output_directory=str(output.relative_to(ROOT)),
                    carry_in_ledger={"path": str(frozen.relative_to(ROOT)),
                                     "sha256": live.sha256(frozen.read_bytes()), "spent_usd": "0.097501"})
        mara = next(sample for sample in plan["samples"] if sample["line_id"] == "mara_refuge_r0")
        mara["direction"] = "Mara quietly answers Iona beside the failing pump. She is tired but determined."
        path = self.directory / "revision.json"
        live.atomic_json(path, plan)
        plan, digest = live.load_plan(path)
        return plan, digest, path, frozen, output

    def capture(self, socket, **timing_updates):
        timing = dict(total=.35, close_grace=.07, quiet=.02,
                      startup=.08, no_audio=.12, poll=.001, send=.025)
        timing.update(timing_updates)
        connector = FakeConnector(socket)
        result = asyncio.run(live.capture_session(connector, api_key="TEST_ONLY_SECRET",
            plan=self.plan, sample=self.sample, timing=live.Timing(**timing)))
        self.assertEqual(connector.calls, 1)
        return result, connector

    def test_offline_default_reads_no_credentials(self):
        with patch.object(live, "read_key", side_effect=AssertionError("key must not be read")):
            with patch("sys.stdout", new=io.StringIO()) as stdout:
                self.assertEqual(live.main([]), 0)
        report = json.loads(stdout.getvalue())
        self.assertEqual(report["network_calls"], 0)
        self.assertEqual(report["mode"], "offline_estimate")
        self.assertEqual(len(report["samples"]), 3)

    def test_record_requires_approval_before_key(self):
        with patch.object(live, "read_key", side_effect=AssertionError("key must not be read")):
            with patch("sys.stdout", new=io.StringIO()):
                self.assertEqual(live.main(["--record", self.sample["line_id"]]), 2)
        for update in ({"approved": False}, {"manifest_sha256": "changed"},
                       {"scope": "full_game"}, {"cap_usd": 50}, {"cap_usd": "NaN"}):
            with self.assertRaises(live.Refused):
                live.validate_approval(self.approval(**update), self.plan, self.digest)

    def test_complete_source_hash_not_legacy_spoken_text(self):
        script = live.read_json(live.SCRIPT)
        script["lines"][self.sample["line_id"]]["text"] += " Extra words."
        path = self.directory / "script.json"
        live.atomic_json(path, script)
        with self.assertRaises(live.Refused):
            live.load_plan(live.PLAN, path)

    def test_unknown_line_refused_before_key(self):
        approval = self.directory / "approval.json"
        live.atomic_json(approval, self.approval())
        with patch.object(live, "read_key", side_effect=AssertionError("key must not be read")):
            with patch("sys.stdout", new=io.StringIO()):
                self.assertEqual(live.main(["--record", "narration_ending", "--approval", str(approval)]), 2)

    def test_reservation_persisted_and_parallel_run_refused(self):
        with live.Ledger(self.directory, self.digest) as ledger:
            attempt = ledger.reserve(self.sample["line_id"], self.plan, Decimal("0.25"))
            persisted = live.read_json(self.directory / "ledger.json")
            self.assertEqual(persisted["attempts"][0]["billing_state"], "reserved")
            self.assertEqual(Decimal(attempt["reserved_usd"]), Decimal("0.075"))
            with self.assertRaises(live.Refused):
                with live.Ledger(self.directory, self.digest):
                    self.fail("parallel ledger entered")
        # An interrupted call remains unresolved even after the process lock ends.
        with live.Ledger(self.directory, self.digest) as ledger:
            with self.assertRaises(live.Refused):
                ledger.reserve(self.plan["samples"][1]["line_id"], self.plan, Decimal("0.25"))

    def test_budget_and_attempts_limit_no_retakes(self):
        plan = dict(self.plan, max_attempts_total=3, max_attempts_per_line=1)
        with live.Ledger(self.directory, self.digest) as ledger:
            with self.assertRaises(live.Refused):
                ledger.reserve(self.sample["line_id"], plan, Decimal("0.07"))
            for sample in plan["samples"]:
                attempt = ledger.reserve(sample["line_id"], plan, Decimal("0.25"))
                ledger.settle(attempt, live.CaptureResult(final_seconds=90), .05)
                with self.assertRaises(live.Refused):
                    ledger.reserve(sample["line_id"], plan, Decimal("0.25"))
            self.assertEqual(sum(Decimal(a["actual_usd"]) for a in ledger.data["attempts"]), Decimal("0.225"))
            with self.assertRaises(live.Refused):
                ledger.reserve("fourth", plan, Decimal("0.25"))

    def test_replacement_supplement_does_not_broaden_scope_or_budget(self):
        for change in ({"approved": False}, {"scope": live.SCOPE},
                       {"manifest_sha256": "changed"}, {"cap_usd": .26},
                       {"cap_usd": .24}, {"line_id": "rowan_kitchen_r2"},
                       {"replaces_attempt_id": "other"}, {"max_additional_attempts": 2},
                       {"max_additional_attempts": True}):
            with self.subTest(change=change), self.assertRaises(live.Refused):
                live.validate_replacement_approval(self.replacement_approval(**change),
                    self.plan, self.digest, live.REPLACEMENT_LINE, Decimal(".25"))
        approval_path, supplement_path = self.directory / "approval.json", self.directory / "replacement.json"
        live.atomic_json(approval_path, self.approval())
        live.atomic_json(supplement_path, self.replacement_approval())
        with patch.object(live, "read_key", side_effect=AssertionError("key must not be read")):
            with patch("sys.stdout", new=io.StringIO()):
                self.assertEqual(live.main(["--record", "rowan_kitchen_r2", "--approval",
                    str(approval_path), "--replacement-approval", str(supplement_path)]), 2)

    def test_one_replacement_preserves_original_and_base_limits(self):
        with live.Ledger(self.directory, self.digest) as ledger:
            original = self.seed_zero_usage_original(ledger)
            original_snapshot = json.loads(json.dumps(original))
            for sample in self.plan["samples"][1:]:
                attempt = ledger.reserve(sample["line_id"], self.plan, Decimal(".25"))
                ledger.settle(attempt, live.CaptureResult(final_seconds=30), .05)
            with self.assertRaises(live.Refused):
                ledger.reserve(live.REPLACEMENT_LINE, self.plan, Decimal(".25"))
            replacement = ledger.reserve(live.REPLACEMENT_LINE, self.plan, Decimal(".25"),
                                         replacement_approval=self.replacement_approval())
            self.assertEqual(original, original_snapshot)
            self.assertEqual(replacement["replacement_for"], live.REPLACEMENT_ATTEMPT)
            self.assertEqual(Decimal(replacement["reserved_usd"]), Decimal(".075"))
            self.assertEqual(len(replacement["replacement_approval_sha256"]), 64)
            ledger.settle(replacement, live.CaptureResult(final_seconds=20), .05)
            with self.assertRaises(live.Refused):
                ledger.reserve(live.REPLACEMENT_LINE, self.plan, Decimal(".25"),
                               replacement_approval=self.replacement_approval())
            for sample in self.plan["samples"]:
                with self.assertRaises(live.Refused):
                    ledger.reserve(sample["line_id"], self.plan, Decimal(".25"))
            self.assertEqual(len(ledger.data["attempts"]), 4)

    def test_replacement_does_not_consume_an_unused_base_sample(self):
        with live.Ledger(self.directory, self.digest) as ledger:
            self.seed_zero_usage_original(ledger)
            replacement = ledger.reserve(live.REPLACEMENT_LINE, self.plan, Decimal(".25"),
                                         replacement_approval=self.replacement_approval())
            ledger.settle(replacement, live.CaptureResult(final_seconds=10), .05)
            for sample in self.plan["samples"][1:]:
                attempt = ledger.reserve(sample["line_id"], self.plan, Decimal(".25"))
                ledger.settle(attempt, live.CaptureResult(final_seconds=10), .05)
                with self.assertRaises(live.Refused):
                    ledger.reserve(sample["line_id"], self.plan, Decimal(".25"))
            self.assertEqual(len(ledger.data["attempts"]), 4)

    def test_replacement_requires_exact_zero_usage_quarantined_original(self):
        changes = ({"usage_seconds": 1, "actual_usd": "0.000834"},
                   {"usage_seconds": 0, "actual_usd": "0.01"},
                   {"billing_state": "unresolved"}, {"result_status": "pending_listening"},
                   {"attempt_id": "different"}, {"line_id": "rowan_kitchen_r2"})
        for index, change in enumerate(changes):
            with self.subTest(change=change):
                with live.Ledger(self.directory / str(index), self.digest) as ledger:
                    original = self.seed_zero_usage_original(ledger)
                    original.update(change)
                    with self.assertRaises(live.Refused):
                        ledger.reserve(live.REPLACEMENT_LINE, self.plan, Decimal(".25"),
                                       replacement_approval=self.replacement_approval())
                    self.assertEqual(len(ledger.data["attempts"]), 1)
        with live.Ledger(self.directory / "missing", self.digest) as ledger:
            with self.assertRaises(live.Refused):
                ledger.reserve(live.REPLACEMENT_LINE, self.plan, Decimal(".25"),
                               replacement_approval=self.replacement_approval())

    def test_cumulative_snapshots_not_summed(self):
        result, connector = self.capture(FakeSocket(self.sample["script"]))
        self.assertEqual(result.last_usage_seconds, 2)
        self.assertEqual(result.final_seconds, 3)
        self.assertEqual(result.status, "pending_listening")
        self.assertFalse(result.signal["audio_fidelity_verified"])
        start = next(x for x in connector.socket.sent if x["type"] == "session.start")
        self.assertEqual(start["session"]["model"], "gpt-live-1")
        self.assertEqual(start["session"]["audio"]["output"]["voice"], self.sample["voice"])
        self.assertEqual(start["session"]["delegation"], {"type": "client"})
        self.assertFalse(start["session"]["store"])
        self.assertTrue(start["session"]["input"][0]["content"][0]["text"].endswith(self.sample["script"]))
        commentary = next(x for x in connector.socket.sent if x["type"] == "session.commentary.append")
        self.assertIn("delegation_id", commentary)
        self.assertIsNone(commentary["delegation_id"])
        self.assertEqual(commentary["content"], start["session"]["input"][0]["content"][0]["text"])
        self.assertIn("Speak first in English", commentary["content"])
        self.assertNotIn("Remain completely silent until", start["session"]["instructions"])
        sent_types = [x["type"] for x in connector.socket.sent]
        self.assertLess(sent_types.index("session.input_audio.append"), sent_types.index("session.commentary.append"))
        self.assertEqual(sent_types.count("session.commentary.append"), 1)
        self.assertTrue(connector.socket.closed)
        self.assertNotIn("session.instructions.append", sent_types)
        with live.Ledger(self.directory, self.digest) as ledger:
            attempt = ledger.reserve(self.sample["line_id"], self.plan, Decimal("0.25"))
            ledger.settle(attempt, result, .05)
            self.assertEqual(Decimal(attempt["actual_usd"]), Decimal("0.0025"))

    def test_separate_rowan_approval_allows_only_one_replacement_after_iona(self):
        line = "rowan_kitchen_r2"
        spec = live.APPROVED_REPLACEMENTS[line]
        approval = self.replacement_approval(line_id=line, scope=spec["scope"],
                                             replaces_attempt_id=spec["attempt"])
        with live.Ledger(self.directory, self.digest) as ledger:
            self.seed_zero_usage_original(ledger)
            rowan = ledger.reserve(line, self.plan, Decimal(".25"))
            rowan["attempt_id"] = spec["attempt"]
            ledger.settle(rowan, live.CaptureResult(final_seconds=30), .05)
            snapshot = json.loads(json.dumps(rowan))
            mara = ledger.reserve("mara_refuge_r0", self.plan, Decimal(".25"))
            ledger.settle(mara, live.CaptureResult(final_seconds=31), .05)
            iona = ledger.reserve(live.REPLACEMENT_LINE, self.plan, Decimal(".25"),
                                 replacement_approval=self.replacement_approval())
            ledger.settle(iona, live.CaptureResult(final_seconds=23), .05)
            with self.assertRaises(live.Refused):
                ledger.reserve(line, self.plan, Decimal(".25"))
            replacement = ledger.reserve(line, self.plan, Decimal(".25"),
                                         replacement_approval=approval)
            ledger.settle(replacement, live.CaptureResult(final_seconds=40), .05)
            self.assertEqual(rowan, snapshot)
            self.assertEqual(replacement["replacement_for"], spec["attempt"])
            self.assertEqual(len(ledger.data["attempts"]), 5)
            with self.assertRaises(live.Refused):
                ledger.reserve(line, self.plan, Decimal(".25"), replacement_approval=approval)
            with self.assertRaises(live.Refused):
                ledger.reserve("mara_refuge_r0", self.plan, Decimal(".25"), replacement_approval=approval)

    def test_rowan_replacement_requires_exact_silent_capture_receipt(self):
        line = "rowan_kitchen_r2"
        spec = live.APPROVED_REPLACEMENTS[line]
        approval = self.replacement_approval(line_id=line, scope=spec["scope"],
                                             replaces_attempt_id=spec["attempt"])
        with live.Ledger(self.directory, self.digest) as ledger:
            rowan = ledger.reserve(line, self.plan, Decimal(".25"))
            rowan["attempt_id"] = spec["attempt"]
            ledger.settle(rowan, live.CaptureResult(final_seconds=31), .05)
            with self.assertRaises(live.Refused):
                ledger.reserve(line, self.plan, Decimal(".25"), replacement_approval=approval)

    def test_preamble_paraphrase_and_missing_final_word_reject(self):
        for observed in ("Certainly. " + self.sample["script"],
                         "Mara went to the pumping works.",
                         self.sample["script"].rsplit(" ", 1)[0]):
            with self.subTest(observed=observed):
                result, _ = self.capture(FakeSocket(observed))
                self.assertEqual(result.status, "quarantined")
                self.assertIn("script_mismatch", result.reasons)
                self.assertEqual(result.final_seconds, 3)

    def test_malformed_audio_quarantines_but_still_closes(self):
        result, connector = self.capture(FakeSocket(self.sample["script"], malformed=True))
        self.assertEqual(result.status, "quarantined")
        self.assertIn("malformed_pcm", result.reasons)
        self.assertTrue(connector.socket.closed)
        self.assertEqual(result.final_seconds, 3)

    def test_preamble_before_instruction_is_not_discarded(self):
        result, _ = self.capture(FakeSocket(self.sample["script"], early_text="Hello. "))
        self.assertTrue(result.transcript.startswith("Hello. "))
        self.assertIn("script_mismatch", result.reasons)
        self.assertEqual(len(result.pcm), len(tone()) + 2400)
        self.assertEqual(result.status, "quarantined")

    def test_premature_provider_closure_is_not_audio_completion(self):
        result, _ = self.capture(FakeSocket(self.sample["script"], premature_close=True))
        self.assertIn("unexpected_session_closure", result.reasons)
        self.assertEqual(result.final_seconds, 3)
        self.assertEqual(result.status, "quarantined")

    def test_delegation_never_invokes_backend(self):
        result, connector = self.capture(FakeSocket(self.sample["script"], delegation=True))
        self.assertIn("unexpected_delegation_no_backend_called", result.reasons)
        self.assertEqual(result.status, "quarantined")
        self.assertEqual(connector.calls, 1)

    def test_missing_final_receipt_stops_next_chargeable_attempt(self):
        result, _ = self.capture(FakeSocket(self.sample["script"], receipt=False))
        self.assertIn("missing_final_usage_receipt", result.reasons)
        self.assertEqual(result.last_usage_seconds, 2)
        self.assertIsNone(result.final_seconds)
        with live.Ledger(self.directory, self.digest) as ledger:
            attempt = ledger.reserve(self.sample["line_id"], self.plan, Decimal("0.25"))
            ledger.settle(attempt, result, .05)
            with self.assertRaises(live.Refused):
                ledger.reserve(self.plan["samples"][1]["line_id"], self.plan, Decimal("0.25"))

    def test_deadline_closes_session(self):
        result, connector = self.capture(FakeSocket(self.sample["script"], stall=True), no_audio=10)
        self.assertIn("recording_deadline", result.reasons)
        self.assertTrue(connector.socket.closed)
        self.assertEqual(result.status, "quarantined")

    def test_commentary_acknowledgment_is_not_speech_or_completion(self):
        result, connector = self.capture(FakeSocket(self.sample["script"], stall=True))
        self.assertIn("session.commentary.appended", [event["type"] for event in result.events])
        self.assertIn("no_audible_reply", result.reasons)
        self.assertEqual(result.transcript, "")
        self.assertEqual(result.pcm, b"")
        self.assertEqual(result.status, "quarantined")
        self.assertTrue(connector.socket.closed)

    def test_request_provenance_has_exact_text_version_and_digest(self):
        result, connector = self.capture(FakeSocket(self.sample["script"]))
        folder = live.save_result(self.directory, {"attempt_id": "provenance"},
                                 self.plan, self.digest, self.sample, result)
        provenance = live.read_json(folder / "result.json")["request_provenance"]
        digest = provenance.pop("request_sha256")
        self.assertEqual(provenance["prompt_version"], live.PROMPT_VERSION)
        self.assertEqual(provenance["initial_developer_text"], live.performance_request(self.sample))
        self.assertEqual(provenance["trigger_content"], provenance["initial_developer_text"])
        start = connector.socket.sent[0]["session"]
        self.assertEqual(provenance["session_instructions"], start["instructions"])
        raw = json.dumps(provenance, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        self.assertEqual(digest, live.sha256(raw.encode("utf-8")))

    def test_reports_exclude_credentials_and_provider_error_messages(self):
        result, _ = self.capture(FakeSocket(self.sample["script"], provider_error=True))
        attempt = {"attempt_id": "fixture"}
        folder = live.save_result(self.directory, attempt, self.plan, self.digest, self.sample, result)
        combined = "".join(path.read_text() for path in folder.iterdir() if path.suffix != ".wav")
        self.assertNotIn("SECRET", combined)
        self.assertNotIn("Authorization", combined)
        self.assertNotIn(base64.b64encode(tone()).decode(), combined)
        self.assertIn("provider_error:invalid_event", combined)
        metadata = live.read_json(folder / "result.json")
        self.assertFalse(metadata["listening_accepted"])
        self.assertFalse(metadata["promoted_to_game"])

    def test_usage_over_reservation_blocks_new_requests(self):
        with live.Ledger(self.directory, self.digest) as ledger:
            attempt = ledger.reserve(self.sample["line_id"], self.plan, Decimal("0.25"))
            ledger.settle(attempt, live.CaptureResult(final_seconds=91), .05)
            self.assertTrue(attempt["over_reservation"])
            with self.assertRaises(live.Refused):
                ledger.reserve(self.plan["samples"][1]["line_id"], self.plan, Decimal("0.25"))

    def test_revision_carries_all_spend_and_only_reserves_one_mara(self):
        plan, digest, _path, frozen, output = self.natural_revision()
        frozen_bytes = frozen.read_bytes()
        self.assertEqual(live.carry_in_spend(plan), Decimal("0.097501"))
        with live.Ledger(output, digest) as ledger:
            with self.assertRaises(live.Refused):
                ledger.reserve("mara_refuge_r0", plan, Decimal(".14"))
            with self.assertRaises(live.Refused):
                ledger.reserve("rowan_kitchen_r2", plan, Decimal(".25"))
            attempt = ledger.reserve("mara_refuge_r0", plan, Decimal(".25"))
            self.assertEqual(Decimal(attempt["reserved_usd"]), Decimal(".05"))
            self.assertEqual(attempt["carry_in_usd"], "0.097501")
            ledger.settle(attempt, live.CaptureResult(final_seconds=60), .05)
            with self.assertRaises(live.Refused):
                ledger.reserve("mara_refuge_r0", plan, Decimal(".25"))
        self.assertEqual(frozen.read_bytes(), frozen_bytes)
        with live.Ledger(output, digest) as ledger:
            with self.assertRaises(live.Refused):
                ledger.reserve("mara_refuge_r0", plan, Decimal(".25"))

    def test_revision_hash_receipts_and_total_must_all_agree(self):
        plan, _digest, _path, frozen, _output = self.natural_revision()
        original = frozen.read_bytes()
        frozen.write_bytes(original + b"\n")
        with self.assertRaises(live.Refused):
            live.carry_in_spend(plan)
        frozen.write_bytes(original)
        for update in ({"billing_state": "unresolved"}, {"actual_usd": "0.000000"},
                       {"usage_seconds": -1}):
            ledger = json.loads(original)
            ledger["attempts"][0].update(update)
            live.atomic_json(frozen, ledger)
            plan["carry_in_ledger"]["sha256"] = live.sha256(frozen.read_bytes())
            with self.subTest(update=update), self.assertRaises(live.Refused):
                live.carry_in_spend(plan)
        frozen.write_bytes(original)
        plan["carry_in_ledger"]["sha256"] = live.sha256(original)
        plan["carry_in_ledger"]["spent_usd"] = "0.001"
        with self.assertRaises(live.Refused):
            live.carry_in_spend(plan)

    def test_revision_cannot_reset_spend_by_selecting_another_output(self):
        plan, digest, path, _frozen, _output = self.natural_revision()
        other = self.directory / "fresh-output"
        with live.Ledger(other, digest) as ledger:
            with self.assertRaises(live.Refused):
                ledger.reserve("mara_refuge_r0", plan, Decimal(".25"))
        with patch.object(live, "read_key", side_effect=AssertionError("key must not be read")):
            with patch("sys.stdout", new=io.StringIO()):
                self.assertEqual(live.main(["--plan", str(path), "--output", str(other)]), 2)
                self.assertEqual(live.main(["--plan", str(path), "--output", "/tmp/voice-output"]), 2)
        with self.assertRaises(live.Refused):
            live.load_plan(Path("/tmp/outside-manifest.json"))

    def test_revision_approval_and_line_scope_precede_credentials(self):
        plan, digest, path, _frozen, _output = self.natural_revision()
        approval = self.approval(manifest_sha256=digest)
        with self.assertRaises(live.Refused):
            live.validate_approval(approval, plan, digest)
        approval["allowed_line_ids"] = ["mara_refuge_r0", "ch1_closing"]
        with self.assertRaises(live.Refused):
            live.validate_approval(approval, plan, digest)
        approval["allowed_line_ids"] = ["mara_refuge_r0"]
        approval_path = self.directory / "revision-approval.json"
        live.atomic_json(approval_path, approval)
        self.assertEqual(live.validate_approval(approval, plan, digest), Decimal(".25"))
        with patch.object(live, "read_key", side_effect=AssertionError("key must not be read")):
            with patch("sys.stdout", new=io.StringIO()):
                self.assertEqual(live.main(["--plan", str(path), "--record", "ch1_closing",
                                           "--approval", str(approval_path)]), 2)

    def test_natural_prompt_starts_with_direction_and_keeps_exact_script(self):
        plan, _digest, _path, _frozen, _output = self.natural_revision()
        sample = next(s for s in plan["samples"] if s["line_id"] == "mara_refuge_r0")
        instruction = live.instructions(plan, sample)
        request = live.performance_request(sample, plan)
        self.assertTrue(instruction.startswith(sample["direction"]))
        self.assertIn("unvoiced breaths", instruction)
        self.assertNotRegex(instruction.lower() + request.lower(), r"\b(read|perform|book|narration)\b")
        self.assertTrue(request.endswith(sample["script"]))
        self.assertEqual(request.count(sample["script"]), 1)
        socket = FakeSocket(sample["script"])
        connector = FakeConnector(socket)
        timing = live.Timing(total=.35, close_grace=.07, quiet=.02, startup=.08,
                             no_audio=.12, poll=.001, send=.025)
        result = asyncio.run(live.capture_session(connector, api_key="TEST_ONLY_SECRET",
                            plan=plan, sample=sample, timing=timing))
        self.assertEqual(result.status, "pending_listening")
        self.assertEqual(result.request_provenance["prompt_version"], "qm-live-natural-in-scene-v1")
        self.assertEqual(result.request_provenance["trigger_content"], request)
        self.assertFalse(result.signal["audio_fidelity_verified"])


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(RecorderTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print(f"VOICE_LIVE_TESTS_OK: {result.testsRun} offline cases; no network, keys or production recordings")
    raise SystemExit(0 if result.wasSuccessful() else 1)
