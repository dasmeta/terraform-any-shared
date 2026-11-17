"""Bounded, read-only snapshots from the DefectDojo v2 API."""
import json
import re
import time
from datetime import date, datetime, timedelta, timezone
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

from .identity import logical_key


class SourceError(Exception):
    """Safe reason code without server bodies, URLs or credentials."""

    def __init__(self, code, details=None):
        self.details = details or {}
        super().__init__(code)


def positive(value):
    return type(value) is int and value > 0


def instant(value):
    try:
        result = datetime.fromisoformat(value.replace('Z', '+00:00'))
        return result.astimezone(timezone.utc) if result.utcoffset() is not None else None
    except (ValueError, TypeError, AttributeError):
        return None


def origin_url(value):
    try:
        p = urlsplit(value)
        if (p.scheme not in ('http', 'https') or not p.hostname or p.username or p.password
                or p.query or p.fragment or p.path not in ('', '/') or p.port == 0
                or re.search(r'[\s\\%\x00-\x1f\x7f]', value)):
            raise ValueError
        return value.rstrip('/')
    except (ValueError, TypeError):
        raise SourceError('invalid_api_url') from None


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


class API:
    def __init__(self, api_url, token, opener=None):
        self.origin = origin_url(api_url)
        if not isinstance(token, str) or not token or re.search(r'[\s\x00-\x1f\x7f]', token):
            raise SourceError('invalid_api_token')
        self.base = self.origin + '/api/v2/'
        self.token = token
        self.opener = opener or build_opener(NoRedirect())
        self.calls = 0
        self.started = time.monotonic()

    def check_link(self, link, path, params):
        if link is None:
            return
        try:
            if not isinstance(link, str) or re.search(r'[\s\\]', link):
                raise ValueError
            p, b = urlsplit(link), urlsplit(self.base)
            if ((p.scheme or p.netloc) and (p.scheme, p.hostname, p.port) != (b.scheme, b.hostname, b.port)
                    or p.username or p.password or p.fragment or p.path != b.path + path):
                raise ValueError
            query = parse_qs(p.query, strict_parsing=True)
            if any(query.get(k) != [str(v)] for k, v in params.items() if k != 'offset'):
                raise ValueError
        except (TypeError, ValueError):
            raise SourceError('unsafe_pagination') from None

    def get(self, path, params=None, missing_ok=False):
        if not re.fullmatch(r'[a-z_]+/(?:[1-9][0-9]*/)?', path):
            raise SourceError('invalid_api_path')
        if self.calls >= 2000 or time.monotonic() - self.started > 600:
            raise SourceError('source_budget')
        self.calls += 1
        request = Request(self.base + path + ('?' + urlencode(params) if params else ''),
                          headers={'Authorization': 'Token ' + self.token, 'Accept': 'application/json'})
        try:
            with self.opener.open(request, timeout=20) as response:
                if response.status != 200:
                    raise SourceError('unexpected_api_status')
                raw = response.read(8 * 1024 * 1024 + 1)
                if len(raw) > 8 * 1024 * 1024:
                    raise SourceError('source_response_budget')
                return json.loads(raw)
        except HTTPError as error:
            code = error.code
            error.close()
            if code == 404 and missing_ok:
                return None
            raise SourceError('api_http_' + str(code)) from None
        except (URLError, OSError, ValueError, RecursionError):
            raise SourceError('api_read_failed') from None


class Source:
    TITLE = re.compile(r'Trivy: ([^\[\]\r\n]+) \[ref:branch:main\](?: \[env:([^\]\r\n]+)\])?')
    FLAGS = ('active', 'duplicate', 'false_p', 'out_of_scope', 'risk_accepted')

    def __init__(self, api, policy, now=None):
        self.api, self.policy = api, policy
        self.now = now or datetime.now(timezone.utc)

    def listing(self, path, params=None, max_count=10000):
        params = dict(params or {}, limit=50, offset=0)
        result, seen, expected = [], set(), None
        while True:
            page = self.api.get(path, params)
            if (not isinstance(page, dict) or type(page.get('count')) is not int
                    or not 0 <= page['count'] <= max_count or not isinstance(page.get('results'), list)
                    or len(page['results']) > 50 or 'next' not in page):
                raise SourceError('invalid_list')
            if expected is None:
                expected = page['count']
            if page['count'] != expected:
                raise SourceError('changed_inventory')
            for row in page['results']:
                if not isinstance(row, dict) or not positive(row.get('id')) or row['id'] in seen:
                    raise SourceError('invalid_list_identity')
                seen.add(row['id'])
                result.append(row)
            if hasattr(self.api, 'check_link'):
                self.api.check_link(page['next'], path, params)
            if len(result) == expected and page['next'] is None:
                return result
            if not page['results'] or len(result) >= expected or page['next'] is None:
                raise SourceError('incomplete_inventory')
            params['offset'] = len(result)

    def engagements(self):
        ids = self.policy.get('engagement_ids', [])
        if bool(ids) == bool(self.policy.get('all_engagements', False)):
            raise SourceError('invalid_engagement_selection')
        self.unavailable_engagements = set()
        if ids:
            rows = []
            for engagement_id in ids:
                row = self.api.get(f'engagements/{engagement_id}/', missing_ok=True)
                if row is None:
                    self.unavailable_engagements.add(engagement_id)
                else:
                    if not isinstance(row, dict) or row.get('id') != engagement_id:
                        raise SourceError('invalid_engagement_scope')
                    rows.append(row)
        else:
            rows = self.listing('engagements/', max_count=1000)
        result = {}
        for row in rows:
            if (not isinstance(row, dict) or not positive(row.get('id'))
                    or not isinstance(row.get('name'), str) or not row['name'].strip()
                    or len(row['name']) > 512 or row['id'] in result):
                raise SourceError('invalid_engagement')
            result[row['id']] = row
        if ids and set(result) | self.unavailable_engagements != set(ids):
            raise SourceError('invalid_engagement_scope')
        return result

    @classmethod
    def main_test(cls, test):
        title = test.get('title')
        match = cls.TITLE.fullmatch(title) if isinstance(title, str) else None
        return (match is not None and bool(match[1].strip())
                and (match[2] is None or bool(match[2].strip()))
                and test.get('branch_tag') == 'main' and test.get('test_type_name') == 'Trivy Scan')

    def ready(self, test):
        updated = instant(test.get('updated'))
        return (type(test.get('percent_complete')) is int and test['percent_complete'] == 100
                and test.get('processing', False) is False
                and test.get('status', 'Processed') == 'Processed'
                and updated is not None and updated <= self.now - timedelta(seconds=120))

    @staticmethod
    def test_scope(test, test_id, engagement_id):
        if (not isinstance(test, dict) or test.get('id') != test_id
                or not positive(test.get('id')) or test.get('engagement') != engagement_id):
            raise SourceError('invalid_test_scope')

    def import_stamp(self, test_id):
        page = self.api.get('test_imports/', {'test': test_id, 'o': '-created', 'limit': 1})
        if (not isinstance(page, dict) or type(page.get('count')) is not int
                or page['count'] < 0 or not isinstance(page.get('results'), list)
                or len(page['results']) != min(page['count'], 1)):
            raise SourceError('invalid_import_history')
        if not page['results']:
            return None
        row = page['results'][0]
        if not isinstance(row, dict) or row.get('test') != test_id or not positive(row.get('id')):
            raise SourceError('invalid_import_scope')
        created, modified = instant(row.get('created')), instant(row.get('modified'))
        if (row.get('type') not in ('import', 'reimport') or row.get('branch_tag') != 'main'
                or created is None or modified is None
                or max(created, modified) > self.now - timedelta(seconds=120)):
            return None
        return row['id'], row['type'], row['branch_tag'], created, modified

    @staticmethod
    def fingerprint(test):
        return tuple(test.get(k) for k in ('id', 'engagement', 'title', 'test_type_name',
                                           'branch_tag', 'updated', 'percent_complete', 'processing', 'status'))

    def observation(self, row, test_id, engagement):
        if (not isinstance(row, dict) or not positive(row.get('id'))
                or row.get('test') != test_id or not positive(row.get('test'))
                or any(type(row.get(k)) is not bool for k in self.FLAGS)
                or row.get('severity') not in ('Critical', 'High', 'Medium', 'Low', 'Info')
                or not isinstance(row.get('title'), str) or not row['title'].strip()
                or len(row['title']) > 4096 or 'mitigated' not in row):
            raise SourceError('invalid_finding')
        try:
            discovered = date.fromisoformat(row['date'])
            if discovered > self.now.date():
                raise ValueError
        except (KeyError, ValueError, TypeError):
            raise SourceError('invalid_discovery_date') from None
        reason = 'open'
        for flag, code in [('duplicate', 'duplicate'), ('false_p', 'false_positive'),
                           ('out_of_scope', 'out_of_scope'), ('risk_accepted', 'risk_accepted')]:
            if row[flag]:
                reason = code
                break
        else:
            if row['mitigated'] is not None:
                if instant(row['mitigated']) is None:
                    raise SourceError('invalid_mitigation_date')
                if row['active']:
                    raise SourceError('inconsistent_finding_status')
                reason = 'fixed'
            elif not row['active']:
                reason = 'inactive'
            elif row['severity'] != 'Critical':
                reason = 'severity_changed'
        return dict(id=row['id'], test_id=test_id, engagement_id=engagement['id'],
                    engagement_name=engagement['name'], title=row['title'], severity=row['severity'],
                    date=discovered.isoformat(),
                    url=f'{self.api.origin}/finding/{row["id"]}', open=reason == 'open',
                    reason=reason, observed_at=self.now.isoformat(),
                    logical_key=logical_key(row, engagement['id'], test_id))

    def collect(self, previous):
        """Return observations only after all API reads succeed; missing data stays unknown."""
        observations = {}
        engagements = self.engagements()
        blocked = set(self.unavailable_engagements)
        count_tests = 0
        for engagement_id, engagement in engagements.items():
            tests = self.listing('tests/', {'engagement': engagement_id, 'o': 'created'}, max_count=5000)
            count_tests += len(tests)
            if count_tests > 5000:
                raise SourceError('test_inventory_budget')
            for listed in tests:
                self.test_scope(listed, listed['id'], engagement_id)
                if not self.main_test(listed):
                    continue
                test_id = listed['id']
                before = self.api.get(f'tests/{test_id}/')
                self.test_scope(before, test_id, engagement_id)
                if not self.main_test(before) or not self.ready(before):
                    blocked.add(engagement_id)
                    continue
                import_before = self.import_stamp(test_id)
                if import_before is None:
                    blocked.add(engagement_id)
                    continue
                current = {}
                for row in self.listing('findings/', {'test': test_id, 'severity': 'Critical',
                                                       'active': 'true', 'o': 'id'}):
                    record = self.observation(row, test_id, engagement)
                    if str(record['id']) in observations:
                        raise SourceError('duplicate_finding_identity')
                    current[str(record['id'])] = record
                for key, old in previous.items():
                    if old['open'] and old['test_id'] == test_id and key not in current:
                        row = self.api.get(f'findings/{old["id"]}/', missing_ok=True)
                        if row is None:
                            blocked.add(engagement_id)
                            continue
                        if row.get('id') != old['id']:
                            raise SourceError('invalid_direct_finding_identity')
                        if positive(row.get('test')) and row['test'] != test_id:
                            blocked.add(engagement_id)
                            continue  # A legitimate move is unknown here, never a remediation.
                        current[key] = self.observation(row, test_id, engagement)
                after = self.api.get(f'tests/{test_id}/')
                self.test_scope(after, test_id, engagement_id)
                if (self.fingerprint(before) != self.fingerprint(after) or not self.ready(after)
                        or self.import_stamp(test_id) != import_before):
                    blocked.add(engagement_id)
                    continue
                observations.update(current)
        for key, old in previous.items():
            if old['open'] and old['engagement_id'] in engagements and key not in observations:
                blocked.add(old['engagement_id'])
        return observations, blocked
