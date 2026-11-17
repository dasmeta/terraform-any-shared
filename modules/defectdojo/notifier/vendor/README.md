# Offline runtime dependencies

These unmodified pure-Python wheels are distributed with the module so the
standard Python container can import the notifier without runtime package
installation or a custom image. `manifest.json` records official PyPI download
URLs, pinned versions and verified SHA256 hashes. Distribution licenses are
included both inside the wheels and alongside them. No compiled extensions or
platform-specific binary wheels are included.

PyMySQL SHA2 authentication uses the required TLS connection for managed MySQL.
The optional RSA/cryptography extra is not bundled: external `tls=false` is only
suitable for isolated tests with a compatible native-password authentication
setup. Managed MySQL always verifies certificate and hostname.

When upgrading, fetch each version's `py3-none-any`/`py2.py3-none-any` wheel from
its official PyPI JSON release metadata, verify its SHA256, retain its license,
update the manifest and requirements, then run the bundle and SQL integration
tests. Terraform passes wheel data to a separate binary ConfigMap; tests enforce
Kubernetes object-size limits. Do not edit wheel contents.
