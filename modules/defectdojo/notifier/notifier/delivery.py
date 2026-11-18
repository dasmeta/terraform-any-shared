"""Bounded provider adapters. All errors are fixed codes, never remote content.

The injected HTTP interface is request(method, url, headers, body, timeout,
max_response_bytes) -> {status, headers, body: bytes}. Redirects are forbidden.
"""
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
import json
import math
import re
from urllib.error import HTTPError
from urllib.parse import quote, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

from .slack import message as slack_message

MAX_RESPONSE_BYTES = 65536
TIMEOUT = 20


class DeliveryError(Exception):
    def __init__(self, code, retry_after=None, clear_request=False):
        # Only adapter-owned codes may be rendered in logs.
        self.code = code if isinstance(code, str) and re.fullmatch(r"[a-z0-9_]{1,64}", code) else "delivery_failed"
        self.retry_after = retry_after
        self.clear_request = clear_request
        super().__init__(self.code)


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class HTTPTransport:
    def request(self, method, url, *, headers, body, timeout, max_response_bytes):
        try:
            request = Request(url, data=body, headers=headers, method=method)
            opener = build_opener(NoRedirect())
            try:
                result = opener.open(request, timeout=timeout)
            except HTTPError as error:
                result = error
            with result:
                raw = result.read(max_response_bytes + 1)
                if len(raw) > max_response_bytes:
                    raise DeliveryError("response_too_large")
                return {"status": result.code, "headers": dict(result.headers.items()), "body": raw}
        except DeliveryError:
            raise
        except Exception:
            raise DeliveryError("network_error") from None


def _https(url):
    try:
        parts = urlsplit(url)
        if (not isinstance(url, str) or parts.scheme != "https" or not parts.hostname
                or parts.username is not None or parts.password is not None or parts.fragment
                or any(ord(char) < 33 or ord(char) == 127 for char in url)):
            raise ValueError()
        # Evaluating port rejects malformed or out-of-range values.
        parts.port
    except Exception:
        raise DeliveryError("invalid_webhook") from None
    return url


def _retry_after(headers):
    value = next((str(value) for key, value in headers.items() if key.lower() == "retry-after"), None)
    if value is None:
        return None
    try:
        seconds = float(value)
    except (ValueError, TypeError):
        try:
            when = parsedate_to_datetime(value)
            if when.tzinfo is None:
                return None
            seconds = (when - datetime.now(timezone.utc)).total_seconds()
        except (ValueError, TypeError, OverflowError):
            return None
    if not math.isfinite(seconds):
        return None
    return max(0, math.ceil(seconds))


def _identifier(value, code="invalid_identifier"):
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_.:-]{1,128}", value):
        raise DeliveryError(code)
    return value


def _processed(value):
    if not isinstance(value, str):
        return False
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed.tzinfo is not None and parsed.utcoffset() is not None
    except ValueError:
        return False


class Sender:
    def __init__(self, secrets, region="us", priority="P2", http=None):
        if region not in ("us", "eu"):
            raise DeliveryError("invalid_region")
        if priority not in ("P1", "P2", "P3", "P4", "P5"):
            raise DeliveryError("invalid_priority")
        self.secrets = dict(secrets)
        self.base = "https://api.eu.opsgenie.com" if region == "eu" else "https://api.opsgenie.com"
        self.priority = priority
        self.http = http if http is not None else HTTPTransport()

    def _request(self, method, url, payload=None, key=None):
        headers = {"Accept": "application/json", "Content-Type": "application/json"}
        if key is not None:
            if not isinstance(key, str) or not key or "\r" in key or "\n" in key:
                raise DeliveryError("invalid_integration_key")
            headers["Authorization"] = "GenieKey " + key
        body = json.dumps(payload, ensure_ascii=False, allow_nan=False).encode("utf-8") if payload is not None else None
        if body is not None and len(body) > 65536:
            raise DeliveryError("payload_too_large")
        try:
            result = self.http.request(method, url, headers=headers, body=body,
                                       timeout=TIMEOUT, max_response_bytes=MAX_RESPONSE_BYTES)
            if not isinstance(result["body"], bytes):
                raise DeliveryError("invalid_response")
            if len(result["body"]) > MAX_RESPONSE_BYTES:
                raise DeliveryError("response_too_large")
            status = result["status"]
            if status == 429:
                raise DeliveryError("rate_limited", retry_after=_retry_after(result["headers"]))
            if 300 <= status < 400:
                raise DeliveryError("redirect_blocked")
            if status >= 500:
                raise DeliveryError("provider_unavailable", retry_after=_retry_after(result["headers"]))
            return result
        except DeliveryError:
            raise
        except Exception:
            raise DeliveryError("network_error") from None

    @staticmethod
    def _json(response):
        try:
            result = json.loads(response["body"])
            if not isinstance(result, dict):
                raise ValueError()
            return result
        except (ValueError, UnicodeError, TypeError):
            raise DeliveryError("invalid_response") from None

    @staticmethod
    def _accepted(response):
        if response["status"] != 202:
            raise DeliveryError("provider_rejected")
        data = Sender._json(response)
        request_id = _identifier(data.get("requestId"), "missing_receipt")
        return {"status": "pending", "request_id": request_id}

    def send(self, event):
        try:
            channel, kind, payload = event["channel"], event["kind"], event["payload"]
            if kind not in ("new", "reopened", "resolved", "suppressed", "digest"):
                raise DeliveryError("invalid_event")
            text = payload["text"]
            title = payload["title"]
            if not isinstance(text, str) or not isinstance(title, str) or not text or not title:
                raise DeliveryError("invalid_event")
            if channel == "slack":
                return self._slack(event)
            if channel == "teams":
                return self._teams(text)
            if channel == "opsgenie":
                return self._opsgenie(event, kind, payload)
            raise DeliveryError("invalid_channel")
        except DeliveryError:
            raise
        except Exception:
            raise DeliveryError("invalid_event") from None

    def _slack(self, event):
        try:
            body = slack_message(event)
        except ValueError:
            raise DeliveryError("payload_too_large") from None
        response = self._request("POST", _https(self.secrets.get("slack-url")), body)
        if response["status"] != 200 or response["body"].strip() != b"ok":
            raise DeliveryError("provider_rejected")
        return {"status": "delivered"}

    def _teams(self, text):
        # RichTextBlock TextRun is literal text; TextBlock interprets Markdown.
        card = {"type": "message", "attachments": [{
            "contentType": "application/vnd.microsoft.card.adaptive", "contentUrl": None,
            "content": {"$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                        "type": "AdaptiveCard", "version": "1.2",
                        "body": [{"type": "RichTextBlock", "inlines": [{"type": "TextRun", "text": text}]}]},
        }]}
        if len(json.dumps(card, ensure_ascii=False).encode("utf-8")) > 27000:
            raise DeliveryError("payload_too_large")
        response = self._request("POST", _https(self.secrets.get("teams-url")), card)
        if not 200 <= response["status"] < 300:
            raise DeliveryError("provider_rejected")
        return {"status": "delivered"}

    def _opsgenie(self, event, kind, payload):
        key = self.secrets.get("opsgenie-key")
        if not isinstance(key, str) or not key:
            raise DeliveryError("missing_integration_key")
        if event.get("request_id"):
            request_id = _identifier(event["request_id"])
            response = self._request("GET", self.base + "/v2/alerts/requests/" + quote(request_id, safe=""), key=key)
            if response["status"] == 404:
                # The asynchronous request may not be visible yet. Keep the receipt.
                return {"status": "pending", "request_id": request_id}
            if response["status"] != 200:
                raise DeliveryError("provider_rejected")
            data = self._json(response).get("data")
            if not isinstance(data, dict):
                raise DeliveryError("invalid_receipt")
            if _processed(data.get("processedAt")):
                if data.get("isSuccess") is True:
                    result = {"status": "delivered"}
                    if data.get("alertId"):
                        result["remote_id"] = _identifier(data["alertId"])
                    return result
                if data.get("isSuccess") is False:
                    # A later attempt can safely repeat using the same stable alias.
                    raise DeliveryError("receipt_failed", clear_request=True)
            return {"status": "pending", "request_id": request_id}
        alias = payload.get("alias")
        if not isinstance(alias, str) or not 1 <= len(alias) <= 512 or any(ord(c) < 32 for c in alias):
            raise DeliveryError("invalid_alias")
        if kind in ("resolved", "suppressed"):
            lookup = self._request("GET", self.base + "/v2/alerts/" + quote(alias, safe="") + "?identifierType=alias", key=key)
            if lookup["status"] == 404:
                data = self._json(lookup)
                if data.get("code") == 40401 and data.get("message") in ("Alert does not exist", f"Alert with alias [{alias}] not found."):
                    return {"status": "delivered"}
                raise DeliveryError("provider_rejected")
            if lookup["status"] != 200:
                raise DeliveryError("provider_rejected")
            alert = self._json(lookup).get("data")
            if not isinstance(alert, dict) or alert.get("alias") != alias:
                raise DeliveryError("invalid_alert_lookup")
            alert_id = _identifier(alert.get("id"))
            if alert.get("status") == "closed":
                return {"status": "delivered", "remote_id": alert_id}
            if alert.get("status") != "open":
                raise DeliveryError("invalid_alert_lookup")
            return self._accepted(self._request("POST", self.base + "/v2/alerts/" + quote(alert_id, safe="") + "/close?identifierType=id",
                                                {"source": "DefectDojo notifier"}, key=key))
        if len(payload["text"]) > 15000:
            raise DeliveryError("payload_too_large")
        return self._accepted(self._request("POST", self.base + "/v2/alerts", {
            "message": payload["title"][:130], "description": payload["text"], "alias": alias,
            "priority": "P5" if kind == "digest" else self.priority, "source": "DefectDojo notifier",
            "tags": ["defectdojo", "defectdojo-summary" if kind == "digest" else "defectdojo-finding"],
        }, key=key))
