#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SCRIPT="${SCRIPT_DIR}/../scripts/ephemeral-helm-cleanup.sh"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="${TMP_DIR}/bin"
LOG_FILE="${TMP_DIR}/commands.log"
export LOG_FILE

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${FAKE_BIN}"
: > "${LOG_FILE}"

cat > "${FAKE_BIN}/kubectl" <<'EOF'
#!/bin/sh
set -eu

case "$*" in
  "get namespaces -o jsonpath={range .items[*]}{.metadata.name}{\"\\n\"}{end}")
    case "${NAMESPACE_LIST_MODE:-helm}" in
      helm)
        printf '%s\n' default ephemeral sample-ephemeral-demo-helm dev web-ephemeral-pr-123-helm
        ;;
      expiry)
        printf '%s\n' old-ephemeral young-ephemeral
        ;;
      self)
        printf '%s\n' cleanup-ephemeral old-ephemeral
        ;;
    esac
    exit 0
    ;;
  "delete namespace old-ephemeral --ignore-not-found=true --wait=false")
    echo "kubectl $*" >> "${LOG_FILE}"
    exit 0
    ;;
  "delete namespace young-ephemeral --ignore-not-found=true --wait=false")
    echo "kubectl $*" >> "${LOG_FILE}"
    exit 0
    ;;
  "delete namespace cleanup-ephemeral --ignore-not-found=true --wait=false")
    echo "kubectl $*" >> "${LOG_FILE}"
    exit 0
    ;;
esac

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
  "list -n old-ephemeral -q"|"list -n young-ephemeral -q")
    ;;
  "list -n cleanup-ephemeral -q")
    ;;
  *)
    echo "unexpected helm command: \$*" >&2
    exit 1
    ;;
esac
EOF

chmod +x "${FAKE_BIN}/kubectl" "${FAKE_BIN}/helm"

NAMESPACE_LIST_MODE=helm PATH="${FAKE_BIN}:${PATH}" sh "${SCRIPT}" --dry-run > "${TMP_DIR}/output.log"

grep -q "DRY RUN: helm uninstall api -n ephemeral" "${TMP_DIR}/output.log"
grep -q "DRY RUN: helm uninstall site -n ephemeral" "${TMP_DIR}/output.log"
grep -q "DRY RUN: helm uninstall sample-web -n sample-ephemeral-demo-helm" "${TMP_DIR}/output.log"

if grep -q "helm uninstall" "${LOG_FILE}"; then
  echo "dry-run executed helm uninstall" >&2
  exit 1
fi

: > "${LOG_FILE}"
NAMESPACE_LIST_MODE=expiry DELETE_NAMESPACES=true PATH="${FAKE_BIN}:${PATH}" sh "${SCRIPT}" > "${TMP_DIR}/expiry.log"
grep -q 'kubectl delete namespace old-ephemeral --ignore-not-found=true --wait=false' "${LOG_FILE}"
grep -q 'kubectl delete namespace young-ephemeral --ignore-not-found=true --wait=false' "${LOG_FILE}"

: > "${LOG_FILE}"
NAMESPACE_LIST_MODE=expiry DELETE_NAMESPACES=true PATH="${FAKE_BIN}:${PATH}" sh "${SCRIPT}" --dry-run > "${TMP_DIR}/expiry-dry-run.log"
grep -q 'DRY RUN: kubectl delete namespace old-ephemeral --ignore-not-found=true --wait=false' "${TMP_DIR}/expiry-dry-run.log"
grep -q 'DRY RUN: kubectl delete namespace young-ephemeral --ignore-not-found=true --wait=false' "${TMP_DIR}/expiry-dry-run.log"
if grep -q 'kubectl delete namespace' "${LOG_FILE}"; then
  echo "dry-run executed namespace deletion" >&2
  exit 1
fi

: > "${LOG_FILE}"
NAMESPACE_LIST_MODE=self JOB_NAMESPACE=cleanup-ephemeral DELETE_NAMESPACES=true PATH="${FAKE_BIN}:${PATH}" sh "${SCRIPT}" > "${TMP_DIR}/self.log"
grep -q 'kubectl delete namespace old-ephemeral --ignore-not-found=true --wait=false' "${LOG_FILE}"
grep -q 'Skipping cleanup job namespace cleanup-ephemeral' "${TMP_DIR}/self.log"
if grep -q 'cleanup-ephemeral' "${LOG_FILE}"; then
  echo "cleanup job namespace was inspected or deleted" >&2
  exit 1
fi

echo "ephemeral helm cleanup behavior passed"
