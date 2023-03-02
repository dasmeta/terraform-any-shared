## MongoDB BI Connector
This module creates a helm release for MongoDB BI Connector Helm chart.


## How to Use
All default values are set by Helm chart. You just need to pass auth parameters and URI for MongoDB to make it work.
Be aware of publishing those credentials. Get sure you pass them in a secure way and not in plain text.
For example:
```
module "mongodb_bi_connector" {
  source = "../../"

  name             = "mongodb-bi-connector-terraform"
  mongodb_username = some_secret_store.mongodb-bi-connector-secret["username"]
  mongodb_password = some_secret_store.mongodb-bi-connector-secret["password"]
  mongodb_uri      = some_secret_store.mongodb-bi-connector-secret["uri"]
}
```
