"""Give a selected ticket's Codex turns explicit access to its own Git metadata.

Symphony's explicit turn policy overrides Codex CLI sandbox defaults. This local
JSONL adapter narrows that policy without modifying Symphony or model settings.
Server output is forwarded verbatim; diagnostics belong on stderr.
"""
import json
import os
from pathlib import Path
import re
import selectors
import signal
import subprocess
import sys

WORKSPACE_ROOT = Path("/Users/smh/dev/healthie-platform-workspaces")


def validate_workspace(workspace, root=WORKSPACE_ROOT):
    workspace = Path(workspace)
    if (not workspace.is_absolute() or workspace.resolve() != workspace
            or workspace.parent != root.resolve()
            or not re.fullmatch(r"PIC-\d+", workspace.name)
            or not (workspace / ".git").is_dir()
            or (workspace / ".git").is_symlink()):
        raise ValueError("Expected a normal Git checkout in a Healthie ticket workspace.")
    return workspace


def adapt(line, workspace):
    request = json.loads(line)
    if not isinstance(request, dict):
        raise ValueError("Expected a JSONL request object.")
    method = request.get("method")
    if method not in ("turn/start", "command/exec", "thread/start"):
        return line
    params = request.get("params", {})
    if not isinstance(params, dict) or params.get("cwd") != str(workspace):
        raise ValueError("Codex request does not match the selected workspace.")
    if method == "thread/start":
        if params.get("sandbox") != "workspace-write" or params.get("permissions") is not None:
            raise ValueError("Expected the legacy workspace-write thread sandbox.")
        return line
    policy = params.get("sandboxPolicy")
    if (not isinstance(policy, dict) or policy.get("type") != "workspaceWrite"
            or params.get("permissions") is not None
            or params.get("permissionProfile") is not None):
        raise ValueError("Expected an explicit workspaceWrite turn policy.")
    # Recheck before each turn: do not grant access through a replaced .git link.
    if not (workspace / ".git").is_dir() or (workspace / ".git").is_symlink():
        raise ValueError("Ticket Git metadata is no longer a normal directory.")
    policy["writableRoots"] = [str(workspace), str(workspace / ".git")]
    return json.dumps(request, separators=(",", ":")).encode() + b"\n"


def relay(workspace, command):
    child = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0)
    selector = selectors.DefaultSelector()
    selector.register(sys.stdin.buffer, selectors.EVENT_READ, "input")
    selector.register(child.stdout, selectors.EVENT_READ, "output")
    os.set_blocking(child.stdin.fileno(), False)
    pending = b""
    outgoing = b""
    input_closed = False
    try:
        while selector.get_map():
            for key, _ in selector.select(timeout=1):
                if key.data == "write":
                    try:
                        count = os.write(key.fd, outgoing)
                    except BlockingIOError:
                        continue
                    outgoing = outgoing[count:]
                    if not outgoing:
                        selector.unregister(child.stdin)
                        if input_closed:
                            child.stdin.close()
                    continue
                data = os.read(key.fd, 65536)
                if key.data == "output":
                    if data:
                        sys.stdout.buffer.write(data)
                        sys.stdout.buffer.flush()
                    else:
                        return child.wait(timeout=5)
                elif not data:
                    if pending.strip():
                        raise ValueError("Truncated JSONL request.")
                    selector.unregister(key.fileobj)
                    input_closed = True
                    if not outgoing:
                        child.stdin.close()
                else:
                    pending += data
                    if len(pending) > 8_000_000:
                        raise ValueError("JSONL request exceeds the size limit.")
                    while b"\n" in pending:
                        line, pending = pending.split(b"\n", 1)
                        if not outgoing:
                            selector.register(child.stdin, selectors.EVENT_WRITE, "write")
                        outgoing += adapt(line + b"\n", workspace)
                        if len(outgoing) > 16_000_000:
                            raise ValueError("Pending requests exceed the size limit.")
    finally:
        selector.close()
        if child.poll() is None:
            child.terminate()
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait()
        child.stdin.close()
        child.stdout.close()


def main():
    def stop(signum, _frame):
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        workspace = validate_workspace(sys.argv[1])
        if not sys.argv[2:]:
            raise ValueError("Missing Codex command.")
        return relay(workspace, sys.argv[2:])
    except (ValueError, OSError, subprocess.SubprocessError, IndexError):
        print("Healthie permission bridge: invalid request or Codex transport failure; stopped.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
