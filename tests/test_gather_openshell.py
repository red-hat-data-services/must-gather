"""Run with python3 -m unittest discover -s tests."""
import json
import os
import shutil
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

COLLECTOR = Path(__file__).resolve().parents[1] / 'collection-scripts/gather_openshell.sh'
REDACTOR = COLLECTOR.parent / 'openshell/redact.jq'
JQ = shutil.which('jq')
MOCK = r'''
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
with open(os.environ['CALLS'], 'a') as f:
    f.write(json.dumps([Path(sys.argv[0]).name, *args]) + '\n')
if args[0] == 'api-resources':
    if 'agents.x-k8s.io' in ' '.join(args) and os.environ['AGENT_API'] == 'yes':
        print('sandboxes.agents.x-k8s.io')
    if 'kataconfiguration.openshift.io' in ' '.join(args) and os.environ['KATA_API'] == 'yes':
        print('kataconfigs.kataconfiguration.openshift.io')
elif args[0] == 'logs':
    if '--previous' in args:
        sys.exit('previous container does not exist')
    print('gateway diagnostic https://alice:secret-userinfo@example.com/bot12345:bot-secret/send?token=query-secret&access_token=access-secret')
    print('https://bucket.example/file?X-Amz-Signature=signing-secret')
    print('Authorization: Bearer bearer-secret')
    print('jwt eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.signature')
elif args[0] == 'get':
    resource = args[1]
    if '-o' not in args or args[args.index('-o') + 1] != 'json':
        if os.environ['INSTALLED'] == 'yes':
            print('team-a\nteam-a')
        sys.exit(0)
    if resource == 'runtimeclasses.node.k8s.io':
        if os.environ['FORBIDDEN'] == 'yes':
            sys.exit('Forbidden sensitive-error-token')
        items = [{'kind': 'RuntimeClass', 'metadata': {'name': 'kata'}, 'handler': 'kata'}]
    elif resource == 'kataconfigs.kataconfiguration.openshift.io':
        items = [{'kind': 'KataConfig', 'status': {'readyNodeCount': 0}}]
    else:
        template = {'containers': [{'name': 'openshell-gateway', 'env': [
            {'name': 'PASSWORD', 'value': 'literal-env-secret'},
            {'name': 'TOKEN', 'valueFrom': {'secretKeyRef': {'name': 'ref', 'key': 'token'}}}]}],
            'runtimeClassName': 'kata'}
        items = [{'kind': 'Pod', 'metadata': {'name': 'gateway', 'labels': {'app.kubernetes.io/name': 'openshell'},
                  'annotations': {'kubectl.kubernetes.io/last-applied-configuration': 'last-applied-secret',
                                  'custom': 'opaque-annotation-secret'}},
                  'spec': template},
                 {'kind': 'Pod', 'metadata': {'name': 'workload', 'labels': {
                     'app.kubernetes.io/name': 'openshell', 'openshell.ai/boundary-role': 'workload'}}, 'spec': template},
                 {'kind': 'Pod', 'metadata': {'name': 'supervisor', 'labels': {
                     'app.kubernetes.io/name': 'openshell-supervisor'}}, 'spec': template},
                 {'kind': 'Pod', 'metadata': {'name': 'dashboard', 'labels': {
                     'app.kubernetes.io/name': 'dashboard'}}, 'spec': template}]
        if resource == 'configmaps':
            items = [{'kind': 'ConfigMap', 'data': {'arbitrary.toml': 'opaque-config-secret', 'metadata': 'opaque metadata'},
                      'binaryData': {'key': 'binary-secret'}}]
        elif resource == 'sandboxes.agents.x-k8s.io':
            items = [{'kind': 'Sandbox', 'spec': {'podTemplate': {'spec': template}},
                      'status': {'message': 'RuntimeClass kata not found'}}]
    print(json.dumps({'kind': 'List', 'items': items}))
else:
    sys.exit('Unexpected command')
'''


class OpenShellGatherTest(unittest.TestCase):
    def run_collector(self, *, client='kubectl', installed=True, agent_api=True,
                      kata_api=False, forbidden=False):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        binaries = root / 'bin'
        binaries.mkdir()
        self.assertIsNotNone(JQ, 'Install jq to run collector tests')
        (binaries / 'jq').symlink_to(JQ)
        binary = binaries / client
        binary.write_text(f'#!{sys.executable}\n' + MOCK)
        binary.chmod(0o755)
        env = dict(os.environ, PATH=f'{binaries}:/usr/bin:/bin', KUBECTL=client,
                   SCRIPT_DIR=str(COLLECTOR.parent), CALLS=str(root / 'calls'),
                   INSTALLED='yes' if installed else 'no', AGENT_API='yes' if agent_api else 'no',
                   KATA_API='yes' if kata_api else 'no', FORBIDDEN='yes' if forbidden else 'no',
                   log_collection_args='--since=1h')
        env.pop('OPENSHELL_NAMESPACE', None)
        result = subprocess.run(['/bin/bash', str(COLLECTOR)], cwd=root, env=env,
                                text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = [json.loads(x) for x in (root / 'calls').read_text().splitlines()]
        return root / 'must-gather', calls

    def test_selective_sanitized_collection_with_both_clients(self):
        for client in ['oc', 'kubectl']:
            with self.subTest(client=client):
                bundle, calls = self.run_collector(client=client)
                self.assertFalse(any('inspect' in c or 'secrets' in c for c in calls))
                logs = [c for c in calls if c[1] == 'logs']
                self.assertEqual(len(logs), 2)
                self.assertTrue(all(c[2] == 'gateway' and '--since=1h' in c for c in logs))
                self.assertEqual(sum(c[1:3] == ['get', 'deployments.apps'] and '-n' in c for c in calls), 1)
                output = '\n'.join(p.read_text() for p in bundle.rglob('*') if p.is_file())
                for secret in ['literal-env-secret', 'last-applied-secret', 'opaque-config-secret',
                               'binary-secret', 'secret-userinfo', 'bot-secret', 'query-secret',
                               'access-secret', 'bearer-secret', 'eyJhbGciOiJIUzI1NiJ9',
                               'signing-secret', 'opaque-annotation-secret']:
                    self.assertNotIn(secret, output)
                self.assertIn('gateway diagnostic', output)
                self.assertTrue((bundle / 'namespaces/team-a/openshell/configmaps.json').is_file())
                sandbox = json.loads((bundle / 'namespaces/team-a/openshell/sandboxes.agents.x-k8s.io.json').read_text())
                spec = sandbox['items'][0]['spec']['podTemplate']['spec']
                self.assertEqual(spec['runtimeClassName'], 'kata')
                self.assertNotIn('value', spec['containers'][0]['env'][0])
                self.assertIn('valueFrom', spec['containers'][0]['env'][1])

    def test_optional_agent_api_absent(self):
        bundle, calls = self.run_collector(agent_api=False)
        self.assertFalse(any(c[1:3] == ['get', 'sandboxes.agents.x-k8s.io'] for c in calls))
        self.assertTrue((bundle / 'namespaces/team-a/openshell/pods.json').is_file())

    def test_kata_status_and_runtime_configuration(self):
        bundle, _ = self.run_collector(kata_api=True)
        runtime = bundle / 'openshell/runtime'
        self.assertEqual(json.loads((runtime / 'runtimeclasses.json').read_text())['items'][0]['handler'], 'kata')
        self.assertEqual(json.loads((runtime / 'kataconfigs.json').read_text())['items'][0]['status']['readyNodeCount'], 0)

    def test_forbidden_runtime_does_not_stop_collection_or_write_raw_errors(self):
        bundle, _ = self.run_collector(forbidden=True)
        self.assertFalse((bundle / 'openshell/runtime/runtimeclasses.json').exists())
        self.assertTrue((bundle / 'namespaces/team-a/openshell/events.json').is_file())
        self.assertFalse((bundle / 'openshell/runtime/kataconfigs.json').exists())

    def test_no_installation_is_empty(self):
        bundle, calls = self.run_collector(installed=False)
        self.assertFalse(any(bundle.iterdir()))
        self.assertFalse(any(c[1] == 'logs' for c in calls))

    def test_redacts_log_formats(self):
        lines = ['Authorization: Basic dXNlcjpwYXNz',
                 '{"Authorization":"Bearer json-secret"}',
                 'https://user:pass@host/path?token=abc&access_token=def',
                 'https://api.telegram.org/bot123:abc-DEF/sendMessage',
                 'Bearer opaque-token', 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.signature']
        result = subprocess.run(['jq', '-Rr', '--argjson', 'logs', 'true', '-f', str(REDACTOR)],
                                input='\n'.join(lines), text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        for secret in ['dXNlcjpwYXNz', 'json-secret', 'user:pass', '=abc', '=def',
                       '123:abc-DEF', 'opaque-token', 'eyJhbGci']:
            self.assertNotIn(secret, result.stdout)

    def test_nested_workload_and_debug_container_environment_is_removed(self):
        document = {'spec': {'template': {'spec': {
            key: [{'env': [{'name': 'TOKEN', 'value': key + '-secret'}]}]
            for key in ['containers', 'initContainers', 'ephemeralContainers']
        }}}}
        result = subprocess.run(['jq', '--argjson', 'logs', 'false', '-f', str(REDACTOR)],
                                input=json.dumps(document), text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        spec = json.loads(result.stdout)['spec']['template']['spec']
        for containers in spec.values():
            self.assertEqual(containers[0]['env'], [{'name': 'TOKEN'}])

    def test_invalid_redactors_fail_before_collection(self):
        for content in [None, 'invalid jq syntax!',
                        'if $logs then error("logs broken") else . end',
                        'if $logs then . else error("resources broken") end']:
            with self.subTest(content=content), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                (root / 'openshell').mkdir()
                if content is not None:
                    (root / 'openshell/redact.jq').write_text(content)
                shutil.copy(COLLECTOR.parent / 'common.sh', root / 'common.sh')
                result = subprocess.run(['/bin/bash', str(COLLECTOR)], cwd=root,
                                        env=dict(os.environ, SCRIPT_DIR=str(root), KUBECTL='/does-not-exist'),
                                        text=True, capture_output=True, timeout=10)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('redactor validation failed', result.stderr)
                self.assertNotIn('/does-not-exist', result.stderr)
                self.assertFalse((root / 'must-gather').exists())

    def test_signed_urls_lose_all_query_parameters_and_fragments(self):
        lines = ['https://bucket.example/file?X-Amz-Signature=signing-secret&X-Amz-Credential=credential-secret',
                 'https://host/path?sig=azure-secret&unknown=opaque-secret#fragment-secret',
                 'https://host/other#fragment-only-secret']
        result = subprocess.run([JQ, '-Rr', '--argjson', 'logs', 'true', '-f', str(REDACTOR)],
                                input='\n'.join(lines), text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ['https://bucket.example/file[REDACTED]',
                                                      'https://host/path[REDACTED]',
                                                      'https://host/other[REDACTED]'])

    def test_configmap_payloads_and_nested_annotations_are_omitted(self):
        document = {'kind': 'List', 'items': [
            {'kind': 'ConfigMap', 'metadata': {'name': 'first'},
             'data': {'metadata': 'opaque text', 'env': 'opaque env'},
             'binaryData': {'credentials': 'opaque encoded text'}},
            {'kind': 'ConfigMap', 'metadata': {'name': 'second'}, 'data': {'safe': 'text'}},
            {'kind': 'Deployment', 'metadata': {'name': 'gateway', 'annotations': {'custom': 'opaque-secret'}},
             'spec': {'template': {'metadata': {'annotations': {'custom': 'nested-secret'}}}}},
            {'metadata': 'opaque metadata', 'other': 'diagnostic text'}]}
        result = subprocess.run([JQ, '--argjson', 'logs', 'false', '-f', str(REDACTOR)],
                                input=json.dumps(document), text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        items = json.loads(result.stdout)['items']
        self.assertEqual(len(items), 4)
        for item in items[:2]:
            self.assertNotIn('data', item)
            self.assertNotIn('binaryData', item)
        self.assertEqual(items[2]['metadata'], {'name': 'gateway'})
        self.assertEqual(items[2]['spec']['template']['metadata'], {})
        self.assertEqual(items[3]['metadata'], 'opaque metadata')
        self.assertEqual(items[3]['other'], 'diagnostic text')


if __name__ == '__main__':
    unittest.main()
