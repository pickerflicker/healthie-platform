"""Verify real Codex launch configuration without threads, turns or model calls."""
import json
import selectors
import shutil
import subprocess
import time

from codex_launcher import EFFORTS, MODEL, Settings, codex_argv


def probe(settings):
    executable = shutil.which("codex")
    if not executable:
        raise RuntimeError("Codex is not available on PATH")
    process = subprocess.Popen(codex_argv(executable, settings), stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)

    def request(identifier, method, params):
        process.stdin.write(json.dumps({"id": identifier, "method": method, "params": params}) + "\n")
        process.stdin.flush()
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if not selector.select(max(0, deadline - time.monotonic())):
                break
            line = process.stdout.readline()
            if not line:
                raise RuntimeError("Codex exited before configuration verification")
            message = json.loads(line)
            if message.get("id") == identifier:
                if "error" in message:
                    raise RuntimeError(f"Codex rejected {method}")
                return message["result"]
        raise RuntimeError(f"Codex timed out during {method}")

    try:
        request(1, "initialize", {"clientInfo": {"name": "healthie-launch-settings-check", "version": "1"},
                                  "capabilities": {"experimentalApi": True}})
        process.stdin.write('{"method":"initialized"}\n')
        process.stdin.flush()
        config = request(2, "config/read", {"includeLayers": False})["config"]
        expected = {"model": MODEL, "model_reasoning_effort": settings.effort,
                    "service_tier": "fast" if settings.fast else "default"}
        for key, value in expected.items():
            # Some versions normalize Fast to the wire-level Priority name.
            actual = config.get(key)
            if key == "service_tier" and value == "fast" and actual == "priority":
                continue
            if actual != value:
                raise RuntimeError(f"Codex effective {key} does not match the requested setting")
        agents = config.get("agents") or {}
        if agents.get("default_subagent_model") != MODEL or agents.get("default_subagent_reasoning_effort") != settings.effort:
            raise RuntimeError("Codex did not preserve QA model/effort defaults")
        if agents.get("max_concurrent_threads_per_session") != 1 or agents.get("max_depth") != 1:
            raise RuntimeError("Codex did not preserve the Developer + QA limits")
        print(f"PASS: {MODEL}, effort={settings.effort}, fast={settings.fast}; QA defaults match")
    finally:
        selector.close()
        process.terminate()
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        for stream in (process.stdin, process.stdout):
            stream.close()


if __name__ == "__main__":
    for effort in EFFORTS:
        for fast in (False, True):
            probe(Settings(effort=effort, fast=fast))
