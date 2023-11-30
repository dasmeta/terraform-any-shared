module "this" {
  source  = "../../"

  helm_values = {
      "image" : {
        "repository": "repository: xxxxx.dkr.ecr.us-east-1.amazonaws.com/api",
        "tag": "latest"
      },
      "config" : { 
            "ALLY_DDELIVERY_SERVICE":"http://66.175.236.109:5010",
            "API01_PORT_SOCKET":"3003",
            "API_BASE_URL":"https://dev.orders.co/api/api01",
        },
      "podAnnotations": {
          "linkerd.io/inject" : "enabled"
        },
      "replicaCount":2,
  }
  name = "api01"
  namespace = "test"
}

