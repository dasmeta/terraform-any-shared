# defectdojo

Deploys DefectDojo into Kubernetes with an opinionated Helm-based baseline.
Use this module when you need a shared security-testing installation with a
small input surface and override-friendly chart configuration.

See the [notification example](examples/notifications) for configuration and
delivery behavior, including the known reimport-completion limitation.

Set `notifications.opsgenie_title_prefix` to a client or service label such as
`"Example Security:"` to prefix Opsgenie finding and daily summary titles only.
The default empty string preserves existing titles. The prefix must be trimmed,
contain no control characters and be at most 80 Unicode code points; the complete title
retains the existing 130-character limit. Tags, descriptions, Slack/Teams messages
and MySQL event identities/history are unchanged. The setting applies when queued
notifications are dispatched; previously delivered alerts are not renamed or replayed.

Daily Opsgenie summaries use one P5 alert per nonempty Engagement/date, with
open/new/fixed counts, up to five oldest findings and a link to the full list.
Slack retains its existing card and Teams its complete numbered lists. Existing
daily snapshots and queued multipart summaries are preserved; the compact format
is used for newly created snapshots after the worker release is updated.

## Database lifecycle and recovery

Notifications use a dedicated single-instance MySQL 8.4 by default. There is no
high availability or automatic backup. Back up the database/PVC and its matching
`<app>-notifications-mysql-credentials` Secret together using encrypted storage.
That Secret contains `username`, `password`, `root-password`, `ca.crt`, `tls.crt`
and `tls.key`; backups contain passwords and a private key. Never print them,
commit them, or place them in logs. A volume snapshot alone is insufficient.

Disabling notifications removes workers and managed MySQL. The default
`retain_state=false` pre-delete hook also deletes the managed PVC and generated
Secret: history and pending sends are lost, and re-enabling sends the current
eligible Critical backlog again with fresh Opsgenie identities. Remote alerts
and messages remain. Caller-owned API/channel Secrets, shared retention tokens,
external MySQL data and the main DefectDojo installation are unaffected.

To preserve history, apply `retain_state=true` **while notifications are enabled**,
then disable in a separate apply. Uninstall uses the last installed hook policy;
changing retention and disabling together does not update it. The same rule
applies before switching managed MySQL to external mode. Storage reclaim policy
can retain an underlying PV/disk even after PVC deletion. Bypassing Helm hooks
also bypasses cleanup. Owned channel and notification-only API Secrets are
removed independently of database retention.

Restore a consistent database/PVC plus its matching Secret in the original
namespace and resource names, preserving the Secret's Helm ownership metadata,
before re-enabling. Keep workers suspended until schema/TLS checks succeed.
An existing PVC with missing/empty credentials fails closed; restore the matching
Secret instead of regenerating passwords against an existing database. Partial,
malformed or foreign Secrets also fail closed. Do not reset/delete the Secret
as a repair. Ordinary bootstrap requires unexpired TLS. The renewal procedure
below requires the bootstrap Helm release and its ServiceAccount, RBAC and
ConfigMap to remain installed. If they are present, renew expired certificates
before normal bootstrap. After disabling a retained installation those resources
are removed: `helm get hooks` cannot renew a detached Secret. Stop and prepare a
reviewed recovery that restores the bootstrap prerequisites and matching state
before renewal; do not re-enable normally or regenerate database passwords.

## Database maintenance

Treat database name, storage size and StorageClass as provisioning settings.
Terraform does not migrate schemas or data, switch existing storage backends, or
expand immutable StatefulSet volume templates. Plan a backed-up migration or
explicit storage maintenance for an existing database. Review MySQL image/version
compatibility before upgrading; the managed hook initializes schema automatically.
External MySQL needs a reviewed `init-db` run on installation and schema upgrades:
runtime grants are SELECT/INSERT/UPDATE, while initialization also requires CREATE.
The managed user already has the schema grants needed for `init-db`.

Use the following shared pause/drain procedure before maintenance or renewal.
Prerequisites: Bash, Python 3, `kubectl`, cluster access and an exclusive maintenance
window; do not concurrently apply Helm/Terraform or start manual worker Jobs.
Run the snippets in the same Bash session. Do not use `enabled=false` to pause:
its default teardown purges history. For TLS renewal, pause/drain here, then run
the renewal section **before** the smoke check and resume steps.

```bash
set -euo pipefail
umask 077
export NS=example-security APP=example-defectdojo
export WORKER="${APP}-notifications"
export MAINT_DIR
MAINT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/example-notifications.XXXXXX")
chmod 700 "$MAINT_DIR"
kubectl -n "$NS" get cronjob "$WORKER-poll" "$WORKER-digest" \
  -o json > "$MAINT_DIR/cronjobs-before.json"
python3 - <<'PY'
import json, os, subprocess, time
from pathlib import Path
p = Path(os.environ['MAINT_DIR'])
ns, worker = os.environ['NS'], os.environ['WORKER']
jobs = json.loads((p / 'cronjobs-before.json').read_text())['items']
assert {j['metadata']['name'] for j in jobs} == {worker+'-poll', worker+'-digest'}
states = {j['metadata']['name']: j['spec'].get('suspend', False) for j in jobs}
(p / 'suspend-before.json').write_text(json.dumps(states))
def kube(*args):
    return subprocess.check_output(['kubectl', '-n', ns, *args])
for name in states:
    kube('patch', 'cronjob', name, '--type=merge', '-p', '{"spec":{"suspend":true}}')
labels = {'app.kubernetes.io/name': 'defectdojo-notifications',
          'app.kubernetes.io/instance': worker}
selector = ','.join(k+'='+v for k, v in labels.items())
deadline = time.monotonic() + 3900
while True:
    # Inspect pod-template labels too: a manual/retrying Job may have no Pod yet.
    pending = []
    for job in json.loads(kube('get', 'jobs', '-o', 'json'))['items']:
        template = job['spec']['template'].get('metadata', {}).get('labels', {})
        if not all(template.get(k) == v for k, v in labels.items()):
            continue
        status = job.get('status', {})
        done = any(c.get('type') in ('Complete', 'Failed') and c.get('status') == 'True'
                   for c in status.get('conditions', []))
        if not done or status.get('active', 0):
            pending.append(job['metadata']['name'])
    pods = json.loads(kube('get', 'pods', '-l', selector, '-o', 'json'))['items']
    pending += [p['metadata']['name'] for p in pods
                if p.get('status', {}).get('phase') not in ('Succeeded', 'Failed')]
    if not pending:
        break
    if time.monotonic() >= deadline:
        raise SystemExit('Workers have not drained; keep suspended and investigate: '+', '.join(pending))
    time.sleep(5)
PY
```

This waits for all labeled worker Pods and unfinished Jobs, including manually
created Jobs, rather than relying only on CronJob ownership. Investigate failed
Jobs before proceeding. Keep the saved directory and original suspension flags;
rerunning setup would overwrite the intended resume state with `true`.
If upgrading, keep notifications enabled, recheck that both CronJobs remain
suspended after the apply, and use the **updated** poll CronJob for this smoke
check. Review any changed maintenance manifests before applying them.

The following one-off `init-db` checks schema and the configured connection
without sending alerts. With managed TLS it verifies CA, hostname and negotiated
cipher through PyMySQL. It retains worker Pod labels required by NetworkPolicy,
images, policy, source/dependencies and Secret mounts. External mode requires
CREATE permission; restore any temporary elevated credentials before resuming.

```bash
kubectl -n "$NS" get cronjob "$WORKER-poll" "$WORKER-digest" -o json \
  | python3 -c 'import json,sys; j=json.load(sys.stdin)["items"]; assert len(j)==2 and all(x["spec"].get("suspend",False) for x in j), "Keep both CronJobs suspended"'
export SMOKE_JOB="${WORKER}-check-$(date +%s)"
kubectl -n "$NS" create job "$SMOKE_JOB" --from="cronjob/$WORKER-poll" \
  --dry-run=client -o json > "$MAINT_DIR/smoke.json"
python3 - <<'PY'
import json, os
from pathlib import Path
p = Path(os.environ['MAINT_DIR']) / 'smoke.json'
j = json.loads(p.read_text())
containers = j['spec']['template']['spec']['containers']
assert len(containers) == 1 and containers[0]['name'] == 'poll'
containers[0]['command'] = ['python', '-m', 'notifier', 'init-db']
p.write_text(json.dumps(j, indent=2)+'\n')
PY
kubectl apply --dry-run=server -f "$MAINT_DIR/smoke.json"
kubectl create -f "$MAINT_DIR/smoke.json"
kubectl -n "$NS" wait --for=condition=complete "job/$SMOKE_JOB" --timeout=3600s
kubectl -n "$NS" logs "job/$SMOKE_JOB"
```

Require successful completion with `initialized: true`. Do not substitute a
`poll`/`digest` run: those send real notifications. **On any renewal, restart,
initialization or smoke failure, keep both schedules suspended and investigate.**
Only after success, restore each saved flag (including an intentional prior
suspension); resumed schedules persist state and deliver messages:

```bash
python3 - <<'PY'
import json, os, subprocess
from pathlib import Path
states = json.loads((Path(os.environ['MAINT_DIR']) / 'suspend-before.json').read_text())
for name, suspended in states.items():
    subprocess.run(['kubectl', '-n', os.environ['NS'], 'patch', 'cronjob', name,
                    '--type=merge', '-p', json.dumps({'spec': {'suspend': suspended}})], check=True)
PY
```

## TLS expiry and renewal

Managed MySQL uses a generated CA valid for 3650 days and server certificate
valid for 365 days. Monitor both expirations and renew manually before expiry;
there is no automatic renewal. Normal install/upgrade bootstrap reuses a complete
valid Secret and does not rotate it. The explicit `renew-tls` path accepts old
expired PEM material, validates the replacement, and patches only `ca.crt`,
`tls.crt`, `tls.key`, preserving `username`, `password` and `root-password`.
The generator creates a **new CA on every renewal** and discards its private key;
both the database and clients must load the new trust material.

After the maintenance pause/drain above, take a current database backup and this
Secret backup. Keep the directory mode 0700 and files 0600, encrypt/archive the
backup securely and never print the JSON or private key. Inspect certificate
dates without displaying Secret values:

```bash
export DB="${APP}-notifications-mysql" INIT="${APP}-notifications-db-init"
export SECRET="${DB}-credentials"
kubectl -n "$NS" get secret "$SECRET" -o json > "$MAINT_DIR/secret-before.json"
chmod 600 "$MAINT_DIR/secret-before.json"
python3 - <<'PY'
import base64, json, os
from pathlib import Path
p = Path(os.environ['MAINT_DIR'])
s = json.loads((p / 'secret-before.json').read_text())
assert set(s['data']) == {'username','password','root-password','ca.crt','tls.crt','tls.key'}
for key in ('ca.crt', 'tls.crt'):
    (p / key).write_bytes(base64.b64decode(s['data'][key], validate=True))
PY
openssl x509 -in "$MAINT_DIR/ca.crt" -noout -dates
openssl x509 -in "$MAINT_DIR/tls.crt" -noout -dates
```

The installed bootstrap hook is `$INIT-bootstrap`; Helm normally deletes it on
success (`before-hook-creation,hook-succeeded`). Do not assume a Job exists to
clone, and `kubectl create job --from=job/...` is unsupported. Prerequisite:
Ruby with its standard YAML/JSON libraries. Extract **only** the installed
bootstrap Job from Helm hook manifests, preserving its TLS init container,
images, ServiceAccount/scoped RBAC references, policy and volume mounts. The
following creates a plain fresh Job, discards hook metadata, and changes only the
bootstrap command. Never run a cleanup hook/worker or uninstall for renewal.

```bash
helm get hooks "$INIT" -n "$NS" > "$MAINT_DIR/hooks.yaml"
export RENEW_JOB="${APP}-tls-renew-$(date +%s)"
ruby -ryaml -rjson - "$MAINT_DIR/hooks.yaml" > "$MAINT_DIR/renew.json" <<'RUBY'
docs = YAML.load_stream(File.read(ARGV.fetch(0))).compact
matches = docs.select { |d| d['kind'] == 'Job' &&
  d.dig('metadata','name') == ENV.fetch('INIT')+'-bootstrap' &&
  d.dig('metadata','annotations','helm.sh/hook') == 'post-install,post-upgrade' }
abort 'Expected exactly one installed bootstrap hook' unless matches.length == 1
j = matches.first
pod = j.fetch('spec').fetch('template').fetch('spec')
abort 'Unexpected ServiceAccount' unless pod['serviceAccountName'] == ENV.fetch('INIT')
abort 'Unexpected TLS init container' unless pod.fetch('initContainers').map { |c| c['name'] } == ['candidate-tls']
c = pod.fetch('containers')
abort 'Unexpected bootstrap container' unless c.length == 1 && c[0]['name'] == 'bootstrap' &&
  c[0]['command'] == ['python','-B','/config/bootstrap.py']
j['metadata'] = {'name'=>ENV.fetch('RENEW_JOB'), 'namespace'=>ENV.fetch('NS')}
c[0]['command'] = ['python','-B','/config/bootstrap.py','renew-tls']
puts JSON.pretty_generate(j)
RUBY
kubectl apply --dry-run=server -f "$MAINT_DIR/renew.json"
# Review renew.json locally: it must contain only the intended renewal Job.
kubectl create -f "$MAINT_DIR/renew.json"
kubectl -n "$NS" wait --for=condition=complete "job/$RENEW_JOB" --timeout=660s
kubectl -n "$NS" logs "job/$RENEW_JOB" -c bootstrap
kubectl -n "$NS" get secret "$SECRET" -o json > "$MAINT_DIR/secret-after.json"
python3 - <<'PY'
import json, os
from pathlib import Path
p = Path(os.environ['MAINT_DIR'])
a, b = [json.loads((p / ('secret-'+phase+'.json')).read_text()) for phase in ('before','after')]
assert a['metadata']['uid'] == b['metadata']['uid'], 'Secret was replaced; keep suspended'
assert set(a['data']) == set(b['data']), 'Secret fields changed unexpectedly'
assert all(a['data'][k] == b['data'][k] for k in ('username','password','root-password')), 'Credentials changed'
assert all(a['data'][k] != b['data'][k] for k in ('ca.crt','tls.crt','tls.key')), 'TLS was not replaced'
print('Same Secret UID and credentials; all three TLS fields replaced')
PY
```

Require `reason: renewed` and all assertions passing. Only the generated
credentials/TLS Secret is rotated; do not reset it or touch API/channel Secrets.
Secret volume updates project new files, but `mysqld` does **not** automatically
reload TLS. While workers remain suspended/drained, restart the single managed
StatefulSet and wait for readiness; this causes a brief database outage. Its
`mysql` container mounts the Secret at `/run/mysql-secrets`.

```bash
kubectl -n "$NS" rollout restart "statefulset/$DB"
kubectl -n "$NS" rollout status "statefulset/$DB" --timeout=900s
```

Now run the maintenance `init-db` smoke check above using the current poll
CronJob, whose new Pod loads the new CA from the Secret, then restore the original
suspend flags only after success. Update any other authorized clients' trust
stores to the new CA before reconnecting. Retain the paired backup securely;
recovery after a failed renewal must keep database/server/client trust consistent.
The exact implementation is in
[bootstrap resources](charts/notifications-mysql-bootstrap/templates/resources.yaml),
[bootstrap worker](charts/notifications-mysql-bootstrap/files/bootstrap.py),
[TLS generator](charts/notifications-mysql-bootstrap/files/generate-tls.sh) and
[MySQL resources](charts/notifications-mysql/templates/resources.yaml).

## API token selection and ownership

Notifications select credentials in this order: explicit
`notifications.api_token_secret.name/key`, otherwise enabled retention's actual
Secret/key when API origins match, otherwise a notification-owned
`<app>-notifications-api` bootstrap from this module's application account.
Origin comparison normalizes hostname/scheme case, trailing slash and default
ports; different origins require an explicit suitable Secret. Automatic bootstrap
must target this module's DefectDojo installation.

The application-account token can carry retention's deletion privileges; it is
not a read-only notification token. Use an explicitly managed Secret with a
separate suitably restricted account when narrower privileges or stable ownership
are needed. Selecting a bootstrap-created Secret explicitly does not transfer
its ownership. Notification-only bootstrap/Secret cleanup occurs when disabled,
even with database retention; shared retention and caller-owned Secrets are not
deleted. There is no automatic rotation/revocation, and deleting the generated
Secret does not revoke the underlying account token. Plan account/token rotation
and independent retention/notification toggles with the Secret owner.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.notifications](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.notifications_api_bootstrap](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.notifications_mysql](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.notifications_mysql_bootstrap](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.retention](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.retention_bootstrap](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atomic"></a> [atomic](#input\_atomic) | If set, the installation process will be rolled back on failure. | `bool` | `false` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The DefectDojo Helm chart version to use. | `string` | `"1.9.64"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace if it does not exist. | `bool` | `true` | no |
| <a name="input_custom_configs"></a> [custom\_configs](#input\_custom\_configs) | Additional or override values for the Helm chart. Merged on top of default\_configs. See https://artifacthub.io/packages/helm/defectdojo/defectdojo?modal=values | `any` | `{}` | no |
| <a name="input_default_configs"></a> [default\_configs](#input\_default\_configs) | Default values to pass to the Helm chart. Override specific fields via custom\_configs. | `any` | <pre>{<br/>  "createPostgresqlSecret": true,<br/>  "createSecret": true,<br/>  "createValkeySecret": true<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"defectdojo"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace to install DefectDojo. | `string` | `"defectdojo"` | no |
| <a name="input_notifications"></a> [notifications](#input\_notifications) | Critical main-branch Trivy notifications, automatically enabled by a configured channel or channels Secret when enabled is omitted; enabled=false explicitly disables and enabled=true requires complete valid configuration. Deliver to any combination of Slack, Teams and Opsgenie, using a dedicated managed MySQL outbox by default. Enabled scheduled jobs persist state and send real notifications. Requires Kubernetes >=1.27 and exactly one channel source: an existing channels\_secret or direct channels values for at least one destination. Slack, Teams and Opsgenie are independent; one Opsgenie integration key authenticates findings and P5 summaries. Direct values use sensitive Helm settings but are stored in Terraform/Helm state; their owned Secret is removed with the worker release independently of retain\_state. API token selection prefers an explicit Secret, otherwise matching-origin retention credentials, otherwise automatic application-account bootstrap. Source and bundled dependencies run in a public Python image; use mysql.create=false for an external MySQL and its existing credentials/CA Secrets. Choose engagement\_ids or explicit all\_engagements=true. Managed provisioning initializes tables. Disabling purges managed PVC/credentials by default and reenabling resends the current Critical backlog; explicitly set retain\_state=true to preserve history. Uninstall uses the last installed hook policy, so apply retention changes while enabled before disabling. External MySQL and shared/caller API/channel Secrets are never purged. Notification-only API token Secrets are removed with their bootstrap without revoking the token. P5 Opsgenie summaries may page depending on integration rules. | <pre>object({<br/>    enabled         = optional(bool)<br/>    retain_state    = optional(bool, false)<br/>    image           = optional(string, "python:3.12-slim@sha256:b18b261e1b4974b4f321451ad5251ded85abb22c2b8b262da527dda1d031ab30")<br/>    api_url         = optional(string, "")<br/>    engagement_ids  = optional(set(number), [])<br/>    all_engagements = optional(bool, false)<br/>    poll_schedule   = optional(string, "0 * * * *")<br/>    digest_schedule = optional(string, "30 13 * * *")<br/>    time_zone       = optional(string, "UTC")<br/>    api_token_secret = optional(object({<br/>      name = optional(string, "")<br/>      key  = optional(string, "api-key")<br/>    }), {})<br/>    mysql = optional(object({<br/>      create        = optional(bool, true)<br/>      image         = optional(string, "mysql:8.4@sha256:a81d043930e51745522bd5c430961cf8286f0a23f0a9a2a6e0108f7ea71b0902")<br/>      storage_size  = optional(string, "8Gi")<br/>      storage_class = optional(string)<br/>      host          = optional(string, "")<br/>      port          = optional(number, 3306)<br/>      database      = optional(string, "defectdojo_notifications")<br/>      tls           = optional(bool, true)<br/>      credentials_secret = optional(object({<br/>        name         = optional(string, "")<br/>        username_key = optional(string, "username")<br/>        password_key = optional(string, "password")<br/>      }), {})<br/>      ca_secret = optional(object({<br/>        name = optional(string, "")<br/>        key  = optional(string, "ca.crt")<br/>      }), {})<br/>    }), {})<br/>    channels = optional(object({<br/>      slack_webhook_url = optional(string, "")<br/>      teams_webhook_url = optional(string, "")<br/>      opsgenie_api_key  = optional(string, "")<br/>    }), {})<br/>    channels_secret = optional(object({<br/>      name         = optional(string, "")<br/>      slack_key    = optional(string, "slack-url")<br/>      teams_key    = optional(string, "teams-url")<br/>      opsgenie_key = optional(string, "opsgenie-key")<br/>    }), {})<br/>    opsgenie_title_prefix = optional(string, "")<br/>    opsgenie_region       = optional(string, "us")<br/>    priority              = optional(string, "P2")<br/>  })</pre> | `{}` | no |
| <a name="input_retention"></a> [retention](#input\_retention) | Opt-in cleanup of inactive completed Trivy feature Tests without active findings. Select exactly one of engagement\_ids, exact unique engagement\_names or explicit all\_engagements. Requires Kubernetes >=1.27 and API base URL. Supply an existing API token Secret or enable api\_token\_secret.create to bootstrap one from the chart account. See README for permissions and concurrency limitations. | <pre>object({<br/>    enabled   = optional(bool, false)<br/>    days      = optional(number, 30)<br/>    schedule  = optional(string, "17 2 * * *")<br/>    time_zone = optional(string, "Etc/UTC")<br/>    api_url   = optional(string, "")<br/>    api_token_secret = optional(object({<br/>      create = optional(bool, false)<br/>      name   = optional(string, "")<br/>      key    = optional(string, "api-key")<br/>    }), {})<br/>    engagement_ids         = optional(set(number), [])<br/>    engagement_names       = optional(set(string), [])<br/>    all_engagements        = optional(bool, false)<br/>    protected_branches     = optional(set(string), [])<br/>    protected_environments = optional(set(string), [])<br/>    max_tests_per_run      = optional(number, 10)<br/>  })</pre> | `{}` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Wait for the release to be deployed successfully. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | DefectDojo Helm release metadata |
| <a name="output_notifications"></a> [notifications](#output\_notifications) | Nonsecret notification release, CronJob, effective API token Secret/key/source, MySQL connection/Secret references and state namespace identifiers; null when disabled. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
