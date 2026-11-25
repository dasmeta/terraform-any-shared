"""Validate operator policy and read credentials without exposing their values."""
import json
import re
from pathlib import Path
from urllib.parse import urlsplit
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from .source import SourceError, origin_url


class ConfigError(Exception):
    """Safe configuration reason code."""


def validate(policy):
    if not isinstance(policy, dict):
        raise ConfigError('invalid_policy')
    required = {'namespace', 'api_url', 'engagement_ids', 'all_engagements',
                'time_zone', 'mysql', 'opsgenie_region', 'priority'}
    if set(policy) - {'opsgenie_title_prefix'} != required:
        raise ConfigError('invalid_policy_keys')
    if not isinstance(policy['namespace'], str) or not re.fullmatch(r'[A-Za-z0-9_.:-]{1,64}', policy['namespace']):
        raise ConfigError('invalid_namespace')
    try:
        policy['api_url'] = origin_url(policy['api_url'])
        if len(policy['api_url']) > 512:
            raise ValueError
    except (SourceError, ValueError):
        raise ConfigError('invalid_api_url') from None
    ids = policy['engagement_ids']
    if (not isinstance(ids, list) or len(ids) > 1000
            or any(type(i) is not int or not 0 < i <= 9223372036854775807 for i in ids)
            or len(set(ids)) != len(ids) or type(policy['all_engagements']) is not bool
            or bool(ids) == policy['all_engagements']):
        raise ConfigError('invalid_engagement_selection')
    try:
        if not isinstance(policy['time_zone'], str) or len(policy['time_zone']) > 100:
            raise ValueError
        ZoneInfo(policy['time_zone'])
    except (ZoneInfoNotFoundError, ValueError, TypeError):
        raise ConfigError('invalid_time_zone') from None
    mysql = policy['mysql']
    if (not isinstance(mysql, dict) or set(mysql) - {'host', 'port', 'database', 'tls', 'ca_file'}
            or not isinstance(mysql.get('host'), str)
            or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.:-]{0,252}', mysql['host'])
            or type(mysql.get('port')) is not int or not 1 <= mysql['port'] <= 65535
            or not isinstance(mysql.get('database'), str)
            or not re.fullmatch(r'[A-Za-z0-9_]{1,64}', mysql['database'])
            or type(mysql.get('tls')) is not bool):
        raise ConfigError('invalid_mysql_config')
    if mysql.get('ca_file') is not None:
        if not mysql['tls'] or not isinstance(mysql['ca_file'], str) or not mysql['ca_file'].startswith('/'):
            raise ConfigError('invalid_mysql_ca')
    if policy['opsgenie_region'] not in ('us', 'eu') or policy['priority'] not in ('P1', 'P2', 'P3', 'P4', 'P5'):
        raise ConfigError('invalid_opsgenie_config')
    # Python len() counts Unicode code points; Terraform validation uses the same unit.
    prefix = policy.get('opsgenie_title_prefix', '')
    if (not isinstance(prefix, str) or len(prefix) > 80 or prefix != prefix.strip()
            or any(ord(char) < 32 or ord(char) == 127 for char in prefix)):
        raise ConfigError('invalid_opsgenie_title_prefix')
    return policy


def load(path):
    try:
        with open(path, encoding='utf-8') as source:
            raw = source.read(1024 * 1024 + 1)
        if len(raw) > 1024 * 1024:
            raise ConfigError('policy_budget')
        return validate(json.loads(raw))
    except (OSError, ValueError, TypeError):
        raise ConfigError('policy_read_failed') from None


def secret(directory, name):
    if name not in ('api-token', 'mysql-user', 'mysql-password', 'slack-url', 'teams-url',
                    'opsgenie-key'):
        raise ConfigError('invalid_secret_name')
    try:
        with (Path(directory) / name).open(encoding='utf-8') as source:
            value = source.read(65537).rstrip('\r\n')
        if not value or len(value) > 65536 or '\x00' in value:
            raise ValueError
        return value
    except (OSError, ValueError):
        raise ConfigError('secret_read_failed') from None


def api_token(directory):
    value = secret(directory, 'api-token')
    if re.search(r'[\s\x00-\x1f\x7f]', value):
        raise ConfigError('invalid_api_token')
    return value


def channel_secrets(directory):
    """Read optional destinations; malformed supplied credentials fail closed."""
    values = {}
    for name in ('slack-url', 'teams-url', 'opsgenie-key'):
        try:
            with (Path(directory) / name).open(encoding='utf-8') as source:
                raw = source.read(65537)
        except FileNotFoundError:
            continue
        except (OSError, UnicodeError):
            raise ConfigError('channel_secret_read_failed') from None
        if len(raw) > 65536 or '\x00' in raw:
            raise ConfigError('invalid_channel_secret')
        if not raw.strip():
            continue
        value = raw.rstrip('\r\n')
        if re.search(r'[\s\x00-\x1f\x7f]', value):
            raise ConfigError('invalid_channel_secret')
        if name.endswith('-url'):
            try:
                parts = urlsplit(value)
                if (parts.scheme != 'https' or not parts.hostname or parts.username is not None
                        or parts.password is not None or parts.fragment):
                    raise ValueError
                parts.port  # Reject malformed and out-of-range ports before delivery.
            except ValueError:
                raise ConfigError('invalid_channel_webhook') from None
        values[name] = value
    channels = tuple(channel for channel, name in (('slack', 'slack-url'), ('teams', 'teams-url'),
                                                  ('opsgenie', 'opsgenie-key')) if name in values)
    if not channels:
        raise ConfigError('notification_destination_required')
    return values, channels
