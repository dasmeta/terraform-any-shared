"""One-shot poll/digest worker with persistent delivery state."""
import json
import os
import re
import sys
from datetime import datetime, timezone

from . import config
from .engine import Engine
from .source import API, Source, SourceError
from .store import MySQLStore, StoreError


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    store = None
    try:
        if len(argv) != 1 or argv[0] not in ('poll', 'digest', 'init-db'):
            raise config.ConfigError('invalid_command')
        mode = argv[0]
        policy = config.load(os.environ.get('POLICY_FILE', '/config/policy.json'))
        directory = os.environ.get('SECRET_DIR', '/var/run/secrets/notifications')
        store = MySQLStore.connect(policy['mysql'], policy['namespace'],
                                   config.secret(directory, 'mysql-user'),
                                   config.secret(directory, 'mysql-password'))
        if mode == 'init-db':
            with store.lock():
                store.initialize()
            result = dict(mode=mode, initialized=True)
        else:
            now = datetime.now(timezone.utc)
            api = API(policy['api_url'], config.api_token(directory))
            source = Source(api, policy, now=now)
            from .delivery import Sender
            secrets, channels = config.channel_secrets(directory)
            sender = Sender(secrets, region=policy['opsgenie_region'], priority=policy['priority'],
                            title_prefix=policy.get('opsgenie_title_prefix', ''))
            engine = Engine(source, store, sender, policy, now=now, channels=channels)
            with store.lock():
                result = engine.run(mode)
        print(json.dumps(result, sort_keys=True), flush=True)
        return 0
    except Exception as error:
        # Neither provider bodies nor raw database/config exceptions belong in logs.
        safe = isinstance(error, (config.ConfigError, SourceError, StoreError))
        reason = str(error) if safe else 'run_failed'
        if not re.fullmatch(r'[a-z][a-z0-9_]{0,63}', reason):
            reason = 'run_failed'
        details = error.details if isinstance(error, SourceError) else {}
        print(json.dumps(dict(reason=reason, **details)), flush=True)
        return 1
    finally:
        if store:
            try:
                store.close()
            except StoreError:
                pass  # Process exit also closes the session; do not leak a cleanup traceback.


if __name__ == '__main__':
    sys.exit(main())
