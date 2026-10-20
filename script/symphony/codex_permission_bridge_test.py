"""Permission boundaries and actual JSONL transport without model calls."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import codex_permission_bridge as bridge


class PermissionBridgeTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.workspace = self.root / 'PIC-278'
        (self.workspace / '.git').mkdir(parents=True)

    def test_only_selected_checkout_and_git_are_writable(self):
        request = {'id': 7, 'method': 'turn/start', 'params': {
            'cwd': str(self.workspace), 'threadId': 'thread',
            'approvalPolicy': 'never', 'input': [{'type': 'text', 'text': 'unchanged'}],
            'sandboxPolicy': {'type': 'workspaceWrite', 'writableRoots': [str(self.root)],
                              'networkAccess': True, 'excludeTmpdirEnvVar': True}}}
        expected = json.loads(json.dumps(request))
        expected['params']['sandboxPolicy']['writableRoots'] = [str(self.workspace), str(self.workspace / '.git')]
        self.assertEqual(json.loads(bridge.adapt(json.dumps(request).encode(), self.workspace)), expected)

    def test_non_policy_messages_are_byte_identical(self):
        for line in (b'{ "id":1, "method":"initialize", "params":{} }\n',
                     b'{"method":"initialized"}\n', b'{"id":3,"result":{"ok":true}}\n'):
            self.assertEqual(bridge.adapt(line, self.workspace), line)

    def test_invalid_policies_and_cwd_fail_closed(self):
        for method in ('turn/start', 'command/exec'):
            for override in ({'cwd': str(self.root)}, {'sandboxPolicy': {'type': 'dangerFullAccess'}},
                             {'sandboxPolicy': None}, {'permissions': 'profile'},
                             {'permissionProfile': 'profile'}):
                params = {'cwd': str(self.workspace), 'sandboxPolicy': {'type': 'workspaceWrite'}}
                params.update(override)
                with self.subTest(method=method, override=override), self.assertRaises(ValueError):
                    bridge.adapt(json.dumps({'method': method, 'params': params}).encode(), self.workspace)
        for sandbox in ('danger-full-access', None):
            with self.assertRaises(ValueError):
                bridge.adapt(json.dumps({'method': 'thread/start', 'params': {
                    'cwd': str(self.workspace), 'sandbox': sandbox}}).encode(), self.workspace)

    def test_checkout_validation_rejects_external_or_linked_git(self):
        self.assertEqual(bridge.validate_workspace(self.workspace, self.root), self.workspace)
        with self.assertRaises(ValueError):
            bridge.validate_workspace(self.workspace, self.root / 'elsewhere')
        (self.workspace / '.git').rmdir()
        (self.root / 'metadata').mkdir()
        (self.workspace / '.git').symlink_to(self.root / 'metadata')
        with self.assertRaises(ValueError):
            bridge.validate_workspace(self.workspace, self.root)
        with self.assertRaises(ValueError):
            bridge.adapt(json.dumps({'method': 'turn/start', 'params': {
                'cwd': str(self.workspace), 'sandboxPolicy': {'type': 'workspaceWrite'}}}).encode(), self.workspace)

    def test_real_pipe_transport_and_backend_exit(self):
        # The backend echoes input byte-for-byte. Relay must preserve unrelated
        # requests and backend output, drain on EOF and return the backend status.
        driver = 'from pathlib import Path; import sys; from codex_permission_bridge import relay; sys.exit(relay(Path(sys.argv[1]), sys.argv[2:]))'
        backend = 'import sys; sys.stdout.buffer.write(sys.stdin.buffer.read()); sys.stdout.flush(); sys.exit(7)'
        request = {'id': 2, 'method': 'command/exec', 'params': {'cwd': str(self.workspace),
                   'command': ['git', 'status'], 'sandboxPolicy': {'type': 'workspaceWrite', 'networkAccess': False}}}
        raw = b'{ "method":"initialized" }\n' + json.dumps(request).encode() + b'\n'
        result = subprocess.run([sys.executable, '-c', driver, str(self.workspace),
                                 sys.executable, '-c', backend], input=raw, capture_output=True,
                                cwd=Path(bridge.__file__).parent, timeout=10)
        self.assertEqual(result.returncode, 7, result.stderr)
        lines = result.stdout.splitlines(keepends=True)
        self.assertEqual(lines[0], raw.splitlines(keepends=True)[0])
        self.assertEqual(json.loads(lines[1])['params']['sandboxPolicy']['writableRoots'],
                         [str(self.workspace), str(self.workspace / '.git')])
        self.assertEqual(result.stderr, b'')

    def test_large_input_and_simultaneous_backend_output_do_not_deadlock(self):
        driver = 'from pathlib import Path; import sys; from codex_permission_bridge import relay; sys.exit(relay(Path(sys.argv[1]), sys.argv[2:]))'
        backend = ('import sys; sys.stdout.buffer.write(b"x" * 1000000); sys.stdout.flush(); '
                   'data=sys.stdin.buffer.read(); sys.stdout.buffer.write(data); sys.stdout.flush()')
        raw = json.dumps({'method': 'initialize', 'params': {'padding': 'y' * 1000000}}).encode() + b'\n'
        result = subprocess.run([sys.executable, '-c', driver, str(self.workspace),
                                 sys.executable, '-c', backend], input=raw, capture_output=True,
                                cwd=Path(bridge.__file__).parent, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, b'x' * 1000000 + raw)


if __name__ == '__main__':
    unittest.main()
