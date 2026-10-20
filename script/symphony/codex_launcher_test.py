"""Offline launch-boundary tests: no real tickets, credentials or Codex calls."""
from contextlib import redirect_stderr, redirect_stdout
import io
import json
from pathlib import Path
import re
import tempfile
import threading
import time
import unittest
from unittest.mock import Mock, patch
import urllib.error
import uuid

import codex_launcher as launcher


class LaunchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.workspaces = self.root / "workspaces"
        self.workspace = self.workspaces / "PIC-277"
        self.workspace.mkdir(parents=True)
        self.gate = self.root / "gate"
        self.gate.mkdir()
        self.owner = str(uuid.uuid4())
        (self.gate / "owner").write_text(self.owner)
        self.issue = {"id": self.owner, "identifier": "PIC-277", "description": "old ticket",
                      "project": {"id": launcher.PROJECT_ID}, "state": {"name": "Todo"}}

    def resolve(self, fetch=None):
        return launcher.resolve_launch(self.workspace, self.gate, "test-token",
                                       fetch=fetch or Mock(return_value=self.issue),
                                       workspace_root=self.workspaces)

    def test_older_ticket_defaults(self):
        self.assertEqual(self.resolve()[1], launcher.Settings())

    def test_all_effort_and_fast_combinations(self):
        for effort in launcher.EFFORTS:
            for fast in (False, True):
                with self.subTest(effort=effort, fast=fast):
                    self.issue["description"] = ("## Agent execution\nModel: gpt-6.1-sol\n"
                        f"Reasoning effort: {effort}\nFast mode: {'enabled' if fast else 'disabled'}\n"
                        "Reason: Scope-based recommendation.\n\n## Acceptance\nFast mode: enabled")
                    _, selected = self.resolve()
                    self.assertEqual(selected, launcher.Settings(effort=effort, fast=fast))

    def test_other_sections_cannot_set_launch_settings(self):
        text = "## Notes\nFast mode: enabled\nReasoning effort: high\n"
        self.assertEqual(launcher.parse_settings(text), launcher.Settings())

    def test_bulleted_case_insensitive_fields(self):
        text = "## Agent execution\n- Reasoning effort: HIGH\n* Fast mode: ENABLED\n"
        self.assertEqual(launcher.parse_settings(text), launcher.Settings(effort="high", fast=True))

    def test_invalid_and_conflicting_settings_are_rejected(self):
        bodies = ["Reasoning effort: ultra", "Reasoning effort: high; touch /tmp/pwned",
                  "Reasoning effort:", "Fast mode: perhaps", "Model: another-model",
                  "Fast mode: disabled\nFast mode: enabled",
                  "Reasoning effort: low\n## Agent execution\nReasoning effort: high"]
        for body in bodies:
            with self.subTest(body=body), self.assertRaises(launcher.LaunchError):
                launcher.parse_settings("## Agent execution\n" + body)

    def test_wrong_owner_workspace_project_and_inactive_state(self):
        for field, value in [("id", str(uuid.uuid4())), ("identifier", "PIC-999"),
                             ("project", {"id": "another-project"}),
                             ("state", {"name": "In Review"})]:
            with self.subTest(field=field):
                original = self.issue[field]
                self.issue[field] = value
                with self.assertRaises(launcher.LaunchError): self.resolve()
                self.issue[field] = original
        with self.assertRaises(launcher.LaunchError):
            launcher.resolve_launch(self.root, self.gate, "test-token", fetch=Mock())

    def test_owner_change_and_pause_during_lookup_are_rejected(self):
        def change_owner(*args):
            (self.gate / "owner").write_text(str(uuid.uuid4()))
            return self.issue
        with self.assertRaises(launcher.LaunchError): self.resolve(change_owner)
        (self.gate / "owner").write_text(self.owner)
        def pause(*args):
            (self.gate / "paused").touch()
            return self.issue
        with self.assertRaises(launcher.LaunchError): self.resolve(pause)

    def test_missing_and_malformed_owner_are_rejected(self):
        for value in ("", "PIC-277", "not-a-uuid"):
            (self.gate / "owner").write_text(value)
            with self.assertRaises(launcher.LaunchError): launcher.selected_owner(self.gate)
        (self.gate / "owner").unlink()
        with self.assertRaises(launcher.LaunchError): launcher.selected_owner(self.gate)

    def test_lookup_is_read_only_and_uses_bounded_request(self):
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        response.read.return_value = json.dumps({"data": {"issue": self.issue}}).encode()
        with patch.object(launcher.urllib.request, "urlopen", return_value=response) as urlopen:
            self.assertEqual(launcher.fetch_issue(self.owner, "test-token"), self.issue)
        request = urlopen.call_args.args[0]
        self.assertEqual(request.full_url, "https://api.linear.app/graphql")
        self.assertEqual(urlopen.call_args.kwargs["timeout"], 10)
        payload = json.loads(request.data)
        self.assertTrue(payload["query"].startswith("query "))
        self.assertEqual(payload["variables"], {"id": self.owner})
        response.read.assert_called_once_with(2_000_001)

    def test_lookup_errors_do_not_disclose_token_or_response(self):
        sentinel = "PRIVATE-SENTINEL"
        failures = [urllib.error.URLError(sentinel),
                    urllib.error.HTTPError("https://api.linear.app/graphql", 401, sentinel, {}, None)]
        for error in failures:
            with patch.object(launcher.urllib.request, "urlopen", side_effect=error):
                with self.assertRaises(launcher.LaunchError) as caught:
                    launcher.fetch_issue(self.owner, sentinel)
                self.assertNotIn(sentinel, str(caught.exception))
        with self.assertRaises(launcher.LaunchError): launcher.fetch_issue(self.owner, None)

    def test_invalid_api_payloads_fail_without_starting_codex(self):
        for payload in ([], {}, {"data": None}, {"data": {"issue": None}},
                        {"errors": [{"message": "PRIVATE-SENTINEL"}]}):
            response = Mock()
            response.__enter__ = Mock(return_value=response)
            response.__exit__ = Mock(return_value=False)
            response.read.return_value = json.dumps(payload).encode()
            with self.subTest(payload=payload), \
                 patch.object(launcher.urllib.request, "urlopen", return_value=response):
                with self.assertRaises(launcher.LaunchError) as caught:
                    launcher.fetch_issue(self.owner, "test-token")
                self.assertNotIn("PRIVATE-SENTINEL", str(caught.exception))

    def test_total_lookup_deadline_includes_a_slow_response_body(self):
        release = threading.Event()
        finished = threading.Event()
        def slow_read(*args):
            release.wait(1)
            finished.set()
            return b'{"data":{"issue":null}}'
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        response.read.side_effect = slow_read
        try:
            with patch.object(launcher, "LOOKUP_TIMEOUT", 0.03), \
                 patch.object(launcher.urllib.request, "urlopen", return_value=response):
                start = time.monotonic()
                with self.assertRaisesRegex(launcher.LaunchError, "total deadline"):
                    launcher.fetch_issue(self.owner, "test-token")
                self.assertLess(time.monotonic() - start, 0.5)
                self.assertFalse(finished.is_set())
        finally:
            release.set()
            self.assertTrue(finished.wait(1))

    def test_launch_flags_pin_model_and_child_defaults(self):
        args = launcher.codex_argv("/usr/bin/codex", launcher.Settings(effort="high", fast=True))
        self.assertEqual(args[0], "/usr/bin/codex")
        self.assertEqual(args[-1], "app-server")
        values = [args[i + 1] for i, a in enumerate(args) if a == "--config"]
        self.assertIn('model="gpt-6.1-sol"', values)
        self.assertIn('model_reasoning_effort="high"', values)
        self.assertIn('service_tier="fast"', values)
        self.assertIn('agents.default_subagent_model="gpt-6.1-sol"', values)
        self.assertIn('agents.default_subagent_reasoning_effort="high"', values)
        self.assertIn('agents.max_concurrent_threads_per_session=1', values)
        self.assertIn('agents.max_depth=1', values)
        self.assertIn('service_tier="default"', launcher.codex_argv("codex", launcher.Settings()))

    def test_receipt_is_private_and_contains_only_selections(self):
        self.issue["description"] = "PRIVATE-SENTINEL"
        launcher.write_receipt(self.root / "receipts", self.issue, launcher.Settings(), self.workspace)
        receipt = self.root / "receipts/PIC-277.json"
        self.assertEqual(receipt.stat().st_mode & 0o777, 0o600)
        self.assertNotIn("PRIVATE-SENTINEL", receipt.read_text())
        self.assertEqual(json.loads(receipt.read_text())["effort"], "medium")

    def test_exec_replaces_process_without_stdout_protocol_noise(self):
        class Executed(Exception): pass
        output = io.StringIO()
        with patch.object(launcher, "resolve_launch", return_value=(self.issue, launcher.Settings())), \
             patch.object(launcher.shutil, "which", return_value="/fake/codex"), \
             patch.object(launcher, "write_receipt"), \
             patch.object(launcher.os, "execv", side_effect=Executed) as execute, \
             patch.dict(launcher.os.environ, {}, clear=True), redirect_stdout(output):
            with self.assertRaises(Executed): launcher.main([])
        self.assertEqual(output.getvalue(), "")
        self.assertEqual(execute.call_args.args[0], launcher.sys.executable)
        self.assertIn(str(launcher.ROOT / "script/symphony/codex_permission_bridge.py"), execute.call_args.args[1])
        self.assertIn("/fake/codex", execute.call_args.args[1])
        self.assertEqual(execute.call_args.args[1][-1], "app-server")

    def test_check_does_not_launch_or_write_receipt(self):
        with patch.object(launcher, "resolve_launch", return_value=(self.issue, launcher.Settings())), \
             patch.object(launcher.shutil, "which", return_value="/fake/codex"), \
             patch.object(launcher, "write_receipt") as receipt, \
             patch.object(launcher.os, "execv") as execute, \
             patch.dict(launcher.os.environ, {}, clear=True), redirect_stdout(io.StringIO()) as output:
            self.assertEqual(launcher.main(["--check"]), 0)
        receipt.assert_not_called()
        execute.assert_not_called()
        self.assertEqual(json.loads(output.getvalue())["effort"], "medium")

    def test_startup_failure_is_stderr_only(self):
        with patch.object(launcher, "resolve_launch", side_effect=launcher.LaunchError("No ticket")), \
             patch.dict(launcher.os.environ, {}, clear=True), \
             redirect_stdout(io.StringIO()) as out, redirect_stderr(io.StringIO()) as err:
            self.assertEqual(launcher.main([]), 1)
        self.assertEqual(out.getvalue(), "")
        self.assertIn("No ticket", err.getvalue())

    def test_symphony_initialization_budget_covers_ticket_lookup(self):
        workflow = (launcher.ROOT / "WORKFLOW.md").read_text()
        match = re.search(r"(?m)^  read_timeout_ms:\s*(\d+)\s*$", workflow)
        self.assertIsNotNone(match)
        # Symphony starts its initialize timer before the adapter reads Linear.
        # Reserve at least five additional seconds for shell/Codex startup.
        self.assertGreaterEqual(int(match.group(1)), launcher.LOOKUP_TIMEOUT * 1000 + 5000)


if __name__ == "__main__":
    unittest.main()
