"""Build-replacement continuity through the real transactional SQL ledger."""
import copy
import json
import os
import unittest
import uuid
from datetime import timedelta
from unittest.mock import patch

from test_notifications import FakeAPI, NOW, Sender, finding
from notifier.engine import Engine
from notifier.source import Source
from notifier.store import MySQLStore, StoreError


@unittest.skipUnless(os.environ.get('NOTIFIER_MYSQL_TEST_CONFIG'), 'isolated SQL fixture required')
class ContinuitySQLTests(unittest.TestCase):
    def test_replacement_restart_rollback_and_final_resolution_preserve_alias(self):
        config = json.loads(os.environ['NOTIFIER_MYSQL_TEST_CONFIG'])
        username, password = config.pop('username'), config.pop('password')
        namespace = 'continuity-' + uuid.uuid4().hex
        store = MySQLStore.connect(config, namespace, username, password)
        api, sender = FakeAPI(), Sender()
        policy = dict(namespace=namespace, api_url=api.origin, engagement_ids=[1],
                      all_engagements=False, time_zone='Asia/Yerevan')

        def row(number, build, **changes):
            return finding(number, title='CVE-2026-12345 example-package 1.2.3',
                           vulnerability_ids=[{'vulnerability_id': 'CVE-2026-12345'}],
                           component_name='example-package', component_version='1.2.3',
                           file_path=f'registry.example.com/team/service:{build}@sha256:' + build * 64 + ' (debian 13.7)',
                           **changes)

        def poll(now):
            # A new worker instance each time proves continuity lives in SQL.
            return Engine(Source(api, policy, now=now), store, sender,
                          policy, now=now).run('poll')

        try:
            store.initialize()
            with store.lock():
                api.findings = {1: row(1, 'a')}
                poll(NOW)
                original = {e['channel']: e['payload']['alias'] for e in sender.calls}
                self.assertEqual(set(original), {'slack', 'teams', 'opsgenie'})
                before = copy.deepcopy(store.load_findings())
                sender.calls.clear()
                api.findings[1].update(active=False, mitigated='2026-11-12T09:10:00Z')
                api.findings[2] = row(2, 'b')

                def fail_after_upserts(cursor, rows):
                    cursor.execute('SELECT * FROM missing_continuity_' + uuid.uuid4().hex)

                with patch.object(store, '_insert_events', side_effect=fail_after_upserts):
                    with self.assertRaises(StoreError):
                        poll(NOW + timedelta(minutes=15))
                self.assertEqual(store.load_findings(), before)
                self.assertEqual(sender.calls, [])

                result = poll(NOW + timedelta(minutes=15))
                self.assertEqual(result['lifecycle_events'], 0)
                self.assertEqual(sender.calls, [])
                records = store.load_findings()
                self.assertFalse(records['1']['open'])
                self.assertTrue(records['2']['open'])
                self.assertEqual(records['2']['alert_alias'], original['opsgenie'])

                api.findings[2].update(active=False, mitigated='2026-11-12T09:25:00Z')
                poll(NOW + timedelta(minutes=30))
                self.assertEqual(len(sender.calls), 3)
                self.assertTrue(all(e['kind'] == 'resolved' for e in sender.calls))
                self.assertEqual({e['channel']: e['payload']['alias'] for e in sender.calls}, original)
                sender.calls.clear()

                api.findings[3] = row(3, 'c')
                poll(NOW + timedelta(minutes=45))
                self.assertEqual(len(sender.calls), 3)
                self.assertTrue(all(e['kind'] == 'reopened' for e in sender.calls))
                self.assertTrue(all(e['payload']['alias'] != original[e['channel']] for e in sender.calls))
        finally:
            with store.connection.cursor() as cursor:
                for table in ('notification_deliveries', 'notification_findings',
                              'notification_digests', 'notification_instances'):
                    cursor.execute(f'DELETE FROM {table} WHERE namespace=%s', (namespace,))
            store.connection.commit()
            store.close()
