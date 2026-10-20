"""Ticket settings -> Codex arguments and the local Git permission adapter."""
import argparse
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import queue
import re
import shutil
import sys
import tempfile
import threading
import urllib.error
import urllib.request
import uuid

MODEL = "gpt-6.1-sol"
PROJECT_ID = "f7ab5d2f-ebf7-4dad-b5b3-f17e8c9bf538"
WORKSPACE_ROOT = Path("/Users/smh/dev/healthie-platform-workspaces")
ROOT = Path(__file__).resolve().parents[2]
EFFORTS = ("low", "medium", "high")
LOOKUP_TIMEOUT = 10


class LaunchError(Exception):
    """A safe-to-display launcher error, without ticket bodies or credentials."""


@dataclass(frozen=True)
class Settings:
    model: str = MODEL
    effort: str = "medium"
    fast: bool = False


def parse_settings(description):
    """Read only the Agent execution section; older tickets use defaults."""
    sections = re.split(r"(?m)^##[ \t]+", description or "")
    matches = [s.split("\n", 1) for s in sections[1:]
               if s.split("\n", 1)[0].strip().lower() == "agent execution"]
    if len(matches) > 1:
        raise LaunchError("Duplicate Agent execution sections.")
    if not matches:
        return Settings()
    body = matches[0][1] if len(matches[0]) == 2 else ""
    body = re.split(r"(?m)^#[ \t]+", body, maxsplit=1)[0]
    values = {}
    for line in body.splitlines():
        match = re.fullmatch(r"\s*(?:[-*]\s+)?(Model|Reasoning effort|Fast mode|Reason):\s*(.*?)\s*", line, re.I)
        if not match:
            continue
        key, value = match.group(1).lower(), match.group(2).strip()
        if key in values:
            raise LaunchError("Duplicate Agent execution field.")
        values[key] = value
    model = values.get("model", MODEL)
    effort = values.get("reasoning effort", "medium").lower()
    fast = values.get("fast mode", "disabled").lower()
    if model != MODEL:
        raise LaunchError("Healthie requires model gpt-6.1-sol.")
    if effort not in EFFORTS:
        raise LaunchError("Reasoning effort must be low, medium or high.")
    if fast not in ("enabled", "disabled"):
        raise LaunchError("Fast mode must be enabled or disabled.")
    return Settings(model=model, effort=effort, fast=fast == "enabled")


def selected_owner(gate):
    try:
        owner = (gate / "owner").read_text().strip()
        return str(uuid.UUID(owner))
    except (OSError, ValueError):
        raise LaunchError("Selected ticket owner is missing or invalid.") from None


def fetch_issue(owner, token):
    if not token:
        raise LaunchError("LINEAR_API_KEY is required for the ticket lookup.")
    # urlopen's socket timeout alone is not a total response deadline. A daemon
    # reader lets the launcher fail and exit even if a response trickles forever.
    result = queue.Queue(maxsize=1)

    def read():
        try:
            result.put(_fetch_issue(owner, token))
        except LaunchError as error:
            result.put(error)
        except Exception:
            result.put(LaunchError("Linear ticket lookup failed."))

    threading.Thread(target=read, daemon=True).start()
    try:
        issue = result.get(timeout=LOOKUP_TIMEOUT)
    except queue.Empty:
        raise LaunchError("Linear ticket lookup exceeded its total deadline.") from None
    if isinstance(issue, LaunchError):
        raise issue
    return issue


def _fetch_issue(owner, token):
    query = """query HealthieLaunch($id: String!) {
      issue(id: $id) { id identifier description project { id } state { name } }
    }"""
    request = urllib.request.Request(
        "https://api.linear.app/graphql",
        data=json.dumps({"query": query, "variables": {"id": owner}}).encode(),
        headers={"Authorization": token, "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=LOOKUP_TIMEOUT) as response:
            raw = response.read(2_000_001)
        if len(raw) > 2_000_000:
            raise LaunchError("Linear ticket response exceeded the size limit.")
        payload = json.loads(raw)
        if not isinstance(payload, dict) or payload.get("errors"):
            raise LaunchError("Linear could not resolve the selected ticket.")
        data = payload.get("data")
        issue = data.get("issue") if isinstance(data, dict) else None
        if not isinstance(issue, dict):
            raise LaunchError("Linear returned no selected ticket.")
        return issue
    except urllib.error.HTTPError as error:
        raise LaunchError(f"Linear ticket lookup failed (HTTP {error.code}).") from None
    except (OSError, ValueError, TypeError):
        raise LaunchError("Linear ticket lookup failed; check connectivity and authentication.") from None


def resolve_launch(workspace, gate, token, fetch=fetch_issue, workspace_root=WORKSPACE_ROOT):
    workspace = workspace.resolve()
    if workspace.parent != workspace_root.resolve() or not re.fullmatch(r"PIC-\d+", workspace.name):
        raise LaunchError("Run the launcher inside a Healthie ticket workspace.")
    owner = selected_owner(gate)
    issue = fetch(owner, token)
    if issue.get("id") != owner or issue.get("identifier") != workspace.name:
        raise LaunchError("Selected ticket does not match this workspace.")
    if not isinstance(issue.get("project"), dict) or issue["project"].get("id") != PROJECT_ID:
        raise LaunchError("Selected ticket belongs to a different Linear project.")
    if not isinstance(issue.get("state"), dict) or issue["state"].get("name") not in ("Todo", "In Progress"):
        raise LaunchError("Selected ticket is not Todo or In Progress.")
    # Detect ownership/pause changes while the network lookup was in progress.
    if selected_owner(gate) != owner or (gate / "paused").exists():
        raise LaunchError("Dispatch ownership changed or dispatch is paused.")
    description = issue.get("description")
    if description is not None and not isinstance(description, str):
        raise LaunchError("Linear returned an invalid ticket description.")
    return issue, parse_settings(description)


def codex_argv(executable, settings):
    overrides = {
        "shell_environment_policy.inherit": "all",
        "model": MODEL,
        "model_reasoning_effort": settings.effort,
        "service_tier": "fast" if settings.fast else "default",
        "agents.default_subagent_model": MODEL,
        "agents.default_subagent_reasoning_effort": settings.effort,
        "agents.max_concurrent_threads_per_session": 1,
        "agents.max_depth": 1,
    }
    args = [executable, "--strict-config"]
    for key, value in overrides.items():
        args.extend(["--config", f"{key}={json.dumps(value)}"])
    return args + ["app-server"]


def write_receipt(folder, issue, settings, workspace):
    """Only non-secret launch selections; never store API responses or tokens."""
    folder.mkdir(parents=True, exist_ok=True)
    receipt = {"issue": issue["identifier"], "issue_id": issue["id"],
               "workspace": str(workspace), **asdict(settings),
               "service_tier": "fast" if settings.fast else "default",
               "selected_at": datetime.now(timezone.utc).isoformat()}
    fd, name = tempfile.mkstemp(prefix=".launch-", dir=folder)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(receipt, stream, indent=2)
            stream.write("\n")
        os.replace(name, folder / f"{issue['identifier']}.json")
    finally:
        Path(name).unlink(missing_ok=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Resolve settings without starting Codex or writing a receipt")
    options = parser.parse_args(argv)
    try:
        gate = ROOT / "tmp" / "symphony" / "gate"
        inherited_gate = os.environ.get("HEALTHIE_GATE_ROOT")
        if inherited_gate and Path(inherited_gate).resolve() != gate.resolve():
            raise LaunchError("Scheduler gate does not match the canonical Healthie gate.")
        workspace = Path.cwd().resolve()
        issue, settings = resolve_launch(workspace, gate, os.environ.get("LINEAR_API_KEY"))
        executable = shutil.which("codex")
        if not executable:
            raise LaunchError("Codex executable was not found on PATH.")
        args = codex_argv(executable, settings)
        if options.check:
            print(json.dumps({"issue": issue["identifier"], **asdict(settings)}, indent=2))
            return 0
        write_receipt(ROOT / "tmp" / "symphony" / "launch-settings", issue, settings, workspace)
        # Preserve Symphony's process/stdio protocol. No status text on stdout.
        bridge = ROOT / "script" / "symphony" / "codex_permission_bridge.py"
        os.execv(sys.executable, [sys.executable, str(bridge), str(workspace), *args])
    except (LaunchError, OSError) as error:
        message = str(error) if isinstance(error, LaunchError) else "Launcher could not prepare or start Codex."
        print(f"Healthie launcher: {message}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
