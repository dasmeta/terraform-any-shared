#!/usr/bin/env bash
# Candidate material is discarded when a complete generated Secret already exists.
set -euo pipefail
umask 077
TLS_DIR=${TLS_DIR:-/work/tls}
export RANDFILE="$TLS_DIR/.rnd"
mkdir -p "$TLS_DIR"
cd "$TLS_DIR"
if [[ ! ${MYSQL_SERVICE_NAME:-} =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] || [[ ! ${MYSQL_NAMESPACE:-} =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
    echo 'invalid_tls_identity' >&2
    exit 1
fi
# Do not emit openssl diagnostic output, which is unnecessary in pod logs.
openssl req -x509 -newkey rsa:3072 -nodes -sha256 -days 3650 -keyout ca.key -out ca.crt -subj '/CN=DefectDojo Notifications MySQL CA' -addext 'basicConstraints=critical,CA:TRUE' -addext 'keyUsage=critical,keyCertSign,cRLSign' > /dev/null 2>&1
openssl req -newkey rsa:3072 -nodes -sha256 -keyout tls.key -out server.csr -subj "/CN=$MYSQL_SERVICE_NAME" > /dev/null 2>&1
cat > server.cnf <<EOF
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:$MYSQL_SERVICE_NAME,DNS:$MYSQL_SERVICE_NAME.$MYSQL_NAMESPACE,DNS:$MYSQL_SERVICE_NAME.$MYSQL_NAMESPACE.svc,DNS:$MYSQL_SERVICE_NAME.$MYSQL_NAMESPACE.svc.cluster.local
EOF
openssl x509 -req -sha256 -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt -extfile server.cnf > /dev/null 2>&1
openssl verify -CAfile ca.crt tls.crt > /dev/null 2>&1
rm -f ca.key ca.srl server.csr server.cnf .rnd
