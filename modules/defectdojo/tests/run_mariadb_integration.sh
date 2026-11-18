#!/bin/bash
# Isolated compatibility test only. Requires local MariaDB tools and a Python
# environment with the module requirements installed. No Docker/shared database.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
PYTHON_TEST=${1:-python3}
MODULE_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SQL_TEST_DIR=$(mktemp -d /private/tmp/defectdojo-notifier-sql.XXXXXX)
SQL_TEST_PORT=$($PYTHON_TEST - <<'PY'
import socket
with socket.socket() as listener:
    listener.bind(('127.0.0.1', 0))
    print(listener.getsockname()[1])
PY
)
SQL_TEST_PID=
cleanup() {
    if [ -n "$SQL_TEST_PID" ] && kill -0 "$SQL_TEST_PID" 2>/dev/null; then
        mysqladmin --no-defaults --socket="$SQL_TEST_DIR/mysql.sock" --user=root shutdown || kill "$SQL_TEST_PID"
        wait "$SQL_TEST_PID" || true
    fi
    echo "Isolated SQL server stopped. Evidence directory: $SQL_TEST_DIR"
}
trap cleanup EXIT
"$PYTHON_TEST" - <<'PY'
from importlib.metadata import version
print('PyMySQL distribution:', version('PyMySQL'))
PY
mysqld --version
mariadb-install-db --no-defaults --datadir="$SQL_TEST_DIR/data" --auth-root-authentication-method=normal --skip-test-db > "$SQL_TEST_DIR/initialize.log" 2>&1
mysqld --no-defaults --datadir="$SQL_TEST_DIR/data" --socket="$SQL_TEST_DIR/mysql.sock" --pid-file="$SQL_TEST_DIR/mysql.pid" --bind-address=127.0.0.1 --port="$SQL_TEST_PORT" --skip-name-resolve --log-error="$SQL_TEST_DIR/server.log" > "$SQL_TEST_DIR/startup.log" 2>&1 &
SQL_TEST_PID=$!
SQL_TEST_READY=false
for attempt in $(seq 1 40); do
    if ! kill -0 "$SQL_TEST_PID" 2>/dev/null; then
        cat "$SQL_TEST_DIR/server.log"
        exit 1
    fi
    if mysqladmin --no-defaults --socket="$SQL_TEST_DIR/mysql.sock" --user=root ping > /dev/null 2>&1; then
        SQL_TEST_READY=true
        break
    fi
    sleep 0.25
done
if [ "$SQL_TEST_READY" != true ]; then
    echo 'Isolated SQL startup timed out.'
    exit 1
fi
export NOTIFIER_SQL_PORT="$SQL_TEST_PORT"
cd "$MODULE_ROOT"
"$PYTHON_TEST" - <<'PY'
import json, os, pymysql, unittest
port = int(os.environ['NOTIFIER_SQL_PORT'])
connection = pymysql.connect(host='127.0.0.1', port=port, user='root', password='', ssl_disabled=True)
with connection.cursor() as cursor:
    cursor.execute('CREATE DATABASE notifier_test CHARACTER SET utf8mb4 COLLATE utf8mb4_bin')
connection.close()
os.environ['NOTIFIER_MYSQL_TEST_CONFIG'] = json.dumps(dict(host='127.0.0.1', port=port, database='notifier_test', username='root', password='', tls=False))
result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.discover('tests', pattern='test_*.py'))
raise SystemExit(not result.wasSuccessful())
PY
