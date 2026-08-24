locals {
  bootstrap_users = [
    for user in var.bootstrap_users : {
      username                = user.username
      password                = user.password
      key_prefix              = coalesce(user.key_prefix, "${user.username}/")
      home_dir                = coalesce(user.home_dir, "/var/lib/sftpgo/${user.username}")
      require_password_change = user.require_password_change
    }
  ]

  bootstrap_command = <<-EOT
import base64
import json
import os
import time
import urllib.error
import urllib.request

base_url = "http://127.0.0.1:8080"
admin_username = os.environ["SFTPGO_ADMIN_USERNAME"]
admin_password = os.environ["SFTPGO_ADMIN_PASSWORD"]
users = json.loads(os.environ.get("SFTPGO_BOOTSTRAP_USERS", "[]"))


def request(method, path, token=None, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(base_url + path, data=data, method=method)
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    else:
        credentials = f"{admin_username}:{admin_password}".encode()
        req.add_header("Authorization", "Basic " + base64.b64encode(credentials).decode())
    if payload is not None:
        req.add_header("Content-Type", "application/json")
    return urllib.request.urlopen(req, timeout=10)


def secret(value):
    return {"status": "Plain", "payload": value}


token = None
for _ in range(60):
    try:
        with request("GET", "/api/v2/token") as response:
            token = json.load(response)["access_token"]
            break
    except Exception:
        time.sleep(5)
if not token:
    raise RuntimeError("SFTPGo API did not become ready for bootstrap")

for user in users:
    username = user["username"]
    s3config = {
        "bucket": os.environ["SFTPGO_BOOTSTRAP_S3_BUCKET"],
        "region": os.environ["SFTPGO_BOOTSTRAP_S3_REGION"],
        "access_key": os.environ["SFTPGO_BOOTSTRAP_S3_ACCESS_KEY"],
        "access_secret": secret(os.environ["SFTPGO_BOOTSTRAP_S3_ACCESS_SECRET"]),
        "key_prefix": user["key_prefix"],
    }
    if os.environ.get("SFTPGO_BOOTSTRAP_S3_ENDPOINT"):
        s3config["endpoint"] = os.environ["SFTPGO_BOOTSTRAP_S3_ENDPOINT"]
    if os.environ.get("SFTPGO_BOOTSTRAP_S3_FORCE_PATH_STYLE"):
        s3config["force_path_style"] = os.environ["SFTPGO_BOOTSTRAP_S3_FORCE_PATH_STYLE"].lower() == "true"

    payload = {
        "status": 1,
        "username": username,
        "password": user["password"],
        "filters": {
            "require_password_change": user["require_password_change"],
        },
        "home_dir": user["home_dir"],
        "permissions": {"/": ["*"]},
        "filesystem": {
            "provider": 1,
            "s3config": s3config,
        },
    }
    try:
        with request("GET", f"/api/v2/users/{username}", token=token) as response:
            existing = json.load(response)
        existing.pop("password", None)
        existing.update({
            "status": payload["status"],
            "home_dir": payload["home_dir"],
            "permissions": payload["permissions"],
            "filesystem": payload["filesystem"],
        })
        request("PUT", f"/api/v2/users/{username}", token=token, payload=existing).close()
        print(f"user {username} updated")
        continue
    except urllib.error.HTTPError as error:
        if error.code != 404:
            print(error.read().decode())
            raise

    try:
        request("POST", "/api/v2/users", token=token, payload=payload).close()
    except urllib.error.HTTPError as error:
        print(error.read().decode())
        raise
    print(f"user {username} created")

while True:
    time.sleep(3600)
EOT

  bootstrap_env = [
    {
      name  = "SFTPGO_ADMIN_USERNAME"
      value = var.admin.username
    },
    {
      name  = "SFTPGO_ADMIN_PASSWORD"
      value = var.admin.password
    },
    {
      name  = "SFTPGO_BOOTSTRAP_S3_ACCESS_KEY"
      value = var.s3_storage.access_key
    },
    {
      name  = "SFTPGO_BOOTSTRAP_S3_ACCESS_SECRET"
      value = var.s3_storage.access_secret
    },
    {
      name  = "SFTPGO_BOOTSTRAP_S3_BUCKET"
      value = var.s3_storage.bucket
    },
    {
      name  = "SFTPGO_BOOTSTRAP_S3_REGION"
      value = var.s3_storage.region
    },
    {
      name  = "SFTPGO_BOOTSTRAP_USERS"
      value = jsonencode(local.bootstrap_users)
    },
  ]

  bootstrap_optional_env = concat(
    var.s3_storage.endpoint != null ? [
      {
        name  = "SFTPGO_BOOTSTRAP_S3_ENDPOINT"
        value = var.s3_storage.endpoint
      }
    ] : [],
    var.s3_storage.force_path_style != null ? [
      {
        name  = "SFTPGO_BOOTSTRAP_S3_FORCE_PATH_STYLE"
        value = tostring(var.s3_storage.force_path_style)
      }
    ] : []
  )

  persistence_values = {
    persistence = merge(
      {
        enabled = var.persistence.enabled
      },
      {
        for key, value in {
          pvc = merge(
            {
              accessModes = var.persistence.access_modes
              resources = {
                requests = {
                  storage = var.persistence.storage
                }
              }
            },
            var.persistence.storage_class_name != null ? {
              storageClassName = var.persistence.storage_class_name
            } : {}
          )
        } : key => value if var.persistence.enabled
      }
    )
  }

  web_session_values = var.web_session == null ? {} : {
    httpd = {
      signing_passphrase = var.web_session.signing_passphrase
      cookie_lifetime    = var.web_session.cookie_lifetime
      token_validation   = var.web_session.token_validation
    }
  }

  chart_values = merge(
    {
      replicaCount = var.replica_count
      config = merge(
        {
          common = {
            setstat_mode = 2
          }
          data_provider = {
            create_default_admin = var.admin.enabled
          }
        },
        local.web_session_values
      )
      env = {
        AWS_ACCESS_KEY_ID             = var.s3_storage.access_key
        AWS_DEFAULT_REGION            = var.s3_storage.region
        AWS_REGION                    = var.s3_storage.region
        AWS_SECRET_ACCESS_KEY         = var.s3_storage.access_secret
        SFTPGO_DEFAULT_ADMIN_USERNAME = var.admin.username
        SFTPGO_DEFAULT_ADMIN_PASSWORD = var.admin.password
      }
      extraContainers = [
        {
          name            = "user-bootstrap"
          image           = var.bootstrap_image
          imagePullPolicy = "IfNotPresent"
          command         = ["python", "-c", local.bootstrap_command]
          env             = concat(local.bootstrap_env, local.bootstrap_optional_env)
        }
      ]
      resources          = var.resources
      deploymentStrategy = var.strategy
      imagePullSecrets   = var.image_pull_secrets
    },
    local.persistence_values,
    var.extra_values
  )
}
