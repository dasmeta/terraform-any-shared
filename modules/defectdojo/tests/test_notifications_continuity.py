"""Logical Trivy vulnerabilities survive finding-ID and container-build replacement."""
import copy
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'notifier'))
from notifier.engine import Engine
from notifier.source import Source
from test_notifications import FakeAPI, MemoryStore, Sender, NOW, finding, test_row


def vulnerability(id=1, test=10, **changes):
    row = finding(id, test, vulnerability_ids=[{'vulnerability_id': 'CVE-2026-12345'}],
                  component_name='libxml2', component_version='2.14.0',
                  file_path='registry.example.com:5000/team/frontend/main:build1@sha256:' + 'a' * 64 + ' (debian 13.7)')
    row.update(changes)
    return row


def closed(row):
    row.update(active=False, mitigated='2026-11-12T08:00:00Z')


class LogicalIdentityTests(unittest.TestCase):
    def observation(self, row, engagement=1, test=10):
        policy = dict(namespace='example', engagement_ids=[engagement], all_engagements=False)
        return Source(FakeAPI(), policy, now=NOW).observation(row, test, dict(id=engagement, name='Example'))

    def identity(self, row, **scope):
        return self.observation(row, **scope).get('logical_key')

    def test_container_build_package_version_and_known_os_annotation_are_not_identity(self):
        first = self.identity(vulnerability())
        self.assertIsNotNone(first)
        second = vulnerability(2, component_version='2.14.3', title='A different scanner title',
                               file_path='registry.example.com:5000/team/frontend/main:build2@sha256:' + 'b' * 64 + ' (debian 13.8)')
        self.assertEqual(self.identity(second), first)
        self.assertEqual(self.identity(vulnerability(file_path='registry.example.com:5000/team/frontend/main:build3')), first)
        self.assertEqual(self.identity(vulnerability(file_path='registry.example.com:5000/team/frontend/main@sha256:' + 'c' * 64)), first)

    def test_explicit_registry_port_is_preserved_without_requiring_a_dns_suffix(self):
        first = self.identity(vulnerability(file_path='registry:5000/team/frontend:build1 (debian13.7)'))
        second = self.identity(vulnerability(file_path='registry:5000/team/frontend:build2 (debian13.8)'))
        other_port = self.identity(vulnerability(file_path='registry:5001/team/frontend:build2 (debian13.8)'))
        self.assertEqual(first, second)
        self.assertNotEqual(first, other_port)

    def test_cve_set_is_canonical_but_components_repositories_ports_and_scope_are_distinct(self):
        row = vulnerability(vulnerability_ids=[{'vulnerability_id': 'CVE-2026-54321'}, {'vulnerability_id': 'CVE-2026-12345'}])
        first = self.identity(row)
        self.assertIsNotNone(first)
        self.assertEqual(self.identity(dict(row, vulnerability_ids=list(reversed(row['vulnerability_ids'])))), first)
        for change in (dict(component_name='libssl'), dict(vulnerability_ids=[{'vulnerability_id': 'CVE-2026-12345'}]),
                       dict(file_path=row['file_path'].replace('/frontend/', '/backend/')),
                       dict(file_path=row['file_path'].replace(':5000/', ':5001/'))):
            with self.subTest(change=change):
                self.assertNotEqual(self.identity(dict(row, **change)), first)
        self.assertNotEqual(self.identity(dict(row, test=20), test=20), first)
        self.assertNotEqual(self.identity(row, engagement=2), first)

    def test_noncontainer_paths_and_unknown_annotations_remain_exact(self):
        for path in ('/opt/example/requirements:1.txt', 'package/subdir:1', 'registry.example.com/image:v1 (custom target 1)'):
            with self.subTest(path=path):
                first = self.identity(vulnerability(file_path=path))
                self.assertIsNotNone(first)
                self.assertNotEqual(self.identity(vulnerability(file_path=path.replace('1', '2'))), first)
        a = self.identity(vulnerability(file_path='/opt/one/requirements.txt'))
        b = self.identity(vulnerability(file_path='/opt/two/requirements.txt'))
        self.assertNotEqual(a, b)

    def test_missing_or_ambiguous_metadata_does_not_parse_title(self):
        for change in (dict(vulnerability_ids=None), dict(vulnerability_ids=[]),
                       dict(vulnerability_ids=['CVE-2026-12345']),
                       dict(vulnerability_ids=[{'vulnerability_id': 'not a CVE'}]),
                       dict(vulnerability_ids=[{'vulnerability_id': 'CVE-2026-12345'}, None]),
                       dict(component_name=None), dict(component_name=''), dict(component_name=' libxml2'),
                       dict(file_path=None), dict(file_path=''), dict(file_path='target\nother')):
            with self.subTest(change=change):
                self.assertIsNone(self.identity(vulnerability(title='CVE-2026-12345 libxml2 2.14.0', **change)))


class ContinuityTests(unittest.TestCase):
    def setUp(self):
        self.api, self.store, self.sender = FakeAPI(), MemoryStore(), Sender()
        self.policy = dict(namespace='example', api_url=self.api.origin, engagement_ids=[1],
                           all_engagements=False, time_zone='Asia/Yerevan')
        self.api.findings = {1: vulnerability()}
        self.restart()

    def restart(self, channels=('slack', 'teams', 'opsgenie'), store=None):
        if store is not None:
            self.store = store
        self.engine = Engine(Source(self.api, self.policy, now=NOW), self.store,
                             self.sender, self.policy, now=NOW, channels=channels)

    def poll(self):
        return self.engine.run('poll')

    def replace(self, old=1, new=2, **changes):
        closed(self.api.findings[old])
        self.api.findings[new] = vulnerability(new, **changes)

    def test_legacy_same_poll_replacement_retains_open_alias_episode_and_channels(self):
        self.poll()
        original = copy.deepcopy(self.store.records['1'])
        self.store.records['1'].pop('logical_key', None)
        self.store.records['1'].pop('alert_aliases', None)
        queued = [(e['event_key'], e['stream'], e['payload']) for e in self.store.events]
        self.sender.calls.clear()
        self.replace(component_version='2.14.3', file_path='registry.example.com:5000/team/frontend/main:build2@sha256:' + 'b' * 64 + ' (debian 13.8)')
        result = self.poll()
        self.assertEqual(result['lifecycle_events'], 0)
        self.assertEqual(self.sender.calls, [])
        self.assertEqual([(e['event_key'], e['stream'], e['payload']) for e in self.store.events], queued)
        replacement = self.store.records['2']
        for field in ('episode', 'alert_alias', 'alert_channels'):
            self.assertEqual(replacement[field], original[field])
        self.assertFalse(self.store.records['1']['open'])
        self.assertTrue(replacement['open'])
        self.assertIsNotNone(replacement.get('logical_key'))
        self.restart()
        self.poll()
        self.assertEqual(self.sender.calls, [])
        self.replace(2, 3, component_version='2.14.5')
        self.poll()
        self.assertEqual(self.sender.calls, [])
        self.assertEqual(self.store.records['3']['alert_alias'], original['alert_alias'])

    def test_initial_duplicate_members_create_one_alert_and_only_last_closure_resolves(self):
        self.api.findings[2] = vulnerability(2)
        self.assertEqual(self.poll()['lifecycle_events'], 1)
        self.assertEqual(len(self.sender.calls), 3)
        alias = self.sender.calls[0]['payload']['alias']
        self.sender.calls.clear()
        closed(self.api.findings[1])
        self.assertEqual(self.poll()['lifecycle_events'], 0)
        self.assertEqual(self.sender.calls, [])
        closed(self.api.findings[2])
        self.assertEqual(self.poll()['lifecycle_events'], 1)
        self.assertEqual([e['kind'] for e in self.sender.calls], ['resolved'] * 3)
        self.assertTrue(all(e['payload']['alias'] == alias for e in self.sender.calls))
        self.sender.calls.clear()
        self.api.findings[3] = vulnerability(3)
        self.restart()
        self.assertEqual(self.poll()['lifecycle_events'], 1)
        self.assertEqual([e['kind'] for e in self.sender.calls], ['reopened'] * 3)
        self.assertTrue(all(e['payload']['alias'] != alias for e in self.sender.calls))
        self.assertEqual(self.store.records['3']['episode'], 2)
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)

    def test_unknown_prior_open_member_prevents_group_closure(self):
        self.api.findings[2] = vulnerability(2)
        self.poll()
        self.sender.calls.clear()
        del self.api.findings[1]
        closed(self.api.findings[2])
        result = self.poll()
        self.assertEqual(result['blocked_engagement_ids'], [1])
        self.assertEqual(result['lifecycle_events'], 0)
        self.assertEqual(self.sender.calls, [])
        self.assertTrue(self.store.records['1']['open'])
        self.assertFalse(self.store.records['2']['open'])

    def test_excluded_member_stays_open_until_last_member_and_suppression_is_truthful(self):
        self.api.findings[2] = vulnerability(2)
        self.poll()
        self.sender.calls.clear()
        self.api.findings[1]['false_p'] = True
        self.poll()
        self.assertEqual(self.sender.calls, [])
        self.api.findings[2]['severity'] = 'High'
        self.poll()
        self.assertEqual([e['kind'] for e in self.sender.calls], ['suppressed'] * 3)
        # Among non-fixed reasons, oldest discovery date then finding ID
        # deterministically selects the representative for this episode.
        self.assertTrue(all(e['payload']['finding']['reason'] == 'false_positive' for e in self.sender.calls))

    def test_mixed_final_closure_never_reports_suppression_as_a_fix(self):
        for change, reason in ((dict(severity='High'), 'severity_changed'),
                               (dict(false_p=True), 'false_positive'), (dict(active=False), 'inactive')):
            with self.subTest(reason=reason):
                self.setUp()
                self.api.findings[2] = vulnerability(2)
                self.poll()
                self.sender.calls.clear()
                closed(self.api.findings[1])
                self.api.findings[2].update(change)
                self.assertEqual(self.poll()['lifecycle_events'], 1)
                self.assertEqual([e['kind'] for e in self.sender.calls], ['suppressed'] * 3)
                self.assertTrue(all(e['payload']['finding']['reason'] == reason for e in self.sender.calls))

    def test_staggered_suppression_is_retained_only_for_its_active_episode(self):
        self.api.findings[2] = vulnerability(2)
        self.poll()
        self.sender.calls.clear()
        self.api.findings[1]['false_p'] = True
        self.poll()
        self.assertEqual(self.sender.calls, [])
        closed(self.api.findings[2])
        self.poll()
        self.assertEqual([e['kind'] for e in self.sender.calls], ['suppressed'] * 3)
        self.assertTrue(all(e['payload']['finding']['reason'] == 'false_positive' for e in self.sender.calls))
        self.sender.calls.clear()
        self.api.findings[3] = vulnerability(3)
        self.poll()
        self.assertEqual([e['kind'] for e in self.sender.calls], ['reopened'] * 3)
        self.sender.calls.clear()
        closed(self.api.findings[3])
        self.poll()
        self.assertEqual([e['kind'] for e in self.sender.calls], ['resolved'] * 3)

    def test_in_place_identity_changes_never_split_ownership_of_active_aliases(self):
        for change in (dict(component_name='libssl'), dict(vulnerability_ids=None),
                       dict(file_path='registry.example.com:5000/team/changed/main:build2')):
            with self.subTest(change=change):
                self.setUp()
                self.api.findings = {1: finding(), 2: finding(2)}
                self.poll()
                aliases = {record['alert_alias'] for record in self.store.records.values()}
                self.api.findings = {1: vulnerability(), 2: vulnerability(2)}
                self.poll()
                self.sender.calls.clear()
                closed(self.api.findings[1])
                self.api.findings[2].update(change)
                self.assertEqual(self.poll()['lifecycle_events'], 0)
                self.assertEqual(self.sender.calls, [])
                self.restart()
                closed(self.api.findings[2])
                self.poll()
                self.assertEqual([e['kind'] for e in self.sender.calls], ['resolved'] * 6)
                self.assertEqual({e['payload']['alias'] for e in self.sender.calls}, aliases)

    def test_unrelated_components_repositories_and_noncontainer_paths_do_not_merge(self):
        for changes in (dict(component_name='libssl'),
                        dict(file_path='registry.example.com:5000/team/backend/main:build1'),
                        dict(file_path='/opt/example/requirements.txt')):
            with self.subTest(changes=changes):
                self.setUp()
                self.poll()
                self.sender.calls.clear()
                self.replace(**changes)
                self.assertEqual(self.poll()['lifecycle_events'], 2)
                self.assertEqual(sorted(e['kind'] for e in self.sender.calls), ['new'] * 3 + ['resolved'] * 3)

    def test_missing_metadata_keeps_existing_per_finding_behavior(self):
        self.api.findings = {1: finding()}
        self.poll()
        self.sender.calls.clear()
        closed(self.api.findings[1])
        self.api.findings[2] = finding(2)
        self.assertEqual(self.poll()['lifecycle_events'], 2)
        self.assertEqual(sorted(e['kind'] for e in self.sender.calls), ['new'] * 3 + ['resolved'] * 3)

    def test_group_upgrade_keeps_every_previous_alias_and_disabled_participant_until_final_closure(self):
        self.api.findings = {1: finding()}
        self.restart(('slack', 'opsgenie'))
        self.poll()
        first_alias = self.store.records['1']['alert_alias']
        self.api.findings[2] = finding(2)
        self.restart(('teams',))
        self.poll()
        second_alias = self.store.records['2']['alert_alias']
        self.assertNotEqual(first_alias, second_alias)
        self.api.findings = {1: vulnerability(), 2: vulnerability(2)}
        closed(self.api.findings[1])
        self.sender.calls.clear()
        self.restart(('slack',))
        self.assertEqual(self.poll()['lifecycle_events'], 0)
        self.assertEqual(self.sender.calls, [])
        aliases = {entry['alias']: entry['channels'] for entry in self.store.records['2']['alert_aliases']}
        self.assertEqual(aliases, {first_alias: ['slack', 'opsgenie'], second_alias: ['teams']})
        self.restart(('slack',))
        closed(self.api.findings[2])
        self.assertEqual(self.poll()['lifecycle_events'], 2)
        self.assertEqual([e['channel'] for e in self.sender.calls], ['slack', 'slack'])
        closures = [e for e in self.store.events if e['kind'] == 'resolved']
        self.assertEqual({e['payload']['alias'] for e in closures}, {first_alias, second_alias})
        self.assertEqual({(e['payload']['alias'], e['channel']) for e in closures},
                         {(first_alias, 'slack'), (first_alias, 'opsgenie'), (second_alias, 'slack'), (second_alias, 'teams')})
        self.sender.calls.clear()
        self.restart()
        self.poll()
        self.assertEqual({(e['payload']['alias'], e['channel']) for e in self.sender.calls},
                         {(first_alias, 'opsgenie'), (second_alias, 'teams')})

    def test_repeated_build_chain_keeps_scalar_membership_and_only_writes_changed_records(self):
        writes = []
        snapshot = self.store.snapshot
        def capture(records, events):
            writes.append(set(records))
            snapshot(records, events)
        self.store.snapshot = capture
        self.poll()
        first = self.store.records['1']
        self.assertIs(first.get('alert_member'), True)
        self.assertNotIn('alert_members', first)
        initial_size = len(json.dumps(first))
        for new in range(2, 25):
            self.replace(new - 1, new)
            self.poll()
            self.assertEqual(writes[-1], {str(new - 1), str(new)})
            for record in self.store.records.values():
                self.assertIs(record.get('alert_member'), True)
                self.assertNotIn('alert_members', record)
                self.assertLessEqual(len(json.dumps(record)), initial_size + 80)
        self.assertEqual(len(self.store.events), 3)
        closed(self.api.findings[24])
        self.poll()
        self.sender.calls.clear()
        self.api.findings[25] = vulnerability(25)
        self.poll()
        self.assertTrue(self.store.records['25']['alert_member'])
        self.assertTrue(all(not record['alert_member'] for key, record in self.store.records.items() if key != '25'))
        self.sender.calls.clear()
        closed(self.api.findings[25])
        self.poll()
        self.assertEqual([event['kind'] for event in self.sender.calls], ['resolved'] * 3)

    def test_replacement_does_not_inflate_persisted_digest_transitions(self):
        self.poll()
        self.replace()
        self.poll()
        self.sender.calls.clear()
        self.engine.run('digest')
        summary = next(e['payload']['summary'] for e in self.sender.calls if e['channel'] == 'slack')
        self.assertEqual((summary['open_count'], summary['new_count'], summary['fixed_count']), (1, 1, 0))


if __name__ == '__main__':
    unittest.main()
