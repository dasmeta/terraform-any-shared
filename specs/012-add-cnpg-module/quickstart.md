# Quickstart: consume the CNPG module

1. Use CloudNativePG 1.26 or later and verify that it serves the
   `postgresql.cnpg.io/v1` Cluster CRD.
2. Create the namespace separately.
3. Materialize a `kubernetes.io/basic-auth` Secret in that namespace using the
   approved secret-management path. Its `username` must equal the database
   owner and it must include a `password` key.
4. Configure explicit instances, storage class, storage size, and the existing
   Secret name. Do not provide credential values to Terraform.
5. Apply the module, then wait for CNPG before applying an application:

   ```sh
   kubectl wait --for=condition=Ready \
     clusters.postgresql.cnpg.io/<cluster-name> \
     --namespace <namespace> --timeout=15m
   ```

6. Use the `-rw` endpoint for writes and the `-ro` or `-r` endpoint for
   read-only workload traffic. Synchronize matching passwords through the
   approved secret-management mechanism.
