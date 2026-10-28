#!/bin/sh
set -eu

DRY_RUN=false
NAMESPACE_NAME_PATTERN="${NAMESPACE_NAME_PATTERN:-ephemeral}"
DELETE_NAMESPACES="${DELETE_NAMESPACES:-false}"
JOB_NAMESPACE="${JOB_NAMESPACE:-}"

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

case "${DELETE_NAMESPACES}" in
  true|false) ;;
  *)
    echo "DELETE_NAMESPACES must be true or false" >&2
    exit 2
    ;;
esac

failures=0
matched_namespaces=0

namespaces="$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')"

for namespace in ${namespaces}; do
  case "${namespace}" in
    *"${NAMESPACE_NAME_PATTERN}"*) ;;
    *) continue ;;
  esac

  if [ -n "${JOB_NAMESPACE}" ] && [ "${namespace}" = "${JOB_NAMESPACE}" ]; then
    echo "Skipping cleanup job namespace ${namespace}"
    continue
  fi

  matched_namespaces=$((matched_namespaces + 1))
  echo "Checking Helm releases in namespace ${namespace}"

  if ! releases="$(helm list -n "${namespace}" -q)"; then
    echo "Failed to list Helm releases in namespace ${namespace}" >&2
    failures=1
    continue
  fi

  namespace_failed=false
  if [ -z "${releases}" ]; then
    echo "No Helm releases found in namespace ${namespace}"
  else
    for release in ${releases}; do
      if [ "${DRY_RUN}" = "true" ]; then
        echo "DRY RUN: helm uninstall ${release} -n ${namespace}"
        continue
      fi

      echo "Uninstalling Helm release ${release} from namespace ${namespace}"
      if ! helm uninstall "${release}" -n "${namespace}"; then
        echo "Failed to uninstall Helm release ${release} from namespace ${namespace}" >&2
        failures=1
        namespace_failed=true
      fi
    done
  fi

  if [ "${DELETE_NAMESPACES}" = "true" ] && [ "${namespace_failed}" = "false" ]; then
    if [ "${DRY_RUN}" = "true" ]; then
      echo "DRY RUN: kubectl delete namespace ${namespace} --ignore-not-found=true --wait=false"
    elif ! kubectl delete namespace "${namespace}" --ignore-not-found=true --wait=false; then
      echo "Failed to delete namespace ${namespace}" >&2
      failures=1
    fi
  fi
done

if [ "${matched_namespaces}" -eq 0 ]; then
  echo "No namespaces matched pattern '${NAMESPACE_NAME_PATTERN}'"
fi

exit "${failures}"
