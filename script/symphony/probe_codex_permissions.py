"""Exercise the installed sandbox through the bridge, with no model/Linear calls."""
import json
import os
from pathlib import Path
import selectors
import shutil
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def run_probe():
    with tempfile.TemporaryDirectory(prefix='permission-probe-', dir=ROOT / 'tmp') as folder:
        root = Path(folder).resolve()
        workspace = root / 'PIC-999999'
        workspace.mkdir()
        origin = root / 'origin.git'
        subprocess.run(['git', 'init', '--bare', '-q', str(origin)], check=True)
        subprocess.run(['git', 'init', '-q', str(workspace)], check=True)
        subprocess.run(['git', '-C', str(workspace), 'remote', 'add', 'origin', str(origin)], check=True)
        (workspace / 'baseline.txt').write_text('fixture baseline\n')
        for args in (['add', 'baseline.txt'], ['commit', '-qm', 'Fixture baseline'],
                     ['push', '-q', 'origin', 'HEAD:main']):
            subprocess.run(['git', '-C', str(workspace), '-c', 'user.name=Permission Probe',
                            '-c', 'user.email=probe@example.invalid', *args], check=True)
        for protected in ('.codex', '.agents', '.aws'):
            (workspace / protected).mkdir()
        outside = root / 'sibling'
        outside.mkdir()
        # Only the fixture root differs from production. Validate it using the
        # same checkout checks, then run the exact production transport/policy.
        driver = ('from codex_permission_bridge import validate_workspace, relay; '
                  'from pathlib import Path; import sys; '
                  'w=validate_workspace(Path(sys.argv[1]), Path(sys.argv[1]).parent); '
                  'sys.exit(relay(w, sys.argv[2:]))')
        process = subprocess.Popen([sys.executable, '-c', driver, str(workspace),
                                    shutil.which('codex') or 'codex', 'app-server'],
                                   cwd=HERE, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.DEVNULL, bufsize=0)
        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        pending = b''

        def rpc(identifier, method, params):
            nonlocal pending
            process.stdin.write(json.dumps({'id': identifier, 'method': method, 'params': params}).encode() + b'\n')
            process.stdin.flush()
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                while b'\n' in pending:
                    line, pending = pending.split(b'\n', 1)
                    response = json.loads(line)
                    if response.get('id') == identifier:
                        if 'error' in response:
                            raise RuntimeError(f'{method}: {response["error"]}')
                        return response['result']
                if selector.select(timeout=0.2):
                    data = os.read(process.stdout.fileno(), 65536)
                    if not data:
                        raise RuntimeError('Permission bridge exited during probe')
                    pending += data
            raise RuntimeError(f'{method} timed out')

        def execute(identifier, code):
            return rpc(identifier, 'command/exec', {'command': [sys.executable, '-c', code],
                'cwd': str(workspace), 'sandboxPolicy': {'type': 'workspaceWrite',
                'writableRoots': [], 'networkAccess': False}})

        try:
            rpc(1, 'initialize', {'clientInfo': {'name': 'healthie-permission-probe', 'version': '1'}})
            process.stdin.write(b'{"method":"initialized"}\n')
            process.stdin.flush()
            result = execute(2, '''from pathlib import Path
import subprocess
Path('probe.txt').write_text('sandbox Git validation\\n')
def git(*args):
    subprocess.run(['git', '-c', 'user.name=Permission Probe', '-c', 'user.email=probe@example.invalid', *args], check=True, capture_output=True)
git('switch', '-c', 'permission-probe')
git('add', 'probe.txt')
git('commit', '-m', 'Disposable permission probe')
git('fetch', 'origin', 'main')
assert Path('.git/FETCH_HEAD').read_text()
print('PASS: Git branch, add, commit and fetch')
''')
            if result['exitCode'] != 0:
                raise RuntimeError(f'Git probe failed: {result}')
            print(result['stdout'].strip())
            targets = [str(workspace / d / 'probe') for d in ('.codex', '.agents', '.aws')] + [str(outside / 'probe')]
            result = execute(3, f'''from pathlib import Path
for target in {targets!r}:
    try:
        Path(target).write_text('must be denied')
    except PermissionError:
        continue
    raise AssertionError('Unexpected write access: ' + target)
print('PASS: .codex, .agents, .aws and sibling writes denied')
''')
            if result['exitCode'] != 0:
                raise RuntimeError(f'Boundary probe failed: {result}')
            print(result['stdout'].strip())
        finally:
            selector.close()
            process.terminate()
            try:
                process.wait(timeout=8)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            process.stdin.close()
            process.stdout.close()


if __name__ == '__main__':
    run_probe()
