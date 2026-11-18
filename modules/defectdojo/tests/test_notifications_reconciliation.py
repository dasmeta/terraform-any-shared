"""Bounded tracked-ID reconciliation and independent durable delivery progress."""
import copy
import unittest
from datetime import timedelta

from test_notifications import FakeAPI, MemoryStore, NOW, Sender, finding, test_row
from notifier.engine import Engine
from notifier.source import Source, SourceError


class BudgetFakeAPI(FakeAPI):
    """Enforce the production request ceiling without HTTP or real sends."""

    def get(self, path, params=None, missing_ok=False):
        if len(self.calls) >= 2000:
            raise SourceError('source_budget')
        return super().get(path, params, missing_ok)


class LargeCaseStore(MemoryStore):
    """Linear fixture queue operations; each seeded finding has its own stream."""

    def enqueue(self, events):
        keys = {event['event_key'] for event in self.events}
        for event in events:
            if event['event_key'] not in keys:
                keys.add(event['event_key'])
                self.events.append(dict(copy.deepcopy(event), id=len(self.events) + 1,
                                        attempts=0, request_id=None, status='pending'))

    def pending(self, now, limit=100, channels=None):
        pending, streams = [], set()
        for event in self.events:
            stream = event['channel'], event['stream']
            if event['status'] != 'pending' or stream in streams:
                continue
            streams.add(stream)
            if (event.get('next_attempt', now) <= now
                    and (channels is None or event['channel'] in channels)):
                pending.append(copy.deepcopy(event))
                if len(pending) == limit:
                    break
        return pending


class ReconciliationTests(unittest.TestCase):
    def setUp(self):
        self.api, self.store, self.sender = BudgetFakeAPI(), LargeCaseStore(), Sender()
        self.policy = dict(namespace='example', api_url=self.api.origin, engagement_ids=[1],
                           all_engagements=False, time_zone='Asia/Yerevan')
        self.source = Source(self.api, self.policy, now=NOW)
        self.engine = Engine(self.source, self.store, self.sender, self.policy, now=NOW)

    def seed_open(self, rows):
        for row in rows:
            record = self.source.observation(row, row['test'], self.api.engagements[1])
            self.store.records[str(row['id'])] = dict(record, episode=1)

    def batches(self):
        return [params for path, params in self.api.calls if path == 'findings/' and 'id' in params]

    def test_2100_closed_findings_commit_all_closures_below_request_budget(self):
        self.seed_open(finding(i) for i in range(1, 2101))
        self.api.findings = {i: finding(i, active=False, mitigated='2026-11-12T08:00:00Z')
                             for i in range(1, 2101)}
        try:
            result = self.engine.run('poll')
        except SourceError as error:
            self.fail(f'mass closure made no durable progress: {error}; requests={len(self.api.calls)}')
        self.assertEqual(result['lifecycle_events'], 2100)
        self.assertEqual(len(self.store.records), 2100)
        self.assertTrue(all(not row['open'] and row['reason'] == 'fixed'
                            for row in self.store.records.values()))
        self.assertEqual(len(self.store.events), 6300)
        self.assertTrue(all(event['kind'] == 'resolved' for event in self.store.events))
        self.assertEqual(result['delivered'], 300)
        self.assertEqual(len(self.batches()), 42)
        self.assertEqual(len(self.api.calls), 49)
        self.assertLess(len(self.api.calls), 2000)
        self.assertFalse(any(path.startswith('findings/') and path != 'findings/'
                             for path, _ in self.api.calls))

    def test_batches_are_test_scoped_and_include_all_statuses_and_severities(self):
        self.api.tests[20] = test_row(20)
        self.seed_open([finding(1), finding(2), finding(3, test=20), finding(4, test=20)])
        self.api.findings = {
            1: finding(1, active=False, mitigated='2026-11-12T08:00:00Z'),
            2: finding(2, severity='High'),
            3: finding(3, test=20, active=False, duplicate=True),
            4: finding(4, test=20, active=False),
        }
        self.engine.run('poll')
        self.assertEqual([(params['test'], params['id']) for params in self.batches()],
                         [(10, '1,2'), (20, '3,4')])
        for params in self.batches():
            self.assertEqual(params['o'], 'id')
            self.assertLessEqual(len(params['id'].split(',')), 50)
            self.assertNotIn('severity', params)
            self.assertNotIn('active', params)
            self.assertNotIn('id__in', params)
        self.assertEqual([self.store.records[str(i)]['reason'] for i in range(1, 5)],
                         ['fixed', 'severity_changed', 'duplicate', 'inactive'])

    def test_missing_and_moved_ids_stay_unknown_without_individual_fallback(self):
        self.seed_open([finding(1), finding(2)])
        self.api.findings = {2: finding(2, test=999), 3: finding(3)}
        result = self.engine.run('poll')
        self.assertEqual(result['blocked_engagement_ids'], [1])
        self.assertTrue(self.store.records['1']['open'])
        self.assertTrue(self.store.records['2']['open'])
        self.assertEqual([event['payload']['finding_id'] for event in self.store.events], [3, 3, 3])
        self.assertEqual(len(self.batches()), 1)
        self.assertFalse(any(path.startswith('findings/') and path != 'findings/'
                             for path, _ in self.api.calls))

    def corrupt_batch(self, corrupt):
        self.seed_open([finding(1)])
        self.api.findings = {1: finding(1, active=False, mitigated='2026-11-12T08:00:00Z')}
        get = self.api.get
        def wrapped(path, params=None, missing_ok=False):
            result = get(path, params, missing_ok)
            if path == 'findings/' and 'id' in params:
                corrupt(result)
            return result
        self.api.get = wrapped

    def test_ignored_id_filter_returning_unrequested_row_fails_closed(self):
        self.corrupt_batch(lambda page: page['results'][0].update(id=999))
        with self.assertRaises(SourceError):
            self.engine.run('poll')
        self.assertTrue(self.store.records['1']['open'])
        self.assertEqual(self.store.events, [])

    def test_ignored_test_filter_returning_moved_row_fails_closed(self):
        self.corrupt_batch(lambda page: page['results'][0].update(test=999))
        with self.assertRaises(SourceError):
            self.engine.run('poll')
        self.assertTrue(self.store.records['1']['open'])
        self.assertEqual(self.store.events, [])

    def test_incomplete_batch_fails_closed(self):
        self.corrupt_batch(lambda page: page.update(results=[]))
        with self.assertRaises(SourceError):
            self.engine.run('poll')
        self.assertTrue(self.store.records['1']['open'])
        self.assertEqual(self.store.events, [])

    def test_batch_cannot_claim_more_rows_than_requested(self):
        self.corrupt_batch(lambda page: page.update(count=2, next='next'))
        with self.assertRaises(SourceError):
            self.engine.run('poll')
        self.assertTrue(self.store.records['1']['open'])
        self.assertEqual(self.store.events, [])

    def test_duplicate_batch_identity_fails_closed(self):
        self.seed_open([finding(1), finding(2)])
        self.api.findings = {i: finding(i, active=False, mitigated='2026-11-12T08:00:00Z')
                             for i in (1, 2)}
        get = self.api.get
        def repeated(path, params=None, missing_ok=False):
            page = get(path, params, missing_ok)
            if path == 'findings/' and 'id' in params:
                page['results'][1] = copy.deepcopy(page['results'][0])
            return page
        self.api.get = repeated
        with self.assertRaisesRegex(SourceError, '^invalid_list_identity$'):
            self.engine.run('poll')
        self.assertTrue(all(row['open'] for row in self.store.records.values()))
        self.assertEqual(self.store.events, [])

    def test_paginated_batch_collects_complete_filtered_inventory(self):
        self.seed_open(finding(i) for i in (1, 2, 3))
        self.api.findings = {i: finding(i, active=False, mitigated='2026-11-12T08:00:00Z')
                             for i in (1, 2, 3)}
        get, requests = self.api.get, []
        def paginated(path, params=None, missing_ok=False):
            page = get(path, params, missing_ok)
            if path == 'findings/' and 'id' in params:
                requests.append(copy.deepcopy(params))
                page['results'] = page['results'][:2]
                page['next'] = 'next' if params['offset'] == 0 else None
            return page
        self.api.get = paginated
        result = self.engine.run('poll')
        self.assertEqual(result['lifecycle_events'], 3)
        self.assertEqual([params['offset'] for params in requests], [0, 2])
        self.assertTrue(all(params['test'] == 10 and params['id'] == '1,2,3'
                            for params in requests))
        self.assertTrue(all(not row['open'] for row in self.store.records.values()))

    def test_source_failure_drains_committed_queue_without_saving_partial_observations(self):
        self.sender.failed = {'teams'}
        self.engine.run('poll')
        prior_records = copy.deepcopy(self.store.records)
        prior_events = {event['event_key'] for event in self.store.events}
        self.sender.failed.clear()
        self.sender.calls.clear()
        self.engine.now += timedelta(minutes=5)
        self.api.findings[2] = finding(2)
        self.api.tests[20] = test_row(20)
        get = self.api.get
        def incomplete_second_test(path, params=None, missing_ok=False):
            page = get(path, params, missing_ok)
            if path == 'findings/' and params['test'] == 20:
                page.update(count=1, results=[], next=None)
            return page
        self.api.get = incomplete_second_test
        with self.assertRaisesRegex(SourceError, '^incomplete_inventory$') as caught:
            self.engine.run('poll')
        self.assertEqual(self.store.records, prior_records)
        self.assertEqual({event['event_key'] for event in self.store.events}, prior_events)
        self.assertEqual(self.store.calls, ['snapshot'])
        self.assertEqual([event['channel'] for event in self.sender.calls], ['teams'])
        self.assertTrue(all(event['status'] == 'delivered' for event in self.store.events))
        self.assertEqual(caught.exception.details, {'delivered': 1, 'deferred': 0})

    def test_source_error_code_and_details_survive_queue_dispatch(self):
        class FailedSource:
            def collect(self, previous):
                raise SourceError('source_budget', {'blocked_engagement_ids': [1]})
        self.engine.source = FailedSource()
        with self.assertRaisesRegex(SourceError, '^source_budget$') as caught:
            self.engine.run('digest')
        self.assertEqual(caught.exception.details,
                         {'blocked_engagement_ids': [1], 'delivered': 0, 'deferred': 0})

    def test_database_read_failure_does_not_enter_source_error_dispatch_path(self):
        self.sender.failed = {'teams'}
        self.engine.run('poll')
        self.sender.failed.clear()
        self.sender.calls.clear()
        self.engine.now += timedelta(minutes=5)
        def unavailable():
            raise RuntimeError('database unavailable')
        self.store.load_findings = unavailable
        with self.assertRaisesRegex(RuntimeError, '^database unavailable$'):
            self.engine.run('poll')
        self.assertEqual(self.sender.calls, [])
        self.assertEqual(len([event for event in self.store.events if event['status'] == 'pending']), 1)


if __name__ == '__main__':
    unittest.main()
