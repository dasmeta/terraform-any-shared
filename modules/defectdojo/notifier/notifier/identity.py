"""Conservative structured identity for Trivy findings across container builds."""
import hashlib
import json
import re
import unicodedata

CVE = re.compile(r'CVE-[0-9]{4}-[0-9]{4,}')
COMPONENT = r'[a-z0-9]+(?:(?:[._]|__|-+)[a-z0-9]+)*'
CONTAINER = re.compile(
    r'(?P<registry>[a-z0-9][a-z0-9.-]*(?::[0-9]{1,5})?)/'
    r'(?P<repository>' + COMPONENT + r'(?:/' + COMPONENT + r')*)'
    r'(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127})?(?:@sha256:[0-9a-fA-F]{64})?')
OS_SUFFIX = re.compile(
    r' \((?:debian|ubuntu|alpine|centos|redhat|rocky|almalinux|amazon|oracle|fedora|'
    r'opensuse|suse|wolfi|photon|mariner|azurelinux) ?[0-9][0-9A-Za-z._+\-]*\)$')


def _literal(value, limit):
    return (isinstance(value, str) and 0 < len(value) <= limit and value == value.strip()
            and not any(unicodedata.category(char) == 'Cc' for char in value))


def _target(value):
    # A recognized OS annotation is display metadata only after the remainder is
    # independently proven to be an explicit registry/repository reference.
    candidate = OS_SUFFIX.sub('', value)
    match = CONTAINER.fullmatch(candidate)
    if match:
        registry = match['registry']
        host, separator, port = registry.partition(':')
        if ('.' in host or host == 'localhost' or separator) and (not separator or 0 < int(port) <= 65535):
            return ['container', registry, match['repository']]
    # Do not infer Docker semantics for ordinary paths or uncertain annotations.
    return ['path', value]


def logical_key(row, engagement_id, test_id):
    """Return no identity when structured evidence is absent or ambiguous.

    Scanner title, package version, DefectDojo ID/hash and image build identity
    deliberately do not participate. Scope and complete vulnerability ID sets do.
    """
    vulnerabilities = row.get('vulnerability_ids')
    if (not isinstance(vulnerabilities, list) or not 1 <= len(vulnerabilities) <= 100
            or not _literal(row.get('component_name'), 1024) or not _literal(row.get('file_path'), 4096)):
        return None
    cves = set()
    for item in vulnerabilities:
        value = item.get('vulnerability_id') if isinstance(item, dict) else None
        if not isinstance(value, str) or not CVE.fullmatch(value):
            return None
        cves.add(value)
    identity = ['trivy-main-v1', engagement_id, test_id, sorted(cves), row['component_name'], _target(row['file_path'])]
    return hashlib.sha256(json.dumps(identity, ensure_ascii=False, separators=(',', ':')).encode('utf-8')).hexdigest()
