"""Run the real metadata-only workflow step against controlled GitHub responses."""

import copy
import io
import json
import os
from pathlib import Path
import tempfile
import textwrap
import unittest
from unittest.mock import patch
from contextlib import redirect_stdout


WORKFLOW = Path(__file__).resolve().parents[1] / ".github/workflows/linear-completion.yml"
CODE = compile(textwrap.dedent(WORKFLOW.read_text().split("        run: |\n", 1)[1]),
               str(WORKFLOW), "exec")


class CompletionTest(unittest.TestCase):
    def setUp(self):
        self.pr = {
            "merged": True, "merged_at": "2026-10-20T18:12:48Z",
            "merge_commit_sha": "a" * 40, "state": "closed",
            "base": {"ref": "main", "repo": {"full_name": "pickerflicker/healthie-platform"}},
            "head": {"ref": "pic-277-seeded-sign-in"},
            "body": "## Evidence\n\nKeep this report.\n\nRefs PIC-277. Parent PIC-273.",
        }
        self.writes = []

    def execute(self, event=None, repository="pickerflicker/healthie-platform", fail_write=False,
                changed_during_run=False):
        reads = 0

        def github(request, timeout):
            nonlocal reads
            self.assertEqual(request.full_url,
                             "https://api.github.com/repos/pickerflicker/healthie-platform/pulls/5")
            self.assertEqual(timeout, 20)
            if request.method == "GET":
                reads += 1
                data = copy.deepcopy(self.pr)
                if changed_during_run and reads > 1:
                    data["body"] = "A newer human edit"
            else:
                self.assertEqual(request.method, "PATCH")
                payload = json.loads(request.data)
                self.assertEqual(set(payload), {"body"})
                self.writes.append(payload)
                data = {"body": "not saved" if fail_write else payload["body"]}
            return io.BytesIO(json.dumps(data).encode())

        with tempfile.TemporaryDirectory() as temp:
            event_path = Path(temp) / "event.json"
            event_path.write_text(json.dumps(event or {"pull_request": {"number": 5}}))
            env = {"GITHUB_EVENT_PATH": str(event_path), "GITHUB_REPOSITORY": repository,
                   "GH_TOKEN": "synthetic-test-token"}
            with patch.dict(os.environ, env), patch("urllib.request.urlopen", github), redirect_stdout(io.StringIO()):
                exec(CODE, {})

    def test_refs_regression_preserves_body_and_adds_correct_closing_relation(self):
        before = self.pr["body"]
        self.execute()
        self.assertEqual(self.writes, [{"body": "Closes PIC-277\n\n" + before}])

    def test_missing_body_is_supported(self):
        self.pr["body"] = None
        self.execute()
        self.assertEqual(self.writes[0]["body"].strip(), "Closes PIC-277")

    def test_idempotent_after_repair(self):
        self.execute()
        self.pr["body"] = self.writes[0]["body"]
        self.writes.clear()
        self.execute()
        self.assertEqual(self.writes, [])

    def test_fenced_example_does_not_replace_real_closing_relation(self):
        self.pr["body"] = "```text\nCloses PIC-277\n```"
        self.execute()
        self.assertEqual(self.writes[0]["body"], "Closes PIC-277\n\n" + self.pr["body"])

    def test_unfinished_fence_cannot_swallow_closing_line(self):
        self.pr["body"] = "Unfinished example:\n```text\nRefs PIC-277"
        self.execute()
        self.assertEqual(self.writes[0]["body"], "Closes PIC-277\n\n" + self.pr["body"])

    def test_conflicting_closing_directives_fail_without_edit(self):
        for body in ("Closes PIC-273", "Fixes PIC-273, PIC-277", "Closes PIC-277\nResolves PIC-273"):
            with self.subTest(body=body):
                self.pr["body"] = body
                with self.assertRaisesRegex(SystemExit, "Conflicting closing"):
                    self.execute()
                self.assertEqual(self.writes, [])

    def test_observed_concurrent_edit_is_preserved(self):
        with self.assertRaisesRegex(SystemExit, "PR changed"):
            self.execute(changed_during_run=True)
        self.assertEqual(self.writes, [])

    def test_closed_unmerged_or_wrong_destination_never_writes(self):
        baseline = copy.deepcopy(self.pr)
        for change in ({"merged": False}, {"merged_at": None}, {"merge_commit_sha": None},
                       {"state": "open"}, {"base": {"ref": "staging", "repo": baseline["base"]["repo"]}},
                       {"base": {"ref": "main", "repo": {"full_name": "other/repository"}}}):
            with self.subTest(change=change):
                self.pr = {**copy.deepcopy(baseline), **change}
                with self.assertRaises(SystemExit):
                    self.execute()
                self.assertEqual(self.writes, [])

    def test_unrelated_branch_does_not_close_incidental_issue_mentions(self):
        self.pr["head"]["ref"] = "dependabot/bundler/example"
        self.execute()
        self.assertEqual(self.writes, [])

    def test_manual_replay_uses_same_verified_merge_path(self):
        self.execute({"inputs": {"pr_number": "5"}})
        self.assertTrue(self.writes[0]["body"].startswith("Closes PIC-277\n\n"))

    def test_invalid_number_or_repository_never_writes(self):
        with self.assertRaises(SystemExit):
            self.execute({"inputs": {"pr_number": "5/../../other"}})
        with self.assertRaises(SystemExit):
            self.execute(repository="other/repository")
        self.assertEqual(self.writes, [])

    def test_failed_patch_is_not_reported_as_success(self):
        with self.assertRaisesRegex(SystemExit, "did not confirm"):
            self.execute(fail_write=True)


if __name__ == "__main__":
    unittest.main()
