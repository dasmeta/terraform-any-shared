"""Destination behavior and transport bounds; no live notifications."""
import importlib
import io
import json
from pathlib import Path
import sys
import unittest
from datetime import datetime, timedelta, timezone
from email.utils import format_datetime
from unittest.mock import Mock, patch
from urllib.error import HTTPError

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "notifier"))

SECRETS = {"slack-url": "https://hooks.slack.com/services/secret-path",
           "teams-url": "https://example.logic.azure.com/workflows/secret?sig=secret",
           "opsgenie-key": "integration-secret"}


def event(channel="opsgenie", kind="new", request_id=None):
    return {"channel": channel, "kind": kind, "request_id": request_id,
            "payload": {"alias": "dd:instance:f:1:episode:1", "title": "A vulnerability",
                        "text": "<!here> <@U123> [look](https://bad.example) & exploit\nhttps://dojo.example/finding/1",
                        "transition_id": "transition:1"}}


def response(status=200, data=None, headers=None, body=None):
    return {"status": status, "headers": headers or {},
            "body": body if body is not None else json.dumps(data or {}).encode()}


class FakeHTTP:
    def __init__(self, *responses):
        self.responses, self.calls = list(responses), []

    def request(self, method, url, **kwargs):
        self.calls.append((method, url, kwargs))
        result = self.responses.pop(0)
        if isinstance(result, Exception):
            raise result
        return result


class DeliveryTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.import_module("notifier.delivery")

    def sender(self, *responses, region="us"):
        self.http = FakeHTTP(*responses)
        return self.mod.Sender(SECRETS, region=region, http=self.http)

    def payload(self, index=0):
        return json.loads(self.http.calls[index][2]["body"])

    def test_slack_plain_text_disables_mentions_markup_and_unfurls(self):
        sender = self.sender(response(body=b"ok"))
        self.assertEqual(sender.send(event("slack")), {"status": "delivered"})
        payload = self.payload()
        self.assertFalse(payload["mrkdwn"])
        self.assertFalse(payload["link_names"])
        self.assertEqual(payload["parse"], "none")
        self.assertFalse(payload["unfurl_links"])
        self.assertNotIn("<!here>", payload["text"])
        self.assertNotIn("<@U123>", payload["text"])
        self.assertIn("https://dojo.example/finding/1", payload["text"])

    def test_teams_workflow_uses_adaptive_card_rich_plain_text(self):
        sender = self.sender(response(202, body=b""))
        self.assertEqual(sender.send(event("teams"))["status"], "delivered")
        payload = self.payload()
        self.assertEqual(payload["type"], "message")
        card = payload["attachments"][0]
        self.assertEqual(card["contentType"], "application/vnd.microsoft.card.adaptive")
        self.assertEqual(card["content"]["type"], "AdaptiveCard")
        body = card["content"]["body"]
        self.assertEqual(body[0]["type"], "RichTextBlock")
        self.assertEqual(body[0]["inlines"][0]["type"], "TextRun")
        self.assertEqual(body[0]["inlines"][0]["text"], event()["payload"]["text"])
        self.assertNotIn("msteams", card["content"])

    def test_opsgenie_create_uses_integration_key_alias_priority_tags_and_receipt(self):
        sender = self.sender(response(202, {"requestId": "receipt-1"}))
        self.assertEqual(sender.send(event()), {"status": "pending", "request_id": "receipt-1"})
        self.assertEqual(self.http.calls[0][0:2], ("POST", "https://api.opsgenie.com/v2/alerts"))
        self.assertEqual(self.http.calls[0][2]["headers"]["Authorization"], "GenieKey integration-secret")
        self.assertEqual(self.payload()["alias"], event()["payload"]["alias"])
        self.assertEqual(self.payload()["priority"], "P2")
        self.assertEqual(self.payload().get("tags"), ["defectdojo", "defectdojo-finding"])

    def test_digest_uses_same_integration_key_and_p5_summary_tags_in_eu(self):
        sender = self.sender(response(202, {"requestId": "digest-receipt"}), region="eu")
        sender.send(event(kind="digest"))
        self.assertEqual(self.http.calls[0][1], "https://api.eu.opsgenie.com/v2/alerts")
        self.assertEqual(self.http.calls[0][2]["headers"]["Authorization"], "GenieKey integration-secret")
        self.assertEqual(self.payload()["priority"], "P5")
        self.assertEqual(self.payload().get("tags"), ["defectdojo", "defectdojo-summary"])

    def test_close_looks_up_alias_before_async_close(self):
        sender = self.sender(response(200, {"data": {"id": "alert-1", "alias": event()["payload"]["alias"], "status": "open"}}),
                             response(202, {"requestId": "close-receipt"}))
        result = sender.send(event(kind="resolved"))
        self.assertEqual(result, {"status": "pending", "request_id": "close-receipt"})
        self.assertEqual(self.http.calls[0][0], "GET")
        self.assertIn("identifierType=alias", self.http.calls[0][1])
        self.assertEqual(self.http.calls[1][0:2], ("POST", "https://api.opsgenie.com/v2/alerts/alert-1/close?identifierType=id"))
        self.assertEqual([call[2]["headers"]["Authorization"] for call in self.http.calls],
                         ["GenieKey integration-secret"] * 2)

    def test_verified_absent_alias_on_close_is_success_but_generic_404_is_error(self):
        sender = self.sender(response(404, {"message": "Alert does not exist", "code": 40401}))
        self.assertEqual(sender.send(event(kind="suppressed"))["status"], "delivered")
        sender = self.sender(response(404, {"message": "Endpoint not found"}))
        with self.assertRaises(self.mod.DeliveryError):
            sender.send(event(kind="resolved"))

    def test_exact_alias_not_found_response_is_idempotent_close_success(self):
        alias = event()["payload"]["alias"]
        sender = self.sender(response(404, {"message": f"Alert with alias [{alias}] not found.", "code": 40401}))
        self.assertEqual(sender.send(event(kind="resolved"))["status"], "delivered")
        sender = self.sender(response(404, {"message": "Alert with alias [different-alias] not found.", "code": 40401}))
        with self.assertRaises(self.mod.DeliveryError):
            sender.send(event(kind="resolved"))

    def test_pending_receipt_only_gets_status_without_recreating_alert(self):
        sender = self.sender(response(404, {"message": "Request does not exist"}))
        result = sender.send(event(request_id="receipt-1"))
        self.assertEqual(result, {"status": "pending", "request_id": "receipt-1"})
        self.assertEqual(len(self.http.calls), 1)
        self.assertEqual(self.http.calls[0][0:2], ("GET", "https://api.opsgenie.com/v2/alerts/requests/receipt-1"))

    def test_only_processed_successful_receipt_confirms_delivery(self):
        sender = self.sender(response(200, {"data": {"isSuccess": True, "processedAt": "2026-11-12T00:00:00Z", "alertId": "alert-1"}}))
        self.assertEqual(sender.send(event(request_id="receipt-1")), {"status": "delivered", "remote_id": "alert-1"})
        sender = self.sender(response(200, {"data": {"isSuccess": True}}))
        self.assertEqual(sender.send(event(request_id="receipt-1"))["status"], "pending")

    def test_terminal_failed_receipt_is_reset_for_later_retry(self):
        sender = self.sender(response(200, {"data": {"isSuccess": False, "processedAt": "2026-11-12T00:00:00Z", "status": "integration failure"}}))
        with self.assertRaises(self.mod.DeliveryError) as caught:
            sender.send(event(request_id="receipt-1"))
        self.assertEqual(caught.exception.code, "receipt_failed")
        self.assertTrue(caught.exception.clear_request)
        self.assertEqual(len(self.http.calls), 1)

    def test_create_requires_202_receipt_instead_of_accepting_arbitrary_200(self):
        for status, data in ((202, {}), (200, {"requestId": "abc"})):
            sender = self.sender(response(status, data))
            with self.assertRaises(self.mod.DeliveryError):
                sender.send(event())

    def test_rate_limit_honors_retry_after_seconds_and_http_date(self):
        sender = self.sender(response(429, headers={"Retry-After": "120"}))
        with self.assertRaises(self.mod.DeliveryError) as caught:
            sender.send(event("slack"))
        self.assertEqual(caught.exception.retry_after, 120)
        future = datetime.now(timezone.utc) + timedelta(minutes=5)
        sender = self.sender(response(429, headers={"retry-after": format_datetime(future)}))
        with self.assertRaises(self.mod.DeliveryError) as caught:
            sender.send(event("teams"))
        self.assertGreater(caught.exception.retry_after, 295)

    def test_redirects_bodies_and_network_errors_are_safe(self):
        for reply in (response(302, headers={"Location": "https://attacker.example/"}),
                      response(500, body=b"individual-secret remote provider message"),
                      RuntimeError("https://secret/path?sig=summary-secret")):
            sender = self.sender(reply)
            with self.assertRaises(self.mod.DeliveryError) as caught:
                sender.send(event())
            self.assertNotIn("secret", repr(caught.exception))
            self.assertNotIn("https:", repr(caught.exception))
            self.assertIsNone(caught.exception.__cause__)
            self.assertEqual(len(self.http.calls), 1)

    def test_sender_limits_response_bytes_even_for_injected_transport(self):
        sender = self.sender(response(200, body=b"x" * 65537))
        with self.assertRaisesRegex(self.mod.DeliveryError, "response_too_large"):
            sender.send(event("slack"))
        kwargs = self.http.calls[0][2]
        self.assertGreater(kwargs["timeout"], 0)
        self.assertEqual(kwargs["max_response_bytes"], 65536)

    def test_rejects_insecure_webhooks_and_invalid_region_before_network(self):
        for url in ("http://example.com", "https://user:password@example.com", "https://example.com/#secret", "https://example.com/\nX:bad"):
            secrets = dict(SECRETS, **{"slack-url": url})
            with self.assertRaises(self.mod.DeliveryError):
                self.mod.Sender(secrets, http=FakeHTTP()).send(event("slack"))
        with self.assertRaises(self.mod.DeliveryError):
            self.mod.Sender(SECRETS, region="https://attacker.example")

    def test_deprecated_extra_summary_key_is_ignored_for_all_opsgenie_requests(self):
        for obsolete in (SECRETS['opsgenie-key'], 'obsolete-key', None):
            with self.subTest(obsolete=obsolete):
                secrets = dict(SECRETS, **{'opsgenie-summary-key': obsolete})
                self.http = FakeHTTP(response(202, {'requestId': 'finding-receipt'}),
                                     response(202, {'requestId': 'digest-receipt'}),
                                     response(404), response(404))
                sender = self.mod.Sender(secrets, http=self.http)
                self.assertEqual(sender.send(event()), {'status': 'pending', 'request_id': 'finding-receipt'})
                self.assertEqual(sender.send(event(kind='digest')), {'status': 'pending', 'request_id': 'digest-receipt'})
                sender.send(event(request_id='finding-receipt'))
                sender.send(event(kind='digest', request_id='digest-receipt'))
                self.assertEqual([call[2]['headers']['Authorization'] for call in self.http.calls],
                                 ['GenieKey integration-secret'] * 4)
                self.assertEqual([call[0] for call in self.http.calls], ['POST', 'POST', 'GET', 'GET'])
                self.assertEqual(self.payload(0)['priority'], 'P2')
                self.assertEqual(self.payload(1)['priority'], 'P5')
                self.assertEqual(self.payload(0).get('tags'), ['defectdojo', 'defectdojo-finding'])
                self.assertEqual(self.payload(1).get('tags'), ['defectdojo', 'defectdojo-summary'])

    def test_large_payload_rejected_without_silent_truncation(self):
        sender = self.sender()
        item = event()
        item["payload"]["text"] = "a" * 15001
        with self.assertRaises(self.mod.DeliveryError):
            sender.send(item)
        self.assertEqual(self.http.calls, [])


class TransportTests(unittest.TestCase):
    def setUp(self):
        self.mod = importlib.import_module("notifier.delivery")

    def test_no_redirect_handler_returns_no_redirect_request(self):
        handler = self.mod.NoRedirect()
        self.assertIsNone(handler.redirect_request(Mock(), Mock(), 302, "Moved", {}, "https://attacker.example"))

    def test_http_error_body_is_bounded_and_closed(self):
        body = io.BytesIO(b"x" * 100)
        error = HTTPError("https://secret/path", 500, "provider message", {}, body)
        opener = Mock()
        opener.open.side_effect = error
        with patch.object(self.mod, "build_opener", return_value=opener):
            with self.assertRaisesRegex(self.mod.DeliveryError, "response_too_large"):
                self.mod.HTTPTransport().request("GET", "https://example.com", headers={}, body=None,
                                                timeout=10, max_response_bytes=10)
        self.assertTrue(body.closed)


if __name__ == "__main__":
    unittest.main()
