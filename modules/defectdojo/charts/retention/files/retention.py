#!/usr/bin/env python3
"""Conservative, bounded deletion of retired DefectDojo Trivy branch Tests."""

import fnmatch
import json
import os
import re
import sys
import time
from datetime import datetime, timedelta, timezone
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener


class RetentionError(Exception):
    """A safe reason code; never includes remote bodies, URLs, or credentials."""


def positive(value):
    return type(value) is int and value > 0


def timestamp(value):
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed if parsed.utcoffset() is not None else None
    except (AttributeError, TypeError, ValueError):
        return None


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


class API:
    def __init__(self, base_url, token, request_limit=2000):
        try:
            parts = urlsplit(base_url)
            valid = (parts.scheme in ("http", "https") and parts.hostname
                     and not parts.username and not parts.password
                     and not parts.query and not parts.fragment and parts.port != 0
                     and parts.path in ("", "/")
                     and not re.search(r"[\s\\%]", base_url)
                     and not any(p in (".", "..") for p in parts.path.split("/")))
        except (TypeError, ValueError):
            valid = False
        if not valid:
            raise RetentionError("invalid_api_url")
        if not isinstance(token, str) or not token or re.search(r"[\s\x00-\x1f\x7f]", token):
            raise RetentionError("invalid_token")
        if not positive(request_limit) or request_limit > 2000:
            raise RetentionError("invalid_request_limit")
        self.base = base_url.rstrip("/")
        self.base += "/api/v2/"
        self.origin = (parts.scheme, parts.hostname, parts.port)
        self.token, self.limit, self.calls = token, request_limit, 0
        self.opener = build_opener(NoRedirect())

    def check_link(self, link, path, params):
        """Validate pagination hints without ever navigating to them."""
        if link is None:
            return
        if not isinstance(link, str) or re.search(r"[\s\\]", link):
            raise RetentionError("invalid_pagination")
        try:
            parts = urlsplit(link)
            base = urlsplit(self.base)
            if parts.scheme or parts.netloc:
                if (parts.scheme, parts.hostname, parts.port) != self.origin:
                    raise RetentionError("unsafe_pagination")
            if parts.username or parts.password or parts.fragment or parts.path != base.path + path:
                raise RetentionError("unsafe_pagination")
            query = parse_qs(parts.query, strict_parsing=True)
            for key, value in params.items():
                if key not in ("offset",) and query.get(key) != [str(value)]:
                    raise RetentionError("invalid_pagination_scope")
        except (TypeError, ValueError):
            raise RetentionError("invalid_pagination") from None

    def _request(self, method, path, params=None, missing_ok=False):
        if not isinstance(path, str) or not re.fullmatch(r"[a-z_]+/(?:[1-9][0-9]*/)?", path):
            raise RetentionError("invalid_api_path")
        if self.calls >= self.limit:
            raise RetentionError("request_budget")
        self.calls += 1
        url = self.base + path + ("?" + urlencode(params) if params else "")
        request = Request(url, method=method, headers={"Authorization": "Token " + self.token,
                                                       "Accept": "application/json"})
        try:
            with self.opener.open(request, timeout=30) as response:
                body = response.read(8 * 1024 * 1024 + 1)
                if len(body) > 8 * 1024 * 1024:
                    raise RetentionError("response_budget")
                if method == "DELETE":
                    if response.status not in (200, 202, 204):
                        raise RetentionError("delete_status")
                    return None
                if response.status != 200:
                    raise RetentionError("read_status")
                return json.loads(body)
        except HTTPError as error:
            code = error.code
            error.close()
            if code == 404 and missing_ok and method == "GET":
                return None
            raise RetentionError("http_status_" + str(code)) from None
        except (URLError, OSError, ValueError, RecursionError):
            raise RetentionError("request_failed") from None

    def get(self, path, params=None, missing_ok=False):
        return self._request("GET", path, params, missing_ok)

    def delete(self, path):
        return self._request("DELETE", path)


class Worker:
    TITLE = re.compile(r"Trivy: ([^\[\]\r\n]+) \[ref:branch:([^\]\r\n]+)\](?: \[env:([^\]\r\n]+)\])?")
    BRANCHES = ("main", "master", "develop", "trunk", "prod", "production", "release/*")
    ENVIRONMENTS = ("prod", "production", "prod-*", "production-*", "release")

    def __init__(self, api, config, now=None, sleep=time.sleep, clock=time.monotonic):
        self.api, self.sleep, self.clock = api, sleep, clock
        self.config = self.validate(config)
        self.now = now if now is not None else datetime.now(timezone.utc)
        if not isinstance(self.now, datetime) or self.now.utcoffset() is None:
            raise RetentionError("invalid_now")
        self.cutoff = self.now - timedelta(days=self.config["days"])
        self.started, self.calls = clock(), 0
        self.inventory_pages = 0
        self.summary = {"requested": 0, "confirmed": 0, "pending": 0, "skipped": 0}

    @staticmethod
    def validate(config):
        if not isinstance(config, dict):
            raise RetentionError("invalid_policy")
        allowed = {"api_url", "engagement_ids", "engagement_names", "all_engagements", "days", "protected_branches", "protected_environments", "max_tests_per_run"}
        if set(config) - allowed:
            raise RetentionError("unknown_policy_field")
        result = dict(config)
        ids = result.setdefault("engagement_ids", [])
        if (not isinstance(ids, list) or len(ids) > 100
                or not all(positive(i) for i in ids) or len(set(ids)) != len(ids)):
            raise RetentionError("invalid_engagement_ids")
        names = result.setdefault("engagement_names", [])
        if (not isinstance(names, list) or len(names) > 100
                or any(not isinstance(name, str) or not name.strip() or len(name) > 512
                       or re.search(r"[\x00-\x1f\x7f]", name) for name in names)
                or len(set(names)) != len(names)):
            raise RetentionError("invalid_engagement_names")
        all_engagements = result.setdefault("all_engagements", False)
        if type(all_engagements) is not bool:
            raise RetentionError("invalid_all_engagements")
        if sum((bool(ids), bool(names), all_engagements)) != 1:
            raise RetentionError("invalid_engagement_selector")
        for name, default, maximum in (("days", 30, 3650), ("max_tests_per_run", 10, 100)):
            result.setdefault(name, default)
            if not positive(result[name]) or result[name] > maximum:
                raise RetentionError("invalid_" + name)
        for name in ("protected_branches", "protected_environments"):
            result.setdefault(name, [])
            patterns = result[name]
            if (not isinstance(patterns, list) or len(patterns) > 100
                    or any(not isinstance(p, str) or not p.strip() or len(p) > 200
                           or re.search(r"[\x00-\x1f\x7f]", p) for p in patterns)):
                raise RetentionError("invalid_" + name)
        if "api_url" in result and not isinstance(result["api_url"], str):
            raise RetentionError("invalid_api_url")
        return result

    def request(self, path, params=None, missing_ok=False):
        self.budget()
        self.calls += 1
        result = self.api.get(path, params, missing_ok=missing_ok)
        self.budget(check_calls=False)
        return result

    def budget(self, check_calls=True):
        if self.clock() - self.started >= 1800:
            raise RetentionError("runtime_budget")
        if check_calls and self.calls >= 2000:
            raise RetentionError("request_budget")

    def page(self, path, params):
        response = self.request(path, params)
        if (not isinstance(response, dict) or type(response.get("count")) is not int
                or response["count"] < 0 or not isinstance(response.get("results"), list)
                or "next" not in response or len(response["results"]) > params["limit"]
                or response["count"] < len(response["results"])
                or any(not isinstance(row, dict) for row in response["results"])):
            raise RetentionError("invalid_list_response")
        if response["next"] is not None:
            if hasattr(self.api, "check_link"):
                self.api.check_link(response["next"], path, params)
            else:
                raise RetentionError("unverifiable_pagination")
        return response

    def scoped_test(self, row, engagement, test_id=None):
        if (not isinstance(row, dict) or not positive(row.get("id"))
                or not positive(row.get("engagement")) or row["engagement"] != engagement
                or (test_id is not None and row["id"] != test_id)):
            raise RetentionError("invalid_test_scope")

    def inventory_page(self, path, params):
        self.inventory_pages += 1
        if self.inventory_pages > 100:
            raise RetentionError("pagination_budget")
        return self.page(path, params)

    def resolve_engagements(self):
        if self.config["engagement_ids"]:
            return self.config["engagement_ids"]
        rows, seen, offset, expected = [], set(), 0, None
        while True:
            page = self.inventory_page("engagements/", {"limit": 50, "offset": offset})
            if expected is None:
                expected = page["count"]
            if page["count"] != expected or expected > 100:
                raise RetentionError("engagement_inventory_budget_or_change")
            for row in page["results"]:
                name = row.get("name")
                if (not positive(row.get("id")) or row["id"] in seen
                        or not isinstance(name, str) or not name.strip() or len(name) > 512
                        or re.search(r"[\x00-\x1f\x7f]", name)):
                    raise RetentionError("invalid_engagement_response")
                seen.add(row["id"])
                rows.append(row)
            offset += len(page["results"])
            if offset == expected and page["next"] is None:
                break
            if not page["results"] or offset >= expected or page["next"] is None:
                raise RetentionError("incomplete_engagement_inventory")
        if self.config["all_engagements"]:
            return sorted(seen)
        resolved = []
        for name in self.config["engagement_names"]:
            matches = [row["id"] for row in rows if row["name"] == name]
            if not matches:
                raise RetentionError("engagement_name_not_found")
            if len(matches) != 1:
                raise RetentionError("ambiguous_engagement_name")
            resolved.append(matches[0])
        return sorted(resolved)

    def inventory(self):
        tests, seen = [], set()
        for engagement in self.resolve_engagements():
            offset, expected = 0, None
            while True:
                page = self.inventory_page("tests/", {"engagement": engagement, "limit": 50, "offset": offset, "o": "created"})
                if expected is None:
                    expected = page["count"]
                if expected != page["count"] or expected > 5000 - len(tests) + offset:
                    raise RetentionError("inventory_budget_or_change")
                for row in page["results"]:
                    self.scoped_test(row, engagement)
                    if row["id"] in seen:
                        raise RetentionError("duplicate_test")
                    seen.add(row["id"])
                    tests.append((row["id"], engagement))
                offset += len(page["results"])
                if offset == expected and page["next"] is None:
                    break
                if not page["results"] or offset >= expected or page["next"] is None:
                    raise RetentionError("incomplete_inventory")
        return tests

    def snapshot(self, test_id, engagement):
        test = self.request(f"tests/{test_id}/", missing_ok=True)
        if test is None:
            return None
        self.scoped_test(test, engagement, test_id)
        title = test.get("title")
        match = self.TITLE.fullmatch(title) if isinstance(title, str) else None
        updated = timestamp(test.get("updated"))
        if (not match or not match[1].strip() or not match[2].strip()
                or re.fullmatch(r"(?:sha256:)?[a-fA-F0-9]{7,64}", match[2])
                or test.get("test_type_name") != "Trivy Scan" or test.get("percent_complete") != 100
                or type(test.get("percent_complete")) not in (int, float)
                or test.get("branch_tag") != match[2] or not updated or updated >= self.cutoff):
            return None
        branch, environment = match[2], match[3] or ""
        for value, builtins, key in ((branch, self.BRANCHES, "protected_branches"),
                                      (environment, self.ENVIRONMENTS, "protected_environments")):
            if any(fnmatch.fnmatchcase(value.lower(), p.lower()) for p in (*builtins, *self.config[key])):
                return None
        history = self.page("test_imports/", {"test": test_id, "o": "-created", "limit": 1})
        if not history["results"]:
            if history["count"]:
                raise RetentionError("incomplete_import_response")
            return None
        record = history["results"][0]
        if not positive(record.get("test")) or record["test"] != test_id:
            raise RetentionError("invalid_import_scope")
        created, modified = timestamp(record.get("created")), timestamp(record.get("modified"))
        if (not positive(record.get("id")) or record.get("type") not in ("import", "reimport")
                or record.get("branch_tag") != branch or not created or not modified
                or max(created, modified) >= self.cutoff):
            return None
        counts = []
        for active in (True, False):
            params = {"test": test_id, "limit": 1}
            if active:
                params["active"] = "true"
            findings = self.page("findings/", params)
            for row in findings["results"]:
                if not positive(row.get("test")) or row["test"] != test_id or not positive(row.get("id")):
                    raise RetentionError("invalid_finding_scope")
                if active and row.get("active") is not True:
                    raise RetentionError("invalid_active_response")
            if findings["count"] and not findings["results"]:
                raise RetentionError("incomplete_findings_response")
            counts.append(findings["count"])
        if counts[0] or counts[1] > 10000:
            return None
        return (test_id, engagement, title, branch, test["test_type_name"], test["percent_complete"],
                updated, record["id"], record["type"], record["branch_tag"], created, modified, *counts)

    def run(self):
        inventory = self.inventory()  # Finish every scoped page before any DELETE.
        for test_id, engagement in inventory:
            if self.summary["requested"] >= self.config["max_tests_per_run"]:
                break
            first = self.snapshot(test_id, engagement)
            if first is None or self.snapshot(test_id, engagement) != first:
                self.summary["skipped"] += 1
                print(json.dumps({"test_id": test_id, "reason": "preserved"}), flush=True)
                continue
            self.budget()
            self.calls += 1
            self.summary["requested"] += 1
            self.summary["pending"] += 1
            print(json.dumps({"test_id": test_id, "reason": "requested"}), flush=True)
            self.api.delete(f"tests/{test_id}/")  # Never retry an ambiguous native cascade.
            deadline = self.clock() + 60
            while True:
                pending = self.request(f"tests/{test_id}/", missing_ok=True)
                if pending is None:
                    break
                self.scoped_test(pending, engagement, test_id)
                if self.clock() >= deadline:
                    raise RetentionError("deletion_pending")
                self.sleep(min(2, deadline - self.clock()))
            self.summary["pending"] -= 1
            self.summary["confirmed"] += 1
            print(json.dumps({"test_id": test_id, "reason": "confirmed"}), flush=True)
        return dict(self.summary)


def main():
    worker = None
    try:
        with open(os.environ.get("RETENTION_POLICY_FILE", "/config/policy.json"), encoding="utf-8") as source:
            policy = json.load(source)
        Worker.validate(policy)
        with open(os.environ.get("RETENTION_TOKEN_FILE", "/var/run/secrets/defectdojo/token"), encoding="utf-8") as source:
            token = source.read(65537).strip()
        if len(token) > 65536:
            raise RetentionError("invalid_token")
        api = API(policy.get("api_url"), token)
        worker = Worker(api, policy)
        print(json.dumps(worker.run()), flush=True)
        return 0
    except (RetentionError, OSError, ValueError, TypeError) as error:
        # Exceptions may contain server bodies, file paths, or secret values.
        summary = dict(worker.summary) if worker else {}
        reason = str(error) if isinstance(error, RetentionError) else "run_aborted"
        if not re.fullmatch(r"[a-z][a-z0-9_]{0,63}", reason):
            reason = "run_aborted"
        print(json.dumps({"reason": reason, **summary}), flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
