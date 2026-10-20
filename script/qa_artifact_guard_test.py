"""Exercise the evidence guard against real staged and committed Git changes."""

import pathlib
import shutil
import subprocess
import tempfile
import unittest


GUARD = pathlib.Path(__file__).resolve().parents[1] / "bin/check-qa-artifacts"


class ArtifactGuardTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = pathlib.Path(self.temp.name)
        self.git("init", "-q")
        self.git("config", "user.name", "Guard Test")
        self.git("config", "user.email", "guard@example.invalid")
        (self.repo / "bin").mkdir()
        shutil.copy2(GUARD, self.repo / "bin/check-qa-artifacts")
        self.write(".gitignore", "/docs/qa/\n/test-results/\n/playwright-report/\n/qa-artifacts/\n/tmp/\n")
        self.git("add", ".")
        self.git("commit", "-qm", "Base")
        self.base = self.git("rev-parse", "HEAD").stdout.strip()

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.repo, text=True,
                              capture_output=True, check=True)

    def write(self, path, content="test evidence"):
        destination = self.repo / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(content)

    def guard(self, *args, expected=0):
        result = subprocess.run([str(self.repo / "bin/check-qa-artifacts"), *args],
                                cwd=self.repo, text=True, capture_output=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def test_forced_staged_evidence_is_rejected(self):
        for prefix in ("docs/qa", "test-results", "playwright-report", "qa-artifacts", "tmp/qa-reports"):
            with self.subTest(prefix=prefix):
                path = prefix + "/test case.png"
                self.write(path)
                self.git("add", "-f", "--", path)
                result = self.guard(expected=1)
                self.assertIn(path, result.stderr)
                self.git("reset", "-q", "HEAD", "--", path)

    def test_pr_diff_rejects_evidence_but_allows_cleanup(self):
        self.write("docs/qa/test.png")
        self.git("add", "-f", "docs/qa/test.png")
        self.git("commit", "-qm", "Accidental evidence")
        artifact_commit = self.git("rev-parse", "HEAD").stdout.strip()
        self.guard("--base", self.base, expected=1)
        self.git("rm", "-q", "docs/qa/test.png")
        self.guard()
        self.git("commit", "-qm", "Remove evidence")
        self.guard("--base", self.base)
        self.guard("--base", artifact_commit)

    def test_source_and_reusable_fixtures_are_allowed(self):
        self.write("test/browser/login.spec.js", "// Reusable assertion\n")
        self.write("test/fixtures/avatar.png")
        self.git("add", "test")
        self.guard()
        self.git("commit", "-qm", "Reusable tests")
        self.guard("--base", self.base)

    def test_invalid_base_fails_closed(self):
        result = subprocess.run([str(self.repo / "bin/check-qa-artifacts"), "--base", "missing-ref"],
                                cwd=self.repo, capture_output=True)
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
