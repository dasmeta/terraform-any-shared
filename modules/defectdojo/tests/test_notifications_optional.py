"""Optional destinations select future events and pause disabled delivery queues."""
import copy
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from contextlib import redirect_stdout
from datetime import timedelta
from unittest.mock import patch

from test_notifications import FakeAPI, MemoryStore, NOW, Sender, finding
from notifier import config
from notifier.__main__ import main
from notifier.engine import Engine
from notifier.source import Source


class OptionalCredentialTests(unittest.TestCase):
    def test_missing_empty_and_whitespace_destinations_are_disabled(self):
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, 'slack-url').write_text('https://hooks.example.com/slack\n')
            Path(directory, 'teams-url').write_text(' \t\r\n ')
            Path(directory, 'opsgenie-key').write_text('')
            secrets, channels = config.channel_secrets(directory)
        self.assertEqual(channels, ('slack',))
        self.assertEqual(secrets, {'slack-url': 'https://hooks.example.com/slack'})

    def test_single_mixed_and_all_destinations_use_canonical_order(self):
        values = {'slack-url': 'https://hooks.example.com/slack',
                  'teams-url': 'https://workflow.example.com/teams',
                  'opsgenie-key': 'integration-key'}
        for names, expected in [(['teams-url'], ('teams',)),
                                (['opsgenie-key'], ('opsgenie',)),
                                (['teams-url', 'slack-url'], ('slack', 'teams')),
                                (list(values), ('slack', 'teams', 'opsgenie'))]:
            with self.subTest(channels=expected), tempfile.TemporaryDirectory() as directory:
                for name in names:
                    Path(directory, name).write_text(values[name])
                secrets, channels = config.channel_secrets(directory)
                self.assertEqual(channels, expected)
                self.assertEqual(secrets, {name: values[name] for name in names})

    def test_no_destination_fails_safely(self):
        for values in ({}, {'opsgenie-summary-key': 'obsolete-key'}):
            with self.subTest(names=list(values)), tempfile.TemporaryDirectory() as directory:
                for name, value in values.items():
                    Path(directory, name).write_text(value)
                with self.assertRaises(config.ConfigError) as caught:
                    config.channel_secrets(directory)
                for value in values.values():
                    self.assertNotIn(value, str(caught.exception))

    def test_opsgenie_needs_only_one_key_and_never_reads_deprecated_summary_file(self):
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, 'opsgenie-key').write_text('integration-key\n')
            self.assertEqual(config.channel_secrets(directory),
                             ({'opsgenie-key': 'integration-key'}, ('opsgenie',)))
            # A directory in place of the deprecated file would fail if opened.
            Path(directory, 'opsgenie-summary-key').mkdir()
            self.assertEqual(config.channel_secrets(directory),
                             ({'opsgenie-key': 'integration-key'}, ('opsgenie',)))
            Path(directory, 'opsgenie-summary-key').rmdir()
            Path(directory, 'opsgenie-summary-key').write_bytes(b'obsolete\x00\xff')
            self.assertEqual(config.channel_secrets(directory),
                             ({'opsgenie-key': 'integration-key'}, ('opsgenie',)))
            with self.assertRaisesRegex(config.ConfigError, 'invalid_secret_name'):
                config.secret(directory, 'opsgenie-summary-key')

    def test_nonempty_malformed_files_never_fall_back_to_disabled(self):
        invalid = [('teams-url', b'http://workflow.example.com/secret'),
                   ('teams-url', b'https://user:SECRET@workflow.example.com/path'),
                   ('teams-url', b'https://workflow.example.com:bad/path'),
                   ('teams-url', b'https://workflow.example.com/path#SECRET'),
                   ('teams-url', b' https://workflow.example.com/SECRET '),
                   ('teams-url', b'\x00'), ('teams-url', b'\xff'),
                   ('teams-url', b' ' * 65537),
                   ('teams-url', b'https://workflow.example.com/' + b'a' * 65537),
                   ('opsgenie-key', b'bad SECRET'), ('opsgenie-key', b'bad\nSECRET'),
                   ('opsgenie-key', b'bad\x00SECRET')]
        for name, value in invalid:
            with self.subTest(name=name, value_prefix=value[:30]), tempfile.TemporaryDirectory() as directory:
                Path(directory, 'slack-url').write_text('https://hooks.example.com/slack')
                Path(directory, name).write_bytes(value)
                with self.assertRaises(config.ConfigError) as caught:
                    config.channel_secrets(directory)
                self.assertNotIn('SECRET', str(caught.exception))
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, 'slack-url').write_text('https://hooks.example.com/slack')
            Path(directory, 'teams-url').mkdir()
            with self.assertRaises(config.ConfigError):
                config.channel_secrets(directory)
            with patch.object(Path, 'open', side_effect=PermissionError('SECRET')):
                with self.assertRaises(config.ConfigError) as caught:
                    config.channel_secrets(directory)
            self.assertNotIn('SECRET', str(caught.exception))

    def test_api_and_mysql_credentials_remain_required(self):
        with tempfile.TemporaryDirectory() as directory:
            for name in ('api-token', 'mysql-user', 'mysql-password'):
                with self.subTest(name=name), self.assertRaises(config.ConfigError):
                    config.secret(directory, name)


class OptionalEngineTests(unittest.TestCase):
    def setUp(self):
        self.api, self.store, self.sender = FakeAPI(), MemoryStore(), Sender()
        self.policy = dict(namespace='example', api_url=self.api.origin, engagement_ids=[1],
                           all_engagements=False, time_zone='Asia/Yerevan')

    def engine(self, channels, now=NOW):
        return Engine(Source(self.api, self.policy, now=now), self.store, self.sender,
                      self.policy, now=now, channels=channels)

    def test_slack_only_six_then_one_dedup_and_daily_digest(self):
        engine = self.engine(('slack',))
        self.api.findings = {i: finding(i) for i in range(1, 7)}
        self.assertEqual(engine.run('poll')['lifecycle_events'], 6)
        self.assertEqual(len(self.sender.calls), 6)
        self.assertEqual(engine.run('poll')['lifecycle_events'], 0)
        self.assertEqual(len(self.sender.calls), 6)
        self.api.findings[7] = finding(7)
        self.assertEqual(engine.run('poll')['lifecycle_events'], 1)
        self.assertEqual(len(self.sender.calls), 7)
        self.assertEqual(self.sender.calls[-1]['payload']['finding_id'], 7)
        engine.run('digest')
        self.assertEqual(len(self.sender.calls), 8)
        self.assertEqual(self.sender.calls[-1]['payload']['summary']['new_count'], 7)
        engine.run('digest')
        self.assertEqual(len(self.sender.calls), 8)
        self.assertEqual({event['channel'] for event in self.store.events}, {'slack'})

    def test_teams_only_opsgenie_only_and_mixed_lifecycle_and_digest(self):
        for channels in (('teams',), ('opsgenie',), ('slack', 'opsgenie')):
            with self.subTest(channels=channels):
                self.store, self.sender = MemoryStore(), Sender()
                engine = self.engine(channels)
                self.assertEqual(engine.run('poll')['lifecycle_events'], 1)
                engine.run('digest')
                self.assertEqual([event['channel'] for event in self.sender.calls], list(channels) * 2)

    def test_disabled_pending_is_unchanged_and_resumes_when_reenabled(self):
        self.sender.failed = {'teams', 'opsgenie'}
        self.engine(('slack', 'teams', 'opsgenie')).run('poll')
        queued = copy.deepcopy(self.store.events[1:])
        self.sender.calls.clear()
        self.sender.failed.clear()
        now = NOW + timedelta(hours=1)
        self.assertEqual(self.engine(('slack',), now).run('poll')['delivered'], 0)
        self.assertEqual(self.store.events[1:], queued)
        self.assertEqual(self.sender.calls, [])
        self.assertEqual(self.engine(('slack', 'teams', 'opsgenie'), now).run('poll')['delivered'], 2)
        self.assertEqual([event['channel'] for event in self.sender.calls], ['teams', 'opsgenie'])

    def test_newly_enabled_channel_waits_for_transition_and_next_daily_snapshot(self):
        self.engine(('slack',)).run('poll')
        self.engine(('slack',)).run('digest')
        self.sender.calls.clear()
        engine = self.engine(('slack', 'teams'))
        self.assertEqual(engine.run('poll')['lifecycle_events'], 0)
        engine.run('digest')
        self.assertEqual(self.sender.calls, [])
        self.api.findings[2] = finding(2)
        engine.run('poll')
        self.assertEqual([e['channel'] for e in self.sender.calls], ['slack', 'teams'])
        self.sender.calls.clear()
        self.engine(('slack', 'teams'), NOW + timedelta(days=1)).run('digest')
        self.assertEqual([e['channel'] for e in self.sender.calls], ['slack', 'teams'])

    def test_paused_episode_participants_retain_ordered_closure_until_reenabled(self):
        for pending_open in (False, True):
            for kind in ('resolved', 'suppressed'):
                with self.subTest(pending_open=pending_open, kind=kind):
                    self.api, self.store, self.sender = FakeAPI(), MemoryStore(), Sender()
                    self.sender.failed = {'opsgenie'} if pending_open else set()
                    self.engine(('slack', 'opsgenie')).run('poll')
                    self.sender.calls.clear()
                    self.sender.failed.clear()
                    # Observing the unchanged finding while disabled must retain
                    # the episode's original destinations in durable JSON state.
                    self.engine(('slack',)).run('poll')
                    self.assertEqual(self.store.records['1'].get('alert_channels'), ['slack', 'opsgenie'])
                    if kind == 'resolved':
                        self.api.findings[1].update(active=False, mitigated='2026-11-12T08:00:00Z')
                    else:
                        self.api.findings[1].update(false_p=True)
                    now = NOW + timedelta(hours=1)
                    self.assertEqual(self.engine(('slack',), now).run('poll')['lifecycle_events'], 1)
                    self.assertEqual([e['channel'] for e in self.sender.calls], ['slack'])
                    paused = [e for e in self.store.events if e['channel'] == 'opsgenie']
                    self.assertEqual([e['kind'] for e in paused], ['new', kind])
                    self.assertEqual(paused[-1]['status'], 'pending')
                    self.assertEqual(paused[-1]['attempts'], 0)
                    self.sender.calls.clear()
                    self.engine(('slack', 'opsgenie'), now).run('poll')
                    self.assertEqual([e['kind'] for e in self.sender.calls],
                                     ['new', kind] if pending_open else [kind])
                    self.assertTrue(all(e['channel'] == 'opsgenie' for e in self.sender.calls))
                    self.assertTrue(all(e['status'] == 'delivered' for e in self.store.events))

    def test_legacy_episode_defaults_all_destinations_and_reopening_captures_new_selection(self):
        self.engine(('slack', 'teams', 'opsgenie')).run('poll')
        self.store.records['1'].pop('alert_channels', None)
        self.sender.calls.clear()
        self.api.findings[1].update(active=False, mitigated='2026-11-12T08:00:00Z')
        self.engine(('slack',)).run('poll')
        self.assertEqual(self.store.records['1'].get('alert_channels'), ['slack', 'teams', 'opsgenie'])
        self.assertEqual([e['channel'] for e in self.sender.calls], ['slack'])
        self.assertEqual([e['channel'] for e in self.store.events if e['kind'] == 'resolved'],
                         ['slack', 'teams', 'opsgenie'])
        self.api.findings[1].update(active=True, mitigated=None)
        self.engine(('slack',)).run('poll')
        self.assertEqual(self.store.records['1'].get('alert_channels'), ['slack'])
        self.assertEqual([e['channel'] for e in self.store.events if e['kind'] == 'reopened'], ['slack'])

    def test_empty_unknown_duplicate_and_non_tuple_channels_fail_before_work(self):
        for channels in ((), ('email',), ('slack', 'slack'), ['slack'], None, 'slack'):
            with self.subTest(channels=channels), self.assertRaises(ValueError):
                self.engine(channels)
        self.assertEqual(self.api.calls, [])
        self.assertEqual(self.store.events, [])


class OptionalCLITests(unittest.TestCase):
    def policy(self):
        return dict(namespace='example', api_url='https://dojo.example.com', engagement_ids=[1],
                    all_engagements=False, time_zone='Asia/Yerevan',
                    mysql=dict(host='mysql.example.com', port=3306, database='notifier', tls=True),
                    opsgenie_region='us', priority='P2')

    def test_live_cli_passes_selected_channels_explicitly(self):
        with tempfile.TemporaryDirectory() as directory:
            for name, value in {'slack-url': 'https://hooks.example.com/slack',
                                'api-token': 'api-token', 'mysql-user': 'user',
                                'mysql-password': 'password'}.items():
                Path(directory, name).write_text(value)
            with patch.dict(os.environ, SECRET_DIR=directory), patch('notifier.config.load', return_value=self.policy()), \
                    patch('notifier.__main__.MySQLStore.connect') as connect, \
                    patch('notifier.__main__.Engine') as engine, patch('notifier.delivery.Sender') as sender, \
                    redirect_stdout(io.StringIO()) as output:
                engine.return_value.run.return_value = {'mode': 'poll'}
                self.assertEqual(main(['poll']), 0, output.getvalue())
            self.assertEqual(engine.call_args.kwargs['channels'], ('slack',))
            self.assertEqual(sender.call_args.args[0], {'slack-url': 'https://hooks.example.com/slack'})
            connect.assert_called_once()

    def test_poll_and_digest_always_connect_persist_and_send_under_database_lock(self):
        for mode in ('poll', 'digest'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                for name, value in {'slack-url': 'https://hooks.example.com/slack',
                                    'api-token': 'api-token', 'mysql-user': 'user',
                                    'mysql-password': 'password'}.items():
                    Path(directory, name).write_text(value)
                store, sender, api = MemoryStore(), Sender(), FakeAPI()
                order = []
                from contextlib import contextmanager
                @contextmanager
                def locked():
                    order.append('lock')
                    yield store
                    order.append('unlock')
                store.lock = locked
                store.close = lambda: order.append('close')
                send = sender.send
                def send_under_lock(event):
                    self.assertEqual(order, ['lock'])
                    return send(event)
                sender.send = send_under_lock
                with patch.dict(os.environ, SECRET_DIR=directory), \
                        patch('notifier.config.load', return_value=self.policy()), \
                        patch('notifier.__main__.MySQLStore.connect', return_value=store) as connect, \
                        patch('notifier.__main__.API', return_value=api), \
                        patch('notifier.delivery.Sender', return_value=sender) as make_sender, \
                        redirect_stdout(io.StringIO()) as output:
                    self.assertEqual(main([mode]), 0, output.getvalue())
                result = json.loads(output.getvalue())
                self.assertEqual(result['delivered'], 1)
                self.assertNotIn('dry_run', result)
                self.assertEqual(order, ['lock', 'unlock', 'close'])
                self.assertEqual([event['channel'] for event in sender.calls], ['slack'])
                self.assertIn(f':{store.generation_id}:', sender.calls[0]['payload']['alias'])
                connect.assert_called_once_with(self.policy()['mysql'], 'example', 'user', 'password')
                make_sender.assert_called_once_with({'slack-url': 'https://hooks.example.com/slack'},
                                                    region='us', priority='P2', title_prefix='')
                if mode == 'poll':
                    self.assertEqual(store.calls, ['snapshot'])
                    self.assertEqual(len(store.records), 1)
                else:
                    self.assertEqual(len(store.manifests), 1)

    def test_init_db_only_initializes_under_lock_without_api_or_channel_credentials(self):
        with patch('notifier.config.load', return_value=self.policy()), \
                patch('notifier.config.secret', side_effect=('user', 'password')) as secret, \
                patch('notifier.config.api_token') as token, \
                patch('notifier.config.channel_secrets') as channels, \
                patch('notifier.__main__.MySQLStore.connect') as connect, \
                patch('notifier.__main__.API') as api, \
                patch('notifier.__main__.Engine') as engine, \
                patch('notifier.delivery.Sender') as sender, redirect_stdout(io.StringIO()) as output:
            store = connect.return_value
            def initialize():
                store.lock.return_value.__enter__.assert_called_once()
                store.lock.return_value.__exit__.assert_not_called()
            store.initialize.side_effect = initialize
            self.assertEqual(main(['init-db']), 0, output.getvalue())
            self.assertEqual(json.loads(output.getvalue()), {'mode': 'init-db', 'initialized': True})
        self.assertEqual([call.args[1] for call in secret.call_args_list], ['mysql-user', 'mysql-password'])
        store.initialize.assert_called_once()
        store.close.assert_called_once()
        for external in (token, channels, api, engine, sender):
            external.assert_not_called()


if __name__ == '__main__':
    unittest.main()
