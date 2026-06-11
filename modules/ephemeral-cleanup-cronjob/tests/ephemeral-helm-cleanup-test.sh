#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SCRIPT="${SCRIPT_DIR}/../scripts/ephemeral-helm-cleanup.sh"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="${TMP_DIR}/bin"
LOG_FILE="${TMP_DIR}/commands.log"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${FAKE_BIN}"
: > "${LOG_FILE}"

cat > "${FAKE_BIN}/kubectl" <<'EOF'
#!/bin/sh
set -eu

if [ "$*" = "get namespaces -o jsonpath={range .items[*]}{.metadata.name}{\"\\n\"}{end}" ]; then
  printf '%s\n' \
    default \
    ephemeral \
    sample-ephemeral-demo-helm \
    dev \
    web-ephemeral-pr-123-helm
  exit 0
fi

echo "unexpected kubectl command: $*" >&2
exit 1
EOF

cat > "${FAKE_BIN}/helm" <<EOF
#!/bin/sh
set -eu

echo "helm \$*" >> "${LOG_FILE}"

case "\$*" in
  "list -n ephemeral -q")
    printf '%s\n' api site
    ;;
  "list -n sample-ephemeral-demo-helm -q")
    printf '%s\n' sample-web
    ;;
  "list -n web-ephemeral-pr-123-helm -q")
    ;;
  *)
    echo "unexpected helm command: \$*" >&2
    exit 1
    ;;
esac
EOF

chmod +x "${FAKE_BIN}/kubectl" "${FAKE_BIN}/helm"

PATH="${FAKE_BIN}:${PATH}" sh "${SCRIPT}" --dry-run > "${TMP_DIR}/output.log"

grep -q "DRY RUN: helm uninstall api -n ephemeral" "${TMP_DIR}/output.log"
grep -q "DRY RUN: helm uninstall site -n ephemeral" "${TMP_DIR}/output.log"
grep -q "DRY RUN: helm uninstall sample-web -n sample-ephemeral-demo-helm" "${TMP_DIR}/output.log"

if grep -q "helm uninstall" "${LOG_FILE}"; then
  echo "dry-run executed helm uninstall" >&2
  exit 1
fi

echo "ephemeral helm cleanup dry-run behavior passed"
