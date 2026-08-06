# Quickstart: Shared ExternalSecret module

1. Install External Secrets Operator v1 and create a SecretStore or ClusterSecretStore outside this module.
2. Store named properties under one provider-side remote key.
3. Configure this module with the target Secret name/type and only needed property mappings.
4. Apply and wait for the ExternalSecret `Ready` condition before deploying the consumer.
5. Verify target name and type only; never print Secret data.
