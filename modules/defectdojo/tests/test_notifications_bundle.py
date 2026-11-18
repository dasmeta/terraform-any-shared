"""Module-contained, offline Python runtime and rendered Kubernetes mounts."""
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / 'notifier/vendor'
PACKAGE = ROOT / 'notifier/notifier'


class BundleTests(unittest.TestCase):
    def bundles(self):
        self.assertTrue((VENDOR / 'manifest.json').exists(), 'Pinned dependency bundle is not implemented')
        return json.loads((VENDOR / 'manifest.json').read_text())

    def test_vendored_pure_wheels_have_verified_hashes_and_licenses(self):
        rows = self.bundles()
        self.assertEqual({r['project'] for r in rows}, {'PyMySQL', 'tzdata'})
        for row in rows:
            raw = (VENDOR / row['filename']).read_bytes()
            self.assertTrue(row['filename'].endswith('none-any.whl'))
            self.assertEqual(hashlib.sha256(raw).hexdigest(), row['sha256'])
            self.assertTrue(row['url'].startswith('https://files.pythonhosted.org/'))
            self.assertTrue(row['licenses'])
            self.assertTrue(all((VENDOR / name).is_file() for name in row['licenses']))

    def test_bundled_runtime_imports_without_site_packages_or_system_timezones(self):
        rows = self.bundles()
        paths = [str(ROOT / 'notifier')] + [str(VENDOR / row['filename']) for row in rows]
        script = '''import importlib.metadata, json, pymysql, tzdata
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from notifier.config import validate
from notifier.store import MySQLStore
from notifier.engine import Engine
assert importlib.metadata.version('PyMySQL') == '1.2.4'
assert importlib.metadata.version('tzdata') == '2026.6'
assert datetime(2026,11,12,9,tzinfo=timezone.utc).astimezone(ZoneInfo('Asia/Yerevan')).hour == 13
print('Bundled runtime imports and timezone fallback passed')
'''
        result = subprocess.run([sys.executable, '-S', '-c', script], capture_output=True, text=True,
                                env=dict(os.environ, PYTHONPATH=os.pathsep.join(paths), PYTHONTZPATH='',
                                         PYTHONDONTWRITEBYTECODE='1'))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def render(self, managed=True, source_change=False):
        import test_notifications_chart as chart_tests
        helper = chart_tests.NotificationChartTests()
        helper.setUp()
        self.addCleanup(helper.doCleanups)
        helper.values['managedMysql'] = managed
        helper.values['sourceFiles'] = {p.name: p.read_text() for p in PACKAGE.glob('*.py')}
        if source_change:
            helper.values['sourceFiles']['__init__.py'] += '\n# Deployment checksum test\n'
        helper.values['wheelFiles'] = {row['filename']: base64.b64encode((VENDOR / row['filename']).read_bytes()).decode()
                                      for row in self.bundles()}
        documents = helper.render()
        self.last_values = helper.values
        self.last_manifest = (helper.directory / "rendered.yaml").read_text()
        return documents

    def test_source_and_wheels_mount_into_public_python_runtime(self):
        docs = self.render()
        sources = next(d for d in docs if d['kind'] == 'ConfigMap' and d['metadata']['name'].endswith('-source'))
        dependencies = next(d for d in docs if d['kind'] == 'ConfigMap' and d['metadata']['name'].endswith('-dependencies'))
        self.assertIn('__main__.py', sources['data'])
        self.assertEqual(set(dependencies['binaryData']), {r['filename'] for r in self.bundles()})
        for row in self.bundles():
            self.assertEqual(base64.b64decode(dependencies['binaryData'][row['filename']]),
                             (VENDOR / row['filename']).read_bytes())
        for doc in docs:
            if doc['kind'] != 'CronJob': continue
            pod = doc['spec']['jobTemplate']['spec']['template']['spec']
            container = pod['containers'][0]
            paths = {env['name']: env['value'] for env in container['env']}
            self.assertIn('/app', paths['PYTHONPATH'])
            for row in self.bundles(): self.assertIn('/deps/' + row['filename'], paths['PYTHONPATH'])
            mounts = {m['mountPath']: m for m in container['volumeMounts']}
            self.assertTrue(mounts['/app']['readOnly'])
            self.assertTrue(mounts['/deps']['readOnly'])
            self.assertNotIn('initContainers', pod)
            self.assertNotIn('pip', ' '.join(container['command']))
            source_volume = next(v['configMap'] for v in pod['volumes'] if v.get('name') == 'source')
            self.assertIn({'key': '__main__.py', 'path': 'notifier/__main__.py'}, source_volume['items'])

    def test_managed_mode_initializes_schema_with_same_runtime(self):
        jobs = [d for d in self.render(managed=True) if d['kind'] == 'Job']
        self.assertEqual(len(jobs), 1)
        job = jobs[0]
        self.assertEqual(job['metadata']['annotations']['helm.sh/hook'], 'post-install,post-upgrade')
        pod = job['spec']['template']['spec']
        self.assertEqual(pod['containers'][0]['command'], ['python', '-m', 'notifier', 'init-db'])
        self.assertFalse(pod['automountServiceAccountToken'])
        self.assertIn('/app', next(e['value'] for e in pod['containers'][0]['env'] if e['name'] == 'PYTHONPATH'))
        self.assertFalse([d for d in self.render(managed=False) if d['kind'] == 'Job'])

    def test_configmaps_remain_below_kubernetes_object_limit(self):
        for document in self.render():
            if document['kind'] == 'ConfigMap':
                self.assertLess(len(json.dumps(document).encode()), 1024 * 1024)

    def test_encoded_helm_release_fits_secret_storage_budget(self):
        # Helm stores both supplied values and the rendered manifest in a
        # gzip+base64 release record. Individually valid ConfigMaps can still
        # make that record too large when dependency bytes occur twice.
        import gzip
        self.render()
        templates = [{"name": str(path.relative_to(ROOT / 'charts/notifications')),
                      "data": base64.b64encode(path.read_bytes()).decode()}
                     for path in (ROOT / 'charts/notifications/templates').iterdir() if path.is_file()]
        release = {"name": "example-notifications", "namespace": "example", "version": 1,
                   "config": self.last_values, "manifest": self.last_manifest,
                   "chart": {"metadata": {"name": "defectdojo-notifications", "version": "0.1.0"},
                             "templates": templates},
                   "hooks": [d for d in self.render() if d['kind'] == 'Job']}
        payload = base64.b64encode(gzip.compress(json.dumps(release).encode(), compresslevel=6, mtime=0))
        self.assertLess(len(payload), 1024 * 1024 - 32768,
                        'Bundled runtime leaves insufficient room in Helm release Secret')

    def test_source_change_updates_every_worker_pod_checksum(self):
        def annotations(documents):
            result = {}
            for doc in documents:
                if doc['kind'] == 'CronJob': pod = doc['spec']['jobTemplate']['spec']['template']
                elif doc['kind'] == 'Job': pod = doc['spec']['template']
                else: continue
                result[doc['metadata']['name']] = pod['metadata']['annotations']['checksum/source']
            return result
        before = annotations(self.render())
        after = annotations(self.render(source_change=True))
        self.assertEqual(set(before), set(after))
        self.assertTrue(all(before[name] != after[name] for name in before))


if __name__ == '__main__': unittest.main()
