# Notification example

Requires Kubernetes >=1.27, an accessible DefectDojo API and a default
StorageClass (or explicit `notifications.mysql.storage_class`; an empty string
selects no class and requires a static/preprovisioned volume). Enabling
notifications creates a dedicated single-instance MySQL 8.4 with an 8Gi
persistent volume, generated credentials and verified TLS, then initializes
its notification tables. The worker uses the pinned public Python 3.12 image
with source and dependency wheels bundled in this module; there is no custom
image build or runtime package download.

The application release name must be a lowercase DNS label of at most 31
characters when notifications are enabled. Both schedules use UTC: polls run
hourly at minute zero, and the daily digest runs at13:30UTC (17:30 in Yerevan).
The example uses direct credentials through the sensitive
`notification_channels` input. Supply only `slack_webhook_url` for Slack-only
delivery. Add `teams_webhook_url` for Teams and/or `opsgenie_api_key` for
Opsgenie; unused fields default empty. Provide
values through your normal environment/tfvars secret handling.
The example omits `api_token_secret`: it reuses enabled
retention's actual token Secret/key, or otherwise automatically bootstraps
`example-defectdojo-notifications-api` from this module's application account.
API and MySQL credentials remain generated in the cluster or referenced by
Secret name.

Opsgenie uses the same integration key for finding and P5 summary alerts. Alerts
carry `defectdojo` plus `defectdojo-finding` or `defectdojo-summary` tags for
routing rules. P5/tags do not disable paging automatically; review the
integration's notification and escalation rules. Replace Engagement IDs 7 and 9 with your IDs, or omit
`engagement_ids` and explicitly set `all_engagements=true`. An empty selector
never means every Engagement.

Direct mode requires at least one destination, no `channels_secret.name` and
default Secret key mappings. Whitespace-only supplied values and mixed
direct/existing Secret sources are
rejected. The shared module declassifies only channel presence for resource
counts; credential values remain sensitive.

Alternatively, replace `channels` with
`channels_secret = { name = "example-notifier-channels" }` in `1-example.tf` and
create that Secret in `example-security` through your normal secret-management
process. It can contain only `slack-url` for Slack-only, `teams-url` for Teams,
and/or `opsgenie-key` for Opsgenie. Custom key
mappings are supported for existing Secrets. Missing or empty channel files
disable that destination; live workers require at least one.

Direct mode owns `example-defectdojo-notifications-channels`, containing only
the selected credentials under fixed keys `slack-url`, `teams-url`,
and `opsgenie-key` as applicable. It passes
credentials only through sensitive Helm settings into that Secret; worker
ConfigMaps and outputs contain no credentials. **Terraform and Helm state still
store direct credential values**; sensitive settings and base64 do not encrypt
state. Protect state and saved plans, keep real credentials out of source
control, or use an existing Secret to keep its values outside Terraform/Helm
state. Disabling removes the owned channels Secret even with
`retain_state=true`; the existing Secret option leaves caller-owned Secrets
untouched.

The example omits `enabled` and sets `retain_state=false`. Providing a direct
channel or `channels_secret.name` enables notifications automatically. Empty
channels stay disabled; API/MySQL Secret references alone do not enable them.
Use `enabled=false` to force off, or `enabled=true` to require complete valid
configuration explicitly. The default teardown
policy deletes managed notifier history; use `retain_state=true` explicitly
when history must survive disabling.

The example enables real delivery. Provisioning initializes the managed schema;
scheduled poll/digest jobs persist state and send notifications. Review the
source scope and destination routing before applying it. The first complete
observation sends existing qualifying Critical findings individually to the
configured destinations. Monitor failed Jobs and, when using Opsgenie, review summary routing rules before
enabling delivery. Poll and digest share a MySQL advisory lock and bounded Job
retries.

Previously open findings absent from the active list are reconciled in bounded
Test-scoped ID batches, including all statuses and severities. Missing or moved
IDs remain unknown rather than inferred fixed. A source-collection error saves
no partial observations; already committed pending deliveries can still retry.

The state namespace uses the canonical API origin: hostname/scheme case,
trailing slash and explicit default ports (`:443` for HTTPS, `:80` for HTTP,
including padded standard ports) do not create separate ledgers. HTTP versus
HTTPS, other hosts and nondefault ports remain separate. Existing bare-origin
namespaces are unchanged. Development installations created before this fix with
an explicit default port already have a different namespace: preserve that
history and plan its migration before applying; this fix does not silently
rewrite or delete old namespaces or remote alert aliases.

**Known import-completion limitation on DefectDojo 3.4.304:** its Test API does
not expose processing/status. Old unchanged Test timestamps and import history,
even with a settlement interval, cannot prove that reimport or deduplication has
finished. Intermediate findings can therefore generate premature notifications.
A reliable repair requires a producer-owned begin/end generation gate covering
every import and successful synchronous post-processing, or an equivalent
upstream API completion signal. A completion-only callback or longer delay is
insufficient. This integration change remains open pending operator approval.

Daily Slack delivery uses one summary card per nonempty Engagement: global
open/new/fixed counts, the five oldest findings and a **View All Findings**
button. See [slack-summary.example.json](slack-summary.example.json). Teams and
Opsgenie retain the complete numbered lists. New counts describe observations
in the last 24 hours, so the first backlog can count as new despite older
discovery dates. An existing daily snapshot stays frozen across layout upgrades;
the new card appears with the next daily snapshot. Unusually large text can
reduce the sample below five, with the displayed count stated explicitly.

Removing a destination preserves its pending deliveries without sending them;
they resume if reenabled. Adding a destination does not backfill unchanged
findings; it receives future lifecycle events and the next eligible daily
snapshot. Existing same-day daily snapshots stay frozen.

Trivy build replacements with matching structured CVE/component/target identity
keep the existing alert open across Finding ID and image tag/digest changes.
They do not produce a misleading `Fixed` followed by `New`. Different scopes or
targets remain separate; insufficient identity metadata keeps per-ID behavior.
Previously queued or delivered messages are not rewritten by the upgrade.

Setting `notifications.enabled=false` removes the notification workers and managed
MySQL workloads. With the default `retain_state=false`, its bootstrap pre-delete
hook then deletes the owned database PVC and generated credential/TLS Secret.
Delivery history and pending sends are lost; re-enabling sends all current
eligible Critical findings again with fresh Opsgenie identities. Historical
messages and remote alerts remain. Caller API/channel Secrets, the shared
retention token, external database data and the main DefectDojo installation are
untouched. Notification-only mode removes its own API Secret/bootstrap when
disabled, without revoking the underlying application-account token; this API
Secret cleanup also applies when database `retain_state=true`.

Use `retain_state=true` to preserve managed state across disabling. Apply this
policy (or a new module version's purge policy) **while enabled first**, then
disable in a separate apply: Helm uninstall uses the last installed hook settings.
Changing the flag and disabling together cannot update those hooks; `--no-hooks`
bypasses cleanup. Switching from managed to external MySQL removes the managed
releases under the same installed policy; apply `retain_state=true` while still
managed before migration if its data must survive. Bootstrap disables atomic
auto-uninstall so a failed install cannot automatically invoke purge; other
releases honor the module's `atomic` setting. PVC deletion follows storage
reclaim policy and `Retain` may leave its underlying PV/disk. See
[database lifecycle and recovery](../../README.md#database-lifecycle-and-recovery).

The single-instance database has no high availability or automatic backups. Back
up retained data together with its matching generated Secret; encrypted Secret
backups contain passwords/private keys and must stay out of source control/logs.
If a Secret is lost with an existing PVC, restore its matching backup rather than
regenerating passwords. See [TLS renewal](../../README.md#tls-expiry-and-renewal).

Treat database name, storage size and StorageClass as initial-provisioning
settings. Changes require explicit data migration or deliberate volume maintenance;
Terraform does not migrate schemas, switch existing storage backends or expand
immutable StatefulSet templates. Follow the
[database maintenance guidance](../../README.md#database-maintenance) before
changing these settings on an existing deployment.

## API token override and retention reuse

Enabled retention is reused automatically, including its configured Secret key;
no second notification token block is needed. The two API origins must match
(after scheme/hostname case, trailing slash and default-port normalization).
Otherwise the plan requires an explicit appropriate Secret, for example this
block inside `notifications`:

```hcl
api_token_secret = {
  name = "example-existing-api"
  key  = "api-key"
}
```

This explicit reference takes precedence over retention and creates no dedicated
notification token bootstrap. Automatic bootstrap uses the application account's
existing permissions, including retention deletion privileges; it is not a
read-only token. The bootstrap does not rotate/revoke the token or log in on every
poll. Keep `api_url` pointed at this module's DefectDojo instance for automatic
acquisition. Use a separately managed explicit Secret for stable ownership when
toggling retention/notifications independently; selection alone does not transfer
ownership of a notification-bootstrap-created Secret. See
[API token selection and ownership](../../README.md#api-token-selection-and-ownership).

## Existing external MySQL

To use a separately managed MySQL 8 schema/user, explicitly set
`notifications.mysql.create=false` and provide its host and credential Secret.
Managed mode rejects external connection/Secret overrides. For example:

```hcl
mysql = {
  create   = false
  host     = "mysql.example.com"
  database = "example_notifications"
  tls      = true
  credentials_secret = {
    name         = "example-notifier-mysql"
    username_key = "username"
    password_key = "password"
  }
  # Omit ca_secret when the server certificate uses a public system CA.
  ca_secret = {
    name = "example-notifier-mysql-ca"
    key  = "ca.crt"
  }
}
```

The example external credentials Secret contains `username` and `password`;
its optional CA Secret contains a PEM CA bundle in `ca.crt`. MySQL certificates
and hostnames are verified by default. `tls=false` is limited to isolated tests
or explicitly private transport with compatible native-password authentication;
the bundled driver does not include optional RSA crypto dependencies. A custom
CA requires TLS. The host is a plain DNS name or IPv4 address; database names
accept letters, digits and underscores.

External mode never deletes the separately managed database or its Secrets,
regardless of `retain_state`; it does not create MySQL or initialize tables
automatically. Its runtime user needs SELECT, INSERT and UPDATE on the dedicated
notification schema; initialization/upgrades additionally need CREATE.

Before upgrading an external database installation, suspend both CronJobs and
wait for every unfinished Job owned by them to finish. Suspension prevents new
scheduled Jobs; it does not stop Jobs already running. The following reviewed
maintenance commands identify ownership directly, without assuming Job labels:

```sh
kubectl -n example-security patch cronjob example-defectdojo-notifications-poll \
  --type=merge -p '{"spec":{"suspend":true}}'
kubectl -n example-security patch cronjob example-defectdojo-notifications-digest \
  --type=merge -p '{"spec":{"suspend":true}}'
python3 - <<'PY'
import json
import subprocess
import time

owners = {'example-defectdojo-notifications-poll', 'example-defectdojo-notifications-digest'}
deadline = time.monotonic() + 3900
while True:
    jobs = json.loads(subprocess.check_output(
        ['kubectl', '-n', 'example-security', 'get', 'jobs', '-o', 'json']))['items']
    pending = []
    for job in jobs:
        owned = any(ref.get('kind') == 'CronJob' and ref.get('name') in owners
                    for ref in job['metadata'].get('ownerReferences', []))
        status = job.get('status', {})
        finished = any(condition.get('type') in {'Complete', 'Failed'}
                       and condition.get('status') == 'True'
                       for condition in status.get('conditions', []))
        if owned and (not finished or status.get('active', 0)):
            pending.append(job['metadata']['name'])
    if not pending:
        break
    if time.monotonic() >= deadline:
        raise SystemExit('Jobs still unfinished; do not upgrade: ' + ', '.join(pending))
    time.sleep(5)
PY
```

Investigate failed Jobs, then apply the updated module while keeping it enabled
and both CronJobs suspended. Confirm the upgraded CronJobs remain suspended
before initialization. Run a reviewed one-off `init-db` Job with CREATE
permission by cloning the **updated** poll CronJob. It inherits the current
image, bundled source/dependencies, policy, Secret mounts and security settings,
adding history-generation metadata while preserving existing state. Cloning an
old CronJob before the upgrade runs old code and does not upgrade the schema.

For a fresh external installation, use the same suspension/drain procedure as
soon as the CronJobs exist, initialize, then resume. Until schema/generation
initialization succeeds, scheduled workers fail closed before sending. Do not
disable the managed module simply to pause scheduling: its default teardown
purges notification history.

```sh
kubectl -n example-security get cronjob \
  example-defectdojo-notifications-poll example-defectdojo-notifications-digest \
  -o json | python3 -c 'import json,sys; jobs=json.load(sys.stdin)["items"]; assert len(jobs)==2 and all(job["spec"].get("suspend", False) for job in jobs), "Both CronJobs must remain suspended"'
kubectl -n example-security create job example-notifications-init \
  --from=cronjob/example-defectdojo-notifications-poll \
  --dry-run=client -o json > /tmp/example-notifications-init.json
python3 - <<'PY'
import json
from pathlib import Path
path = Path('/tmp/example-notifications-init.json')
job = json.loads(path.read_text())
job['spec']['template']['spec']['containers'][0]['command'] = ['python', '-m', 'notifier', 'init-db']
path.write_text(json.dumps(job, indent=2) + '\n')
PY
kubectl apply --dry-run=server -f /tmp/example-notifications-init.json
kubectl apply -f /tmp/example-notifications-init.json
kubectl -n example-security wait --for=condition=complete \
  job/example-notifications-init --timeout=3600s
```

Inspect the generated manifest before applying. `init-db` initializes tables
without sending notifications. The `kubectl --dry-run` flags above validate
the Job manifest; they do not change notification behavior. Restore the runtime
Secret if you temporarily used schema-creation credentials. Confirm successful
initialization and continued suspension, then resume both schedules:

```sh
kubectl -n example-security get cronjob \
  example-defectdojo-notifications-poll example-defectdojo-notifications-digest \
  -o json | python3 -c 'import json,sys; jobs=json.load(sys.stdin)["items"]; assert len(jobs)==2 and all(job["spec"].get("suspend", False) for job in jobs), "Both CronJobs must remain suspended"'
kubectl -n example-security patch cronjob example-defectdojo-notifications-poll \
  --type=merge -p '{"spec":{"suspend":false}}'
kubectl -n example-security patch cronjob example-defectdojo-notifications-digest \
  --type=merge -p '{"spec":{"suspend":false}}'
```

Resumed schedules perform real persistence and delivery. Managed mode performs
schema initialization automatically through its install/upgrade hook.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_defectdojo"></a> [defectdojo](#module\_defectdojo) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_notification_channels"></a> [notification\_channels](#input\_notification\_channels) | Direct credentials for at least one destination. Set only slack\_webhook\_url for Slack-only, optionally teams\_webhook\_url and/or opsgenie\_api\_key. One Opsgenie integration authenticates findings and P5 summaries; paging depends on its rules. Terraform and Helm state store the credentials. | <pre>object({<br/>    slack_webhook_url = optional(string, "")<br/>    teams_webhook_url = optional(string, "")<br/>    opsgenie_api_key  = optional(string, "")<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_notifications"></a> [notifications](#output\_notifications) | Nonsecret identifiers for the companion notification deployment. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
