# Quickstart: consume the CNPG module

1. Install CloudNativePG and verify the `postgresql.cnpg.io/v1` CRD.
2. Create the namespace separately.
3. Use the approved secret-management path to materialize a
   `kubernetes.io/basic-auth` Secret in that namespace, with `username` equal
   to the module's database owner and a `password` key.
4. Configure the module with explicit instances, storage class, storage size,
   and the existing Secret name. Configure object-store backup only after its
   separate credentials Secret and bucket policy exist.
5. Apply the module, then wait for readiness before applying a dependent
   workload:

   ```sh
   kubectl wait --for=condition=Ready \
     clusters.postgresql.cnpg.io/<cluster-name> \
     --namespace <namespace> --timeout=15m
   ```

6. Configure the application to use the output read/write Service hostname,
   port, database, and owner. Sync the matching password through the approved
   secret-management mechanism.
