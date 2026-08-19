# SFTPGo Web Session Stability Design

## Goal

Keep SFTPGo WebAdmin and WebClient sessions valid across pod restarts and make
the browser cookie lifetime explicit for the shared Terraform module.

## Current Cause

The module configures `common` and `data_provider`, but it does not configure
the SFTPGo `httpd` session settings. SFTPGo generates a random signing key when
`httpd.signing_passphrase` is empty, which invalidates JWT and CSRF cookies after
every process restart. The default browser cookie lifetime is also only 20
minutes without activity.

## Decision

Add a grouped `web_session` input to the module with:

- `signing_passphrase`, marked sensitive and supplied by the consumer;
- `cookie_lifetime`, defaulting to 720 minutes when the block is enabled;
- `token_validation`, defaulting to `0` to preserve SFTPGo's IP validation.

The module maps this object to `config.httpd` in the upstream Helm values. The
consumer environment supplies a stable secret from its existing secret output.
The implementation does not enable IP-independent validation by default; a
consumer may set `token_validation = 1` when changing client IPs are confirmed
to be the logout trigger.

## Scope

In scope: module input validation, Helm value generation, the environment YAML,
README, basic example, test fixture, and Speckit evidence.

Out of scope: changing replica count, adding an external database, changing the
ALB, or automatically creating a new secret in the account workspace.

## Verification

Run Terraform formatting and validation for the module, basic example, and test
fixture. Inspect the generated module input to confirm the WebUI session block
is present. Live rollout verification requires refreshed AWS credentials and a
follow-up check of pod restart count and WebUI behavior.
