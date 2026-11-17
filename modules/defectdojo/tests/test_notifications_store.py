"""Outbox tests. Set NOTIFIER_MYSQL_TEST_CONFIG to JSON for real MySQL tests."""
import importlib
import json
import os
from pathlib import Path
import sys
import unittest
from datetime import date, datetime, timedelta, timezone
from unittest.mock import MagicMock, Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "notifier"))
UTC = timezone.utc
NOW = datetime(2026, 11, 12, 9, tzinfo=UTC)


def event(number=1, channel="slack", stream="finding:1", kind="new"):
    return dict(event_key=f"{number:064x}", channel=channel, stream=stream,
                kind=kind, payload={"transition_id": "transition:1", "finding_id": 1,
                                   "engagement_id": 2, "text": "critical"}, created_at=NOW)


class StoreTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.import_module("notifier.store")
        self.connection = MagicMock()
        self.cursor = self.connection.cursor.return_value.__enter__.return_value
        self.store = self.mod.MySQLStore(self.connection, "test")

    def test_generation_is_loaded_and_invalid_state_fails_closed(self):
        self.assertTrue(callable(getattr(self.store, "generation", None)), "database generation is not implemented")
        self.cursor.fetchone.return_value = ("a" * 32,)
        self.assertEqual(self.store.generation(), "a" * 32)
        self.assertEqual(self.cursor.execute.call_args.args[1], ("test",))
        for row in (None, ("not-a-generation",), ("b" * 33,)):
            self.cursor.fetchone.return_value = row
            with self.assertRaises(self.mod.StoreError): self.store.generation()

    def test_lock_is_zero_wait_released_and_never_reconnects(self):
        self.cursor.fetchone.return_value = (1,)
        with self.store.lock():
            pass
        calls = self.cursor.execute.call_args_list
        self.assertIn("GET_LOCK", calls[0].args[0])
        self.assertIn(", 0)", calls[0].args[0])
        self.assertIn("RELEASE_LOCK", calls[1].args[0])
        self.connection.ping.assert_not_called()

    def test_busy_lock_fails_safely(self):
        self.cursor.fetchone.return_value = (0,)
        with self.assertRaisesRegex(self.mod.StoreError, "lock_busy"):
            with self.store.lock():
                self.fail("lock acquired")

    def test_snapshot_commits_records_and_events_together(self):
        self.store.snapshot({"1": {"id": 1}}, [event()])
        self.connection.begin.assert_called_once()
        self.connection.commit.assert_called_once()
        sql = [call.args[0] for call in self.cursor.execute.call_args_list]
        self.assertTrue(any("notification_findings" in x for x in sql))
        self.assertTrue(any("INSERT IGNORE INTO notification_deliveries" in x for x in sql))
        params = self.cursor.execute.call_args_list[-1].args[1]
        self.assertIn(NOW.replace(tzinfo=None), params)

    def test_snapshot_rolls_back_without_exposing_database_error(self):
        self.cursor.execute.side_effect = RuntimeError("mysql-password=do-not-log")
        with self.assertRaises(self.mod.StoreError) as caught:
            self.store.snapshot({"1": {"id": 1}}, [event()])
        self.assertNotIn("do-not-log", repr(caught.exception))
        self.connection.rollback.assert_called_once()
        self.connection.commit.assert_not_called()

    def test_pending_query_enforces_fifo_even_when_earlier_event_not_ready(self):
        self.cursor.fetchall.return_value = [(9, "a" * 64, "opsgenie", "f:1", "new",
            '{"text":"x"}', NOW.replace(tzinfo=None), 2, "receipt", NOW.replace(tzinfo=None))]
        rows = self.store.pending(NOW)
        query = self.cursor.execute.call_args.args[0]
        self.assertIn("NOT EXISTS", query)
        self.assertIn("prior.id < d.id", query)
        self.assertNotIn("prior.next_attempt", query)
        self.assertEqual(rows[0]["payload"], {"text": "x"})
        self.assertEqual(rows[0]["created_at"], NOW)
        self.assertEqual(rows[0]["request_id"], "receipt")

    def test_pending_filters_selected_channels_before_limit_with_parameters(self):
        self.cursor.fetchall.return_value = []
        self.store.pending(NOW, limit=1, channels=("slack", "opsgenie"))
        query, params = self.cursor.execute.call_args.args
        self.assertIn("d.channel IN (%s,%s)", query)
        self.assertLess(query.index("d.channel IN"), query.index("LIMIT"))
        self.assertEqual(params, ("test", NOW.replace(tzinfo=None), "slack", "opsgenie", 1))

    def test_pending_rejects_invalid_channel_selection_without_query(self):
        for channels in ((), ("email",), ("slack", "slack"), ["slack"], "slack"):
            with self.subTest(channels=channels), self.assertRaises(self.mod.StoreError):
                self.store.pending(NOW, channels=channels)
        self.cursor.execute.assert_not_called()

    def test_receipt_retained_by_default_and_explicitly_cleared(self):
        self.store.defer(1, NOW, "pending")
        query = self.cursor.execute.call_args.args[0]
        self.assertNotIn("request_id =", query)
        self.store.defer(1, NOW, "receipt_failed", clear_request=True)
        self.assertIn("request_id = NULL", self.cursor.execute.call_args.args[0])
        self.store.defer(1, NOW, "pending", request_id="abc")
        self.assertIn("abc", self.cursor.execute.call_args.args[1])

    def test_daily_manifest_makes_changed_snapshot_a_noop(self):
        self.cursor.rowcount = 0
        self.assertFalse(self.store.enqueue_digest(date(2026, 11, 12), 2, [event(kind="digest")]))
        self.assertEqual(len(self.cursor.execute.call_args_list), 1)
        self.connection.commit.assert_called_once()

    def test_recent_events_deduplicates_transition_across_channels(self):
        self.cursor.fetchall.return_value = [
            ("a" * 64, '{"transition_id":"t1","engagement_id":2}', "new", NOW.replace(tzinfo=None)),
            ("b" * 64, '{"transition_id":"t1","engagement_id":2}', "new", NOW.replace(tzinfo=None)),
            ("c" * 64, '{"transition_id":"t2","engagement_id":2}', "resolved", NOW.replace(tzinfo=None)),
        ]
        rows = self.store.recent_events(NOW - timedelta(days=1))
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[1]["kind"], "resolved")
        self.assertEqual(rows[0]["created_at"].tzinfo, UTC)

    def test_rejects_naive_time_before_mutating(self):
        item = event()
        item["created_at"] = NOW.replace(tzinfo=None)
        with self.assertRaises(self.mod.StoreError):
            self.store.enqueue([item])
        self.connection.begin.assert_not_called()

    def test_connect_verifies_tls_without_schema_bootstrap(self):
        driver = MagicMock()
        driver.connect.return_value.cursor.return_value.__enter__.return_value.fetchone.return_value = ("Ssl_cipher", "TLS_AES_256_GCM_SHA384")
        with patch.dict(sys.modules, {"pymysql": driver}):
            store = self.mod.MySQLStore.connect({"host": "db", "port": 3306,
                "database": "notifications", "tls": True, "ca_file": "/ca.pem"},
                "test", "user", "password")
        kwargs = driver.connect.call_args.kwargs
        self.assertTrue(kwargs["ssl_verify_cert"])
        self.assertTrue(kwargs["ssl_verify_identity"])
        self.assertEqual(kwargs["ssl_ca"], "/ca.pem")
        self.assertGreater(kwargs["connect_timeout"], 0)
        query = driver.connect.return_value.cursor.return_value.__enter__.return_value.execute.call_args.args[0]
        self.assertIn("Ssl_cipher", query)
        self.assertNotIn("CREATE", query)
        store.close()

    def test_default_tls_uses_system_trust_and_rejects_plaintext_session(self):
        driver = MagicMock()
        driver.connect.return_value.cursor.return_value.__enter__.return_value.fetchone.return_value = ("Ssl_cipher", "")
        with patch.dict(sys.modules, {"pymysql": driver}):
            with self.assertRaisesRegex(self.mod.StoreError, "tls_not_negotiated"):
                self.mod.MySQLStore.connect({"host": "db", "database": "notifications"},
                                           "test", "user", "password")
        kwargs = driver.connect.call_args.kwargs
        self.assertTrue(kwargs["ssl_verify_cert"])
        self.assertTrue(kwargs["ssl_verify_identity"])
        self.assertNotIn("ssl_ca", kwargs)
        driver.connect.return_value.close.assert_called_once()

    def test_schema_uses_binary_collation_for_namespace_and_stream_identity(self):
        self.store.initialize()
        statements = [call.args[0] for call in self.cursor.execute.call_args_list if call.args[0].startswith("CREATE TABLE")]
        self.assertEqual(len(statements), 4)
        for statement in statements:
            self.assertIn("COLLATE=utf8mb4_bin", statement)


@unittest.skipUnless(os.environ.get("NOTIFIER_MYSQL_TEST_CONFIG"), "real MySQL test configuration not set")
class MySQLIntegrationTests(unittest.TestCase):
    """Uses an existing dedicated MySQL test database; never source/provider APIs."""
    def test_selected_queue_progresses_past_disabled_rows_without_mutating_them(self):
        import uuid
        from notifier.store import MySQLStore
        config = json.loads(os.environ["NOTIFIER_MYSQL_TEST_CONFIG"])
        namespace = "optional-" + uuid.uuid4().hex
        username, password = config.pop("username"), config.pop("password")
        store = MySQLStore.connect(config, namespace, username, password)
        try:
            store.initialize()
            with store.lock():
                # Every row has its own ready stream, so LIMIT cannot incidentally
                # hide this starvation bug through per-stream FIFO deduplication.
                disabled = [event(i, channel="teams" if i % 2 else "opsgenie", stream=f"old:{i}")
                            for i in range(1, 151)]
                store.enqueue(disabled + [event(151, stream="active:151"), event(152, stream="active:152")])
                first = store.pending(NOW, limit=1, channels=("slack",))
                self.assertEqual([row["event_key"] for row in first], [f"{151:064x}"])
                store.delivered(first[0]["id"])
                second = store.pending(NOW, limit=1, channels=("slack",))
                self.assertEqual([row["event_key"] for row in second], [f"{152:064x}"])
                store.delivered(second[0]["id"])
                self.assertEqual(store.pending(NOW, channels=("slack",)), [])
                with store.connection.cursor() as cursor:
                    cursor.execute("""SELECT status,attempts,request_id,error_code FROM notification_deliveries
                        WHERE namespace=%s AND channel IN (%s,%s) ORDER BY id""", (namespace, "teams", "opsgenie"))
                    self.assertEqual(cursor.fetchall(), (("pending", 0, None, None),) * 150)
                resumed = store.pending(NOW, limit=200, channels=("teams", "opsgenie"))
                self.assertEqual(len(resumed), 150)
        finally:
            with store.connection.cursor() as cursor:
                for table in ("notification_deliveries", "notification_findings", "notification_digests", "notification_instances"):
                    cursor.execute(f"DELETE FROM {table} WHERE namespace=%s", (namespace,))
            store.connection.commit()
            store.close()

    def test_atomicity_fifo_digest_and_namespace_lock(self):
        import uuid
        from notifier.store import MySQLStore, StoreError
        config = json.loads(os.environ["NOTIFIER_MYSQL_TEST_CONFIG"])
        namespace = "integration-" + uuid.uuid4().hex
        username, password = config.pop("username"), config.pop("password")
        store = MySQLStore.connect(config, namespace, username, password)
        other = MySQLStore.connect(config, namespace, username, password)
        try:
            store.initialize()
            generation = store.generation()
            self.assertRegex(generation, r"^[a-f0-9]{32}$")
            store.initialize()
            self.assertEqual(store.generation(), generation)
            with store.connection.cursor() as cursor:
                cursor.execute("DELETE FROM notification_instances WHERE namespace=%s", (namespace,))
            store.initialize()
            self.assertNotEqual(store.generation(), generation)
            with store.lock():
                with self.assertRaises(StoreError):
                    with other.lock():
                        pass
                first, second = event(), event(2, kind="resolved")
                store.snapshot({"1": {"id": 1}}, [first, second])
                store.snapshot({"1": {"id": 1}}, [first])
                self.assertEqual(store.load_findings(), {"1": {"id": 1}})
                pending = store.pending(NOW)
                self.assertEqual(len(pending), 1)
                self.assertEqual(pending[0]["kind"], "new")
                store.defer(pending[0]["id"], NOW + timedelta(hours=1), "pending", request_id="receipt")
                self.assertEqual(store.pending(NOW), [])
                receipt = store.pending(NOW + timedelta(hours=1))[0]
                self.assertEqual(receipt["request_id"], "receipt")
                store.defer(receipt["id"], NOW, "receipt_failed", clear_request=True)
                self.assertIsNone(store.pending(NOW)[0]["request_id"])
                store.delivered(receipt["id"], "remote")
                self.assertEqual(store.pending(NOW)[0]["kind"], "resolved")
                # Independent channels progress while a failed destination retries.
                store.enqueue([event(7, channel="teams"), event(8, channel="opsgenie")])
                ready = store.pending(NOW)
                for row in ready:
                    if row["channel"] != "opsgenie":
                        store.delivered(row["id"])
                    else:
                        store.defer(row["id"], NOW + timedelta(minutes=1), "rate_limited")
                self.assertEqual(store.pending(NOW), [])
                self.assertEqual([row["channel"] for row in store.pending(NOW + timedelta(minutes=1))], ["opsgenie"])
                digest = event(3, stream="digest:2", kind="digest")
                self.assertTrue(store.enqueue_digest(NOW.date(), 2, [digest]))
                self.assertFalse(store.enqueue_digest(NOW.date(), 2, [event(4, stream="digest:2", kind="digest")]))
                before = store.load_findings()
                # Force a real server SQL error after the record upsert: rollback
                # must restore the old record and not append an outbox event.
                def server_failure(cursor, rows):
                    cursor.execute("SELECT * FROM missing_table_" + uuid.uuid4().hex)
                with patch.object(store, "_insert_events", side_effect=server_failure):
                    with self.assertRaises(StoreError):
                        store.snapshot({"1": {"id": 99}}, [event(5)])
                self.assertEqual(store.load_findings(), before)
        finally:
            with store.connection.cursor() as cursor:
                for table in ("notification_deliveries", "notification_findings", "notification_digests", "notification_instances"):
                    cursor.execute(f"DELETE FROM {table} WHERE namespace = %s", (namespace,))
            store.connection.commit()
            other.close()
            store.close()


if __name__ == "__main__":
    unittest.main()
