#!/bin/sh
set -eu

DRY_RUN=false
NAMESPACE_NAME_PATTERN="${NAMESPACE_NAME_PATTERN:-ephemeral}"

usage() {
  cat <<'EOF'
Usage: ephemeral-helm-cleanup.sh [--dry-run]

Uninstall every Helm release from every namespace whose name contains the
configured pattern. Set NAMESPACE_NAME_PATTERN to override the default
"ephemeral" namespace match.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ -z "${NAMESPACE_NAME_PATTERN}" ]; then
  echo "NAMESPACE_NAME_PATTERN cannot be empty" >&2
  exit 2
fi

failures=0
matched_namespaces=0

namespaces="$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')"

for namespace in ${namespaces}; do
  case "${namespace}" in
    *"${NAMESPACE_NAME_PATTERN}"*) ;;
    *) continue ;;
  esac

  matched_namespaces=$((matched_namespaces + 1))
  echo "Checking Helm releases in namespace ${namespace}"

  releases="$(helm list -n "${namespace}" -q || true)"
  if [ -z "${releases}" ]; then
    echo "No Helm releases found in namespace ${namespace}"
    continue
  fi

  for release in ${releases}; do
    if [ "${DRY_RUN}" = "true" ]; then
      echo "DRY RUN: helm uninstall ${release} -n ${namespace}"
      continue
    fi

    echo "Uninstalling Helm release ${release} from namespace ${namespace}"
    if ! helm uninstall "${release}" -n "${namespace}"; then
      echo "Failed to uninstall Helm release ${release} from namespace ${namespace}" >&2
      failures=1
    fi
  done
done

if [ "${matched_namespaces}" -eq 0 ]; then
  echo "No namespaces matched pattern '${NAMESPACE_NAME_PATTERN}'"
fi

exit "${failures}"
