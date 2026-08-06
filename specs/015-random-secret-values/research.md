# Research: Reusable random secret values module

## Decision: Use `random_password` directly

**Rationale**: The Terraform Random provider owns stable random lifecycle
state. A direct, narrow wrapper avoids adding a cloud provider or a secret-store
dependency to a value-generation module.

**Alternatives considered**:

- Extend the AWS Secret module: rejected because generation and persistence are
  independently useful responsibilities.
- Generate credentials in CNPG: rejected because CNPG deliberately consumes an
  existing Kubernetes bootstrap Secret and must not own AWS Secret Manager.
- Manual Secret Manager values: rejected because it leaves a mandatory,
  error-prone bootstrap step.

## Decision: Expose one sensitive map

**Rationale**: Downstream secret-store modules need a structured payload. One
sensitive output avoids accidental publication of individual values and supports
the existing AWS Secret module's `value` input.

**Alternatives considered**:

- One output per value: rejected because it broadens interface and encourages
  consumers to wire secrets individually.
- Non-sensitive map: rejected because it would expose credentials in plans and
  Terraform Cloud outputs.

## Decision: Support static values and single-level aliases

**Rationale**: A password may need both a database key and an application key,
while names such as a database owner are metadata that belongs in the same
payload. Explicit aliases preserve one generated password.

**Alternatives considered**:

- Two independent generated passwords: rejected because consumers requiring a
  shared credential would fail.
- Expression templates: rejected because they create a broad and unsafe
  evaluation interface.
