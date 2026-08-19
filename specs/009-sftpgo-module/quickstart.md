# Quickstart: SFTPGo Terraform Module

## Validation Flow

1. Format the new module and validation fixtures:

   ```bash
   terraform fmt -recursive modules/sftpgo
   ```

2. Initialize and validate the module:

   ```bash
   terraform -chdir=modules/sftpgo init -backend=false
   terraform -chdir=modules/sftpgo validate
   ```

3. Initialize and validate the basic example:

   ```bash
   terraform -chdir=modules/sftpgo/examples/basic init -backend=false
   terraform -chdir=modules/sftpgo/examples/basic validate
   ```

4. Initialize and validate the basic test fixture:

   ```bash
   terraform -chdir=modules/sftpgo/tests/basic init -backend=false
   terraform -chdir=modules/sftpgo/tests/basic validate
   ```

## Expected Consumer Flow

1. Configure Helm and Kubernetes providers for an existing cluster.
2. Provide S3 bucket, region, access key, and sensitive access secret.
3. Provide sensitive admin password and one or more bootstrap user passwords.
4. Configure persistence, resources, and optional UI ingress.
5. Apply the module to install SFTPGo through Helm.
