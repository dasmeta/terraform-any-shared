"""Namespace-scoped MySQL state and transactional delivery outbox.

No connection is reconnected: losing a session also loses its named lock, so callers
must fail the job and let a fresh process acquire a new lock.
"""
from contextlib import contextmanager
from datetime import date, datetime, timezone
import hashlib
import json
import re
import uuid

UTC = timezone.utc


class StoreError(Exception):
    """Safe storage error; database messages can contain connection secrets."""


def _time(value):
    if not isinstance(value, datetime) or value.tzinfo is None or value.utcoffset() is None:
        raise StoreError("invalid_datetime")
    return value.astimezone(UTC).replace(tzinfo=None)


def _aware(value):
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


def _json(value):
    try:
        return json.dumps(value, ensure_ascii=False, allow_nan=False, separators=(",", ":"))
    except (ValueError, TypeError):
        raise StoreError("invalid_json") from None


def _decoded(value):
    return json.loads(value) if isinstance(value, (str, bytes, bytearray)) else value


class MySQLStore:
    def __init__(self, connection, namespace):
        if not isinstance(namespace, str) or not re.fullmatch(r"[A-Za-z0-9_.:-]{1,64}", namespace):
            raise StoreError("invalid_namespace")
        self.connection = connection
        self.namespace = namespace
        self._lock_name = "dd:" + hashlib.sha256(namespace.encode()).hexdigest()[:61]
        self._locked = False

    @classmethod
    def connect(cls, policy_mysql, namespace, username, password):
        # Lazy import keeps offline engine and adapter tests dependency-free.
        try:
            import pymysql
            kwargs = dict(host=policy_mysql["host"], port=int(policy_mysql.get("port", 3306)),
                          database=policy_mysql["database"], user=username, password=password,
                          charset="utf8mb4", autocommit=True, connect_timeout=10,
                          read_timeout=20, write_timeout=20)
            if policy_mysql.get("tls", True):
                kwargs.update(ssl_verify_cert=True, ssl_verify_identity=True)
                if policy_mysql.get("ca_file"):
                    kwargs["ssl_ca"] = policy_mysql["ca_file"]
            else:
                kwargs["ssl_disabled"] = True
            connection = pymysql.connect(**kwargs)
        except Exception:
            raise StoreError("connect_failed") from None
        try:
            if policy_mysql.get("tls", True):
                # Explicit verification options require TLS in the pinned driver.
                # Also verify the negotiated session, protecting against future
                # driver behavior changes that might permit plaintext fallback.
                with connection.cursor() as cursor:
                    cursor.execute("SHOW SESSION STATUS LIKE 'Ssl_cipher'")
                    row = cursor.fetchone()
                if row is None or not isinstance(row[1], str) or not row[1]:
                    raise StoreError("tls_not_negotiated")
            return cls(connection, namespace)
        except Exception as error:
            try:
                connection.close()
            except Exception:
                pass
            if isinstance(error, StoreError):
                raise
            raise StoreError("connect_failed") from None

    def initialize(self):
        statements = (
            """CREATE TABLE IF NOT EXISTS notification_instances (
                namespace VARCHAR(64) NOT NULL PRIMARY KEY,
                generation CHAR(32) NOT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin""",
            """CREATE TABLE IF NOT EXISTS notification_findings (
                namespace VARCHAR(64) NOT NULL, finding_id BIGINT NOT NULL,
                record JSON NOT NULL, updated_at DATETIME(6) NOT NULL,
                PRIMARY KEY (namespace, finding_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin""",
            """CREATE TABLE IF NOT EXISTS notification_deliveries (
                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                namespace VARCHAR(64) NOT NULL, event_key CHAR(64) NOT NULL,
                channel VARCHAR(16) NOT NULL, stream VARCHAR(160) NOT NULL,
                kind VARCHAR(16) NOT NULL, payload JSON NOT NULL,
                created_at DATETIME(6) NOT NULL, next_attempt DATETIME(6) NOT NULL,
                attempts INT NOT NULL DEFAULT 0, request_id VARCHAR(128) NULL,
                remote_id VARCHAR(128) NULL, status VARCHAR(16) NOT NULL DEFAULT 'pending',
                error_code VARCHAR(64) NULL, UNIQUE KEY event_identity (namespace, event_key),
                KEY ready_events (namespace, status, next_attempt),
                KEY stream_order (namespace, channel, stream, id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin""",
            """CREATE TABLE IF NOT EXISTS notification_digests (
                namespace VARCHAR(64) NOT NULL, local_date DATE NOT NULL,
                engagement_id BIGINT NOT NULL, created_at DATETIME(6) NOT NULL,
                PRIMARY KEY (namespace, local_date, engagement_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin""",
        )
        try:
            with self.connection.cursor() as cursor:
                for statement in statements:
                    cursor.execute(statement)
                cursor.execute("INSERT IGNORE INTO notification_instances (namespace,generation) VALUES (%s,%s)",
                               (self.namespace, uuid.uuid4().hex))
        except Exception:
            raise StoreError("initialize_failed") from None

    def generation(self):
        """Read an identity retained with this namespace's database state."""
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT generation FROM notification_instances WHERE namespace=%s", (self.namespace,))
                row = cursor.fetchone()
            if row is None or not isinstance(row[0], str) or not re.fullmatch(r"[a-f0-9]{32}", row[0]):
                raise StoreError("state_generation_missing")
            return row[0]
        except StoreError:
            raise
        except Exception:
            raise StoreError("generation_read_failed") from None

    @contextmanager
    def lock(self):
        if self._locked:
            raise StoreError("lock_already_held")
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT GET_LOCK(%s, 0)", (self._lock_name,))
                row = cursor.fetchone()
            acquired = row is not None and row[0] == 1
        except Exception:
            raise StoreError("lock_failed") from None
        if not acquired:
            raise StoreError("lock_busy")
        self._locked = True
        try:
            yield self
        finally:
            self._locked = False
            try:
                with self.connection.cursor() as cursor:
                    cursor.execute("SELECT RELEASE_LOCK(%s)", (self._lock_name,))
                    row = cursor.fetchone()
                if row is None or row[0] != 1:
                    raise StoreError("lock_release_failed")
            except Exception:
                raise StoreError("lock_release_failed") from None

    @contextmanager
    def _transaction(self):
        try:
            self.connection.begin()
            with self.connection.cursor() as cursor:
                yield cursor
            self.connection.commit()
        except Exception:
            try:
                self.connection.rollback()
            except Exception:
                pass
            raise StoreError("transaction_failed") from None

    def load_findings(self):
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT finding_id, record FROM notification_findings WHERE namespace = %s",
                               (self.namespace,))
                return {str(key): _decoded(record) for key, record in cursor.fetchall()}
        except Exception:
            raise StoreError("read_failed") from None

    def _events(self, events):
        rows = []
        for event in events:
            if (not re.fullmatch(r"[a-f0-9]{64}", event["event_key"])
                    or event["channel"] not in ("slack", "teams", "opsgenie")
                    or event["kind"] not in ("new", "reopened", "resolved", "suppressed", "digest")
                    or not isinstance(event["stream"], str) or not 1 <= len(event["stream"]) <= 160):
                raise StoreError("invalid_event")
            created = _time(event["created_at"])
            rows.append((self.namespace, event["event_key"], event["channel"], event["stream"],
                         event["kind"], _json(event["payload"]), created, created))
        return rows

    @staticmethod
    def _insert_events(cursor, rows):
        for row in rows:
            cursor.execute("""INSERT IGNORE INTO notification_deliveries
                (namespace,event_key,channel,stream,kind,payload,created_at,next_attempt)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)""", row)

    def snapshot(self, records, events):
        rows = self._events(events)
        now = _time(datetime.now(UTC))
        finding_rows = []
        for key, record in records.items():
            try:
                finding_id = int(key)
                if finding_id <= 0 or finding_id > 9223372036854775807:
                    raise ValueError()
            except (ValueError, TypeError):
                raise StoreError("invalid_finding_id") from None
            finding_rows.append((self.namespace, finding_id, _json(record), now))
        with self._transaction() as cursor:
            for row in finding_rows:
                cursor.execute("""INSERT INTO notification_findings (namespace,finding_id,record,updated_at)
                    VALUES (%s,%s,%s,%s) ON DUPLICATE KEY UPDATE
                    record = VALUES(record), updated_at = VALUES(updated_at)""", row)
            self._insert_events(cursor, rows)

    def enqueue(self, events):
        self.snapshot({}, events)

    def enqueue_digest(self, local_date, engagement_id, events):
        if not isinstance(local_date, date) or isinstance(local_date, datetime):
            raise StoreError("invalid_digest_date")
        if isinstance(engagement_id, bool) or not isinstance(engagement_id, int) or not 0 < engagement_id <= 9223372036854775807:
            raise StoreError("invalid_engagement_id")
        rows = self._events(events)
        with self._transaction() as cursor:
            cursor.execute("""INSERT IGNORE INTO notification_digests
                (namespace,local_date,engagement_id,created_at) VALUES (%s,%s,%s,%s)""",
                           (self.namespace, local_date, engagement_id, _time(datetime.now(UTC))))
            inserted = cursor.rowcount == 1
            if inserted:
                self._insert_events(cursor, rows)
        return inserted

    def pending(self, now, limit=100, channels=None):
        current = _time(now)
        if isinstance(limit, bool) or not isinstance(limit, int) or not 1 <= limit <= 10000:
            raise StoreError("invalid_limit")
        channel_sql, channel_params = "", ()
        if channels is not None:
            if (not isinstance(channels, tuple) or not channels
                    or any(channel not in ("slack", "teams", "opsgenie") for channel in channels)
                    or len(set(channels)) != len(channels)):
                raise StoreError("invalid_channels")
            channel_sql = " AND d.channel IN (" + ",".join("%s" for _ in channels) + ")"
            channel_params = channels
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("""SELECT d.id,d.event_key,d.channel,d.stream,d.kind,d.payload,
                    d.created_at,d.attempts,d.request_id,d.next_attempt
                    FROM notification_deliveries d
                    WHERE d.namespace = %s AND d.status = 'pending' AND d.next_attempt <= %s
                    """ + channel_sql + """
                    AND NOT EXISTS (SELECT 1 FROM notification_deliveries prior
                        WHERE prior.namespace = d.namespace AND prior.channel = d.channel
                        AND prior.stream = d.stream AND prior.status = 'pending' AND prior.id < d.id)
                    ORDER BY d.id LIMIT %s""", (self.namespace, current) + channel_params + (limit,))
                keys = ("id", "event_key", "channel", "stream", "kind", "payload", "created_at", "attempts", "request_id", "next_attempt")
                result = [dict(zip(keys, row)) for row in cursor.fetchall()]
                for row in result:
                    row["payload"] = _decoded(row["payload"])
                    row["created_at"] = _aware(row["created_at"])
                    row["next_attempt"] = _aware(row["next_attempt"])
                return result
        except Exception:
            raise StoreError("read_failed") from None

    def delivered(self, id, remote_id=None):
        if remote_id is not None and (not isinstance(remote_id, str) or len(remote_id) > 128):
            raise StoreError("invalid_remote_id")
        with self._transaction() as cursor:
            cursor.execute("""UPDATE notification_deliveries SET status = 'delivered',
                remote_id = %s, request_id = NULL, error_code = NULL
                WHERE namespace = %s AND id = %s""", (remote_id, self.namespace, id))

    def defer(self, id, next_attempt, error_code, request_id=None, clear_request=False):
        when = _time(next_attempt)
        if not isinstance(error_code, str) or not re.fullmatch(r"[A-Za-z0-9_:.-]{1,64}", error_code):
            raise StoreError("invalid_error_code")
        if request_id is not None and (not isinstance(request_id, str) or not 1 <= len(request_id) <= 128):
            raise StoreError("invalid_request_id")
        receipt_sql, receipt_params = "", ()
        if clear_request:
            receipt_sql = ", request_id = NULL"
        elif request_id is not None:
            receipt_sql, receipt_params = ", request_id = %s", (request_id,)
        with self._transaction() as cursor:
            cursor.execute("""UPDATE notification_deliveries SET attempts = attempts + 1,
                next_attempt = %s, error_code = %s""" + receipt_sql + " WHERE namespace = %s AND id = %s AND status = 'pending'",
                           (when, error_code) + receipt_params + (self.namespace, id))

    def recent_events(self, since):
        start = _time(since)
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("""SELECT event_key,payload,kind,created_at FROM notification_deliveries
                    WHERE namespace = %s AND created_at >= %s ORDER BY id""", (self.namespace, start))
                result, seen = [], set()
                for key, payload, kind, created in cursor.fetchall():
                    payload = _decoded(payload)
                    identity = payload.get("transition_id", key)
                    if identity in seen:
                        continue
                    seen.add(identity)
                    result.append(dict(event_key=key, payload=payload, kind=kind, created_at=_aware(created)))
                return result
        except Exception:
            raise StoreError("read_failed") from None

    def close(self):
        try:
            self.connection.close()
        except Exception:
            raise StoreError("close_failed") from None
