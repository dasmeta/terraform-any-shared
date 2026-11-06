"""Offline retention policy and HTTP tests; no production calls."""

import copy
import importlib.util
import json
from pathlib import Path
import sys
import threading
import unittest
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlencode


SOURCE = Path(__file__).resolve().parents[1] / "charts/retention/files/retention.py"
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("retention", SOURCE)
retention = importlib.util.module_from_spec(spec)
spec.loader.exec_module(retention)

NOW = datetime(2026, 11, 4, tzinfo=timezone.utc)
OLD = "2026-08-01T00:00:00Z"
RECENT = "2026-11-03T00:00:00Z"


def sample_test(test_id=1, branch="feature/example", environment="development"):
    return {
        "id": test_id,
        "engagement": 7,
        "title": f"Trivy: app [ref:branch:{branch}] [env:{environment}]",
        "branch_tag": branch,
        "test_type_name": "Trivy Scan",
        "percent_complete": 100,
        "created": "2020-01-01T00:00:00Z",
        "updated": OLD,
    }


class FakeAPI:
    def __init__(self, tests=None):
        self.tests = {t["id"]: copy.deepcopy(t) for t in (tests or [sample_test()])}
        self.histories = {
            key: {"id": key + 100, "test": key, "type": "reimport", "branch_tag": t["branch_tag"], "created": OLD, "modified": OLD}
            for key, t in self.tests.items()
        }
        self.active = 0
        self.total = 10
        self.deleted = []
        self.requests = []
        self.detail_reads = {}
        self.change_on_recheck = False
        self.pending = False
        self.bad_engagement = False
        self.wrong_finding_test = False
        self.wrong_import_test = False
        self.fail_delete = False
        self.bad_next = None
        self.engagements = [{"id": 7, "name": "example"}]

    def get(self, path, params=None, missing_ok=False):
        params = params or {}
        self.requests.append(("GET", path, dict(params)))
        if path in ("tests/", "engagements/"):
            rows = self.engagements if path == "engagements/" else [t for t in self.tests.values() if t["engagement"] == int(params["engagement"])]
            if self.bad_engagement and path == "tests/":
                rows = [dict(rows[0], engagement=999)]
            offset, limit = int(params.get("offset", 0)), int(params.get("limit", 50))
            next_url = None
            if offset + limit < len(rows):
                next_url = "http://api.example.com/api/v2/" + path + "?" + urlencode(dict(params, offset=offset + limit))
            if self.bad_next:
                next_url = self.bad_next
            return {"count": len(rows), "next": next_url, "results": copy.deepcopy(rows[offset:offset + limit])}
        if path.startswith("tests/"):
            key = int(path.strip("/").split("/")[1])
            if key in self.deleted and not self.pending:
                return None
            self.detail_reads[key] = self.detail_reads.get(key, 0) + 1
            result = copy.deepcopy(self.tests[key])
            if self.change_on_recheck and self.detail_reads[key] >= 2:
                result["updated"] = RECENT
            return result
        key = int(params["test"])
        if path == "test_imports/":
            record = copy.deepcopy(self.histories.get(key))
            if record and self.wrong_import_test:
                record["test"] = 999
            return {"count": int(record is not None), "next": None, "results": [record] if record else []}
        if path == "findings/":
            active = params.get("active") in (True, "true")
            count = self.active if active else self.total
            row = {"id": 21, "test": 999 if self.wrong_finding_test else key, "active": active}
            return {"count": count, "next": None, "results": [row] if count else []}
        raise AssertionError(path)

    def check_link(self, link, path, params):
        retention.API("http://api.example.com", "offline-token").check_link(link, path, params)

    def delete(self, path):
        key = int(path.strip("/").split("/")[1])
        self.requests.append(("DELETE", path, {}))
        self.deleted.append(key)
        if self.fail_delete:
            raise retention.RetentionError("ambiguous DELETE")


class PolicyTests(unittest.TestCase):
    def run_worker(self, api=None, **overrides):
        self.api = api or FakeAPI()
        config = {"engagement_ids": [7], "days": 30, "protected_branches": [], "protected_environments": [], "max_tests_per_run": 10}
        config.update(overrides)
        elapsed = [0]

        def sleep(seconds):
            elapsed[0] += seconds

        worker = retention.Worker(self.api, config, now=NOW, sleep=sleep, clock=lambda: elapsed[0])
        return worker.run()

    def test_expired_completed_feature_test_is_deleted_and_confirmed(self):
        result = self.run_worker()
        self.assertEqual(self.api.deleted, [1])
        self.assertEqual(result["confirmed"], 1)

    def test_recent_import_preserves_years_old_test(self):
        api = FakeAPI()
        api.histories[1]["created"] = RECENT
        api.histories[1]["modified"] = RECENT
        self.run_worker(api)
        self.assertEqual(api.deleted, [])

    def test_recent_test_edit_is_preserved(self):
        api = FakeAPI()
        api.tests[1]["updated"] = RECENT
        self.run_worker(api)
        self.assertEqual(api.deleted, [])

    def test_protected_branches_cannot_be_unprotected(self):
        for branch in ["main", "master", "develop", "trunk", "production", "release/v1"]:
            with self.subTest(branch=branch):
                api = FakeAPI([sample_test(branch=branch)])
                self.run_worker(api)
                self.assertEqual(api.deleted, [])

    def test_custom_deployment_branch_is_preserved(self):
        api = FakeAPI([sample_test(branch="deploy-primary")])
        self.run_worker(api, protected_branches=["deploy-*"])
        self.assertEqual(api.deleted, [])

    def test_production_environment_patterns_are_preserved(self):
        for env in ["production", "prod", "prod-example", "PRODUCTION-example", "release"]:
            with self.subTest(env=env):
                api = FakeAPI([sample_test(environment=env)])
                self.run_worker(api)
                self.assertEqual(api.deleted, [])

    def test_custom_environment_is_preserved(self):
        api = FakeAPI([sample_test(environment="primary")])
        self.run_worker(api, protected_environments=["primary"])
        self.assertEqual(api.deleted, [])

    def test_unknown_legacy_hashed_and_tag_titles_are_preserved(self):
        for title in ["Trivy: registry.example.com/app:abcdef", "sha256:abcdef", "Trivy: app [ref:tag:release]", "Trivy: app [ref:branch:feature/a] trailing"]:
            with self.subTest(title=title):
                api = FakeAPI()
                api.tests[1]["title"] = title
                self.run_worker(api)
                self.assertEqual(api.deleted, [])

    def test_incomplete_wrong_type_and_branch_mismatch_are_preserved(self):
        for field, value in [("percent_complete", 50), ("test_type_name", "Other Scan"), ("branch_tag", "other")]:
            with self.subTest(field=field):
                api = FakeAPI()
                api.tests[1][field] = value
                self.run_worker(api)
                self.assertEqual(api.deleted, [])

    def test_missing_malformed_naive_and_future_timestamps_are_preserved(self):
        for value in [None, "invalid", "2026-08-01", "2099-01-01T00:00:00Z"]:
            with self.subTest(value=value):
                api = FakeAPI()
                api.tests[1]["updated"] = value
                self.run_worker(api)
                self.assertEqual(api.deleted, [])

    def test_missing_or_unknown_history_is_preserved(self):
        for mode in ["missing", "unknown", "bad-time", "wrong-branch"]:
            with self.subTest(mode=mode):
                api = FakeAPI()
                if mode == "missing":
                    api.histories.clear()
                elif mode == "unknown":
                    api.histories[1]["type"] = "unknown"
                elif mode == "bad-time":
                    api.histories[1]["created"] = "invalid"
                else:
                    api.histories[1]["branch_tag"] = "other"
                self.run_worker(api)
                self.assertEqual(api.deleted, [])

    def test_active_findings_and_large_cascades_are_preserved(self):
        for field, value in [("active", 1), ("total", 10001)]:
            with self.subTest(field=field):
                api = FakeAPI()
                setattr(api, field, value)
                self.run_worker(api)
                self.assertEqual(api.deleted, [])

    def test_changed_snapshot_is_preserved(self):
        api = FakeAPI()
        api.change_on_recheck = True
        self.run_worker(api)
        self.assertEqual(api.deleted, [])

    def test_delete_request_limit_is_enforced(self):
        api = FakeAPI([sample_test(1), sample_test(2)])
        self.run_worker(api, max_tests_per_run=1)
        self.assertEqual(api.deleted, [1])

    def test_wrong_scope_or_related_data_aborts_without_deletion(self):
        for field in ["bad_engagement", "wrong_finding_test", "wrong_import_test"]:
            with self.subTest(field=field):
                api = FakeAPI()
                setattr(api, field, True)
                with self.assertRaises(retention.RetentionError):
                    self.run_worker(api)
                self.assertEqual(api.deleted, [])

    def test_async_delete_timeout_stops_further_deletion(self):
        api = FakeAPI([sample_test(1), sample_test(2)])
        api.pending = True
        with self.assertRaises(retention.RetentionError):
            self.run_worker(api)
        self.assertEqual(api.deleted, [1])

    def test_ambiguous_delete_is_not_retried(self):
        api = FakeAPI([sample_test(1), sample_test(2)])
        api.fail_delete = True
        with self.assertRaises(retention.RetentionError):
            self.run_worker(api)
        self.assertEqual(api.deleted, [1])

    def test_empty_scope_is_rejected(self):
        with self.assertRaises(retention.RetentionError):
            self.run_worker(engagement_ids=[])

    def test_history_uses_api_supported_ordering(self):
        self.run_worker()
        histories = [params for method, path, params in self.api.requests if path == "test_imports/"]
        self.assertTrue(histories)
        self.assertTrue(all(p.get("o") == "-created" and "ordering" not in p for p in histories))

    def test_inventory_uses_api_supported_ordering(self):
        self.run_worker()
        pages = [params for method, path, params in self.api.requests if path == "tests/"]
        self.assertTrue(all(p.get("o") == "created" and "ordering" not in p for p in pages))

    def test_all_inventory_pages_are_read_before_deleting(self):
        api = FakeAPI([sample_test(i) for i in range(1, 52)])
        self.run_worker(api, max_tests_per_run=1)
        first_delete = next(i for i, request in enumerate(api.requests) if request[0] == "DELETE")
        pages = [params for method, path, params in api.requests[:first_delete] if path == "tests/"]
        self.assertEqual([p["offset"] for p in pages], [0, 50])
        self.assertEqual(api.deleted, [1])

    def test_cross_origin_pagination_aborts_before_delete(self):
        api = FakeAPI()
        api.bad_next = "https://other.example.com/api/v2/tests/?offset=1"
        with self.assertRaises(retention.RetentionError):
            self.run_worker(api)
        self.assertEqual(api.deleted, [])

    def test_inventory_budget_aborts_before_delete(self):
        api = FakeAPI([sample_test(i) for i in range(1, 5002)])
        with self.assertRaises(retention.RetentionError):
            self.run_worker(api)
        self.assertEqual(api.deleted, [])

    def test_invalid_policy_types_are_rejected(self):
        for field, value in [("days", True), ("days", 1.5), ("engagement_ids", [True]), ("max_tests_per_run", 101), ("protected_branches", [" "]), ("protected_environments", ["x\nsecret"])]:
            with self.subTest(field=field, value=value):
                with self.assertRaises(retention.RetentionError):
                    self.run_worker(**{field: value})

    def test_names_resolve_current_ids_at_runtime(self):
        api = FakeAPI()
        api.tests[1]["engagement"] = 44
        api.engagements = [{"id": 44, "name": "service"}]
        self.run_worker(api, engagement_ids=[], engagement_names=["service"])
        self.assertEqual(api.deleted, [1])
        scoped_pages = [params for method, path, params in api.requests if path == "tests/"]
        self.assertEqual([p["engagement"] for p in scoped_pages], [44])

    def test_named_scope_does_not_include_other_engagements(self):
        api = FakeAPI()
        api.engagements.append({"id": 8, "name": "other"})
        self.run_worker(api, engagement_ids=[], engagement_names=["example"])
        self.assertEqual([p["engagement"] for method, path, p in api.requests if path == "tests/"], [7])

    def test_unknown_and_ambiguous_names_abort_before_test_inventory(self):
        for mode in ["unknown", "ambiguous", "case-mismatch"]:
            with self.subTest(mode=mode):
                api = FakeAPI()
                selected = "unknown" if mode == "unknown" else "Example" if mode == "case-mismatch" else "example"
                if mode == "ambiguous":
                    api.engagements.append({"id": 8, "name": "example", "product": 99})
                with self.assertRaises(retention.RetentionError):
                    self.run_worker(api, engagement_ids=[], engagement_names=[selected])
                self.assertEqual(api.deleted, [])
                self.assertFalse(any(path == "tests/" for method, path, params in api.requests))

    def test_explicit_all_discovers_every_visible_engagement(self):
        api = FakeAPI()
        api.engagements.append({"id": 8, "name": "example"})
        self.run_worker(api, engagement_ids=[], all_engagements=True)
        self.assertEqual([p["engagement"] for method, path, p in api.requests if path == "tests/"], [7, 8])
        self.assertEqual(api.deleted, [1])

    def test_conflicting_scope_selectors_are_rejected(self):
        for extra in [{"engagement_names": ["example"]}, {"all_engagements": True}]:
            with self.subTest(extra=extra):
                with self.assertRaisesRegex(retention.RetentionError, "engagement_selector"):
                    self.run_worker(**extra)
        with self.assertRaisesRegex(retention.RetentionError, "engagement_selector"):
            self.run_worker(engagement_ids=[], engagement_names=["example"], all_engagements=True)

    def test_invalid_names_and_all_flag_are_rejected(self):
        for names in [[""], [" "], ["x\ny"], ["example", "example"], [True], ["x" * 513]]:
            with self.subTest(names=names):
                with self.assertRaises(retention.RetentionError):
                    self.run_worker(engagement_ids=[], engagement_names=names)
        with self.assertRaises(retention.RetentionError):
            self.run_worker(engagement_ids=[], all_engagements="true")

    def test_complete_name_discovery_precedes_test_inventory_and_deletion(self):
        api = FakeAPI()
        api.engagements = [{"id": i, "name": f"service-{i}"} for i in range(1, 52)]
        api.tests[1]["engagement"] = 51
        self.run_worker(api, engagement_ids=[], engagement_names=["service-51"])
        first_test = next(i for i, request in enumerate(api.requests) if request[1] == "tests/")
        discovery = [p["offset"] for method, path, p in api.requests[:first_test] if path == "engagements/"]
        self.assertEqual(discovery, [0, 50])
        self.assertEqual(api.deleted, [1])

    def test_discovery_limit_aborts_without_deletion(self):
        api = FakeAPI()
        api.engagements = [{"id": i, "name": f"service-{i}"} for i in range(1, 102)]
        with self.assertRaises(retention.RetentionError):
            self.run_worker(api, engagement_ids=[], all_engagements=True)
        self.assertEqual(api.deleted, [])

    def test_discovery_counts_against_inventory_page_budget(self):
        api = FakeAPI([sample_test(i) for i in range(1, 5001)])
        with self.assertRaises(retention.RetentionError):
            self.run_worker(api, engagement_ids=[], engagement_names=["example"])
        self.assertEqual(api.deleted, [])


class HTTPTests(unittest.TestCase):
    def setUp(self):
        self.status = 200
        self.body = {"count": 0, "next": None, "results": []}
        self.calls = []
        owner = self

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                owner.calls.append((self.path, self.headers.get("Authorization")))
                self.send_response(owner.status)
                self.send_header("Content-Type", "application/json")
                if owner.status == 302:
                    self.send_header("Location", "/api/v2/redirect-target/")
                self.end_headers()
                body = owner.body if isinstance(owner.body, bytes) else json.dumps(owner.body).encode()
                self.wfile.write(body)

            do_DELETE = do_GET

            def log_message(self, *args):
                pass

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.url = f"http://127.0.0.1:{self.server.server_port}"

    def test_api_token_header_and_query(self):
        api = retention.API(self.url, "offline-token")
        self.assertEqual(api.get("tests/", {"engagement": 7})["count"], 0)
        self.assertEqual(self.calls, [("/api/v2/tests/?engagement=7", "Token offline-token")])

    def test_http_errors_are_sanitized(self):
        for code in [403, 500]:
            self.status = code
            self.body = b"private production payload"
            with self.assertRaises(retention.RetentionError) as ctx:
                retention.API(self.url, "offline-token").get("tests/")
            self.assertNotIn("private production payload", str(ctx.exception))
            self.assertNotIn("offline-token", str(ctx.exception))

    def test_redirect_is_not_followed(self):
        self.status = 302
        with self.assertRaises(retention.RetentionError):
            retention.API(self.url, "offline-token").get("tests/")
        self.assertEqual(len(self.calls), 1)

    def test_missing_is_only_accepted_when_requested(self):
        self.status = 404
        api = retention.API(self.url, "offline-token")
        self.assertIsNone(api.get("tests/1/", missing_ok=True))
        with self.assertRaises(retention.RetentionError):
            api.get("tests/1/")

    def test_invalid_json_fails_closed(self):
        self.body = b"not-json"
        with self.assertRaises(retention.RetentionError):
            retention.API(self.url, "offline-token").get("tests/")

    def test_delete_error_is_not_retried(self):
        self.status = 500
        with self.assertRaises(retention.RetentionError):
            retention.API(self.url, "offline-token").delete("tests/1/")
        self.assertEqual(len(self.calls), 1)

    def test_request_budget_exhaustion_prevents_second_call(self):
        api = retention.API(self.url, "offline-token", request_limit=1)
        api.get("tests/")
        with self.assertRaises(retention.RetentionError):
            api.get("tests/")
        self.assertEqual(len(self.calls), 1)

    def test_unsafe_base_url_and_token_are_rejected(self):
        for url, token in [("https://user:pass@example.com", "token"), ("file:///tmp/data", "token"), (self.url, "token\nheader")]:
            with self.subTest(url=url):
                with self.assertRaises(retention.RetentionError):
                    retention.API(url, token)

    def test_oversized_response_is_rejected(self):
        self.body = b"x" * (8 * 1024 * 1024 + 1)
        with self.assertRaises(retention.RetentionError):
            retention.API(self.url, "offline-token").get("tests/")


if __name__ == "__main__":
    unittest.main()
