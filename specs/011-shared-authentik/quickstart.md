# Quickstart: Shared Authentik module

1. Use the standard database module to create the PostgreSQL database, user,
   and grants. This module does not create them.
2. Ensure the deployment namespace already exists, normally through
   `modules/namespace`.
3. Have the approved secret-management mechanism create a Secret in that
   namespace with these keys (values never belong in Terraform):

   - `AUTHENTIK_SECRET_KEY`
   - `AUTHENTIK_POSTGRESQL__PASSWORD`

4. Configure `modules/authentik` with the Secret name and non-secret database
   endpoint metadata.
5. Configure the cluster's normal ingress module separately against
   `server_service_name` and `server_service_http_port` outputs.
6. Complete Authentik providers, applications, groups, and proxy policies using
   Authentik-native configuration after the release is healthy.
