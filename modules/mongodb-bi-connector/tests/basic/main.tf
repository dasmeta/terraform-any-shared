module "mongodb_bi_connector" {
  source = "../../"

  name             = "mongodb-bi-connector-terraform"
  mongodb_username = "secureUsername"
  mongodb_password = "securePassword"
  mongodb_uri      = "mongodb://mongodb-replicaset:27017/?authSource=testing&replicaSet=test"
}
