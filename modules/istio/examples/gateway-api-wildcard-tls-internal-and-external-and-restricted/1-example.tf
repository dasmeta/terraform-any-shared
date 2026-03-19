# Example: Istio Gateway API with wildcard domain and TLS (AWS EKS - External and Internal)
#
# This configuration:
# - Installs Istio with Gateway API CRDs
# - Creates two Gateways for the same wildcard domain *.devops.dasmeta.com:
#   - "main": External Gateway (internet-facing AWS NLB)
#   - "main-internal": Internal Gateway (internal AWS NLB)
# - Both Gateways configure HTTP listener on port 80
# - Both Gateways configure HTTPS listener on port 443 with cert-manager integration
# - Uses letsencrypt-prod ClusterIssuer for automatic certificate provisioning
# - Both Gateways share the same TLS certificate Secret
# - Automatically redirects all HTTP traffic to HTTPS via HTTPRoute resources

module "this" {
  source = "../.."

  configs = {
    gateway = {
      # Enable Gateway API resources (native k8s Gateway objects)
      api_resources = {
        gateways = [
          # External Gateway (internet-facing AWS NLB)
          {
            name             = "main"
            gatewayClassName = "istio"
            listeners = [
              # HTTP listener on port 80
              {
                name     = "http-80"
                hostname = "${var.domain}"
                port     = 80
                protocol = "HTTP"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
              },
              # HTTPS listener on port 443 with TLS
              {
                name     = "https-443"
                hostname = "${var.domain}"
                port     = 443
                protocol = "HTTPS"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
                tls = {
                  mode = "Terminate"
                  certificateRefs = [
                    {
                      name  = "wildcard-istio-devops-dasmeta-com-tls"
                      kind  = "Secret"
                      group = ""
                    }
                  ]
                }
              },
              # HTTP listener on port 80
              {
                name     = "http-80-wildcard"
                hostname = "*.${var.domain}"
                port     = 80
                protocol = "HTTP"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
              },
              # HTTPS listener on port 443 with TLS
              {
                name     = "https-443-wildcard"
                hostname = "*.${var.domain}"
                port     = 443
                protocol = "HTTPS"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
                tls = {
                  mode = "Terminate"
                  certificateRefs = [
                    {
                      name  = "wildcard-istio-devops-dasmeta-com-tls"
                      kind  = "Secret"
                      group = ""
                    }
                  ]
                }
              }
            ]
            # AWS NLB infrastructure configuration for external LoadBalancer
            infrastructure = {
              annotations = {
                "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
                "service.beta.kubernetes.io/aws-load-balancer-type"            = "nlb"
                "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
                ## attaching custom security groups to the NLB for restricting access to the NLB(NOTE: newer version of load-balancer controller may be needed for this annotations to work)
                # "service.beta.kubernetes.io/aws-load-balancer-security-groups"                     = "sg-00000000000000000" # replace with your security group ID
                # "service.beta.kubernetes.io/aws-load-balancer-manage-backend-security-group-rules" = "true" # needed for load balancer to backend services access
              }
            }
          },
          # Internal Gateway (internal AWS NLB)
          {
            name             = "main-internal"
            gatewayClassName = "istio"
            listeners = [
              # HTTP listener on port 80
              {
                name     = "http-80"
                hostname = "${var.domain}"
                port     = 80
                protocol = "HTTP"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
              },
              # HTTPS listener on port 443 with TLS
              {
                name     = "https-443"
                hostname = "${var.domain}"
                port     = 443
                protocol = "HTTPS"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
                tls = {
                  mode = "Terminate"
                  certificateRefs = [
                    {
                      name  = "wildcard-istio-devops-dasmeta-com-tls"
                      kind  = "Secret"
                      group = ""
                    }
                  ]
                }
              },
              # HTTP listener on port 80 wildcard
              {
                name     = "http-80-wildcard"
                hostname = "*.${var.domain}"
                port     = 80
                protocol = "HTTP"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
              },
              # HTTPS listener on port 443 with TLS wildcard
              {
                name     = "https-443-wildcard"
                hostname = "*.${var.domain}"
                port     = 443
                protocol = "HTTPS"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
                tls = {
                  mode = "Terminate"
                  certificateRefs = [
                    {
                      name  = "wildcard-istio-devops-dasmeta-com-tls"
                      kind  = "Secret"
                      group = ""
                    }
                  ]
                }
              }
            ]
            # AWS NLB infrastructure configuration for internal LoadBalancer
            infrastructure = {
              annotations = {
                "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internal"
                "service.beta.kubernetes.io/aws-load-balancer-type"            = "nlb"
                "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
              }
            }
          }
        ]
        # HTTP to HTTPS redirect for both Gateways
        # This creates HTTPRoute resources that automatically redirect all HTTP traffic to HTTPS
        httpRoutes = [
          # HTTP to HTTPS redirect for external Gateway
          {
            name = "http-to-https-redirect-external"
            parentRefs = [
              {
                name        = "main"
                sectionName = "http-80"
              },
              {
                name        = "main"
                sectionName = "https-80-wildcard"
              }
            ]
            hostnames = ["${var.domain}", "*.${var.domain}"]
            rules = [
              {
                redirect = {
                  scheme     = "https"
                  statusCode = 301
                }
              }
            ]
          },
          # HTTP to HTTPS redirect for internal Gateway
          {
            name = "http-to-https-redirect-internal"
            parentRefs = [
              {
                name        = "main-internal"
                sectionName = "http-80"
              },
              {
                name        = "main-internal"
                sectionName = "https-80-wildcard"
              }
            ]
            hostnames = ["${var.domain}", "*.${var.domain}"]
            rules = [
              {
                redirect = {
                  scheme     = "https"
                  statusCode = 301
                }
              }
            ]
          }
        ]
      }
    }
    # Istiod configuration - disable automatic sidecar injection
    istiod = {
      configs = {
        # Disable automatic sidecar injection globally
        # This prevents Istio from injecting sidecars into pods (horizontal service mesh)
        global = {
          proxy = {
            autoInject = "disabled"
          }
        }
      }
    }
  }
}

# Certificate resource for cert-manager
# This creates a Certificate that will be used by the Gateway for TLS
#
# PREREQUISITE FOR HTTP01:
# If using HTTP01 resolver, the ClusterIssuer must be configured with gatewayHTTPRoute.
# For HTTP01 challenges, use the external Gateway ("main") since it's accessible from the internet:
#   spec:
#     acme:
#       solvers:
#         - http01:
#             gatewayHTTPRoute:
#               parentRefs:
#                 - name: main
#                   namespace: istio-system
#                   kind: Gateway
#                   group: gateway.networking.k8s.io
# Without this configuration, cert-manager will create Ingress resources instead of HTTPRoutes.
# Note: Both Gateways can use the same certificate Secret, but HTTP01 challenges must go through the external Gateway.
#
# IMPORTANT NOTES:
# 1. Gateway API Gateway only READS the Secret - it does NOT modify it
# 2. If the Secret already exists, the Gateway will use it without modification
# 3. Certificate rotation is handled entirely by cert-manager:
#    - cert-manager monitors certificate expiration
#    - Automatically renews certificates before expiration (typically 30 days before)
#    - Updates the Secret with the new certificate
#    - Gateway automatically picks up the new certificate from the updated Secret
# 4. Gateway API is NOT involved in certificate rotation - it's a passive consumer
# 5. Challenge validation depends on ClusterIssuer resolver type:
#
#    DNS01 resolver (e.g., Route53, Cloudflare):
#    - cert-manager creates DNS TXT records to prove domain ownership
#    - Requests certificate from Let's Encrypt
#    - Stores certificate in the Secret
#    - Gateway reads from the Secret (no Gateway involvement in DNS challenge)
#    - Works for wildcard domains (*.devops.dasmeta.com)
#
#    HTTP01 resolver:
#    - REQUIRES: ClusterIssuer must be configured with gatewayHTTPRoute in HTTP01 solver
#      Example ClusterIssuer configuration:
#        spec:
#          acme:
#            solvers:
#              - http01:
#                  gatewayHTTPRoute:
#                    parentRefs:
#                      - name: main
#                        namespace: istio-system
#                        kind: Gateway
#                        group: gateway.networking.k8s.io
#    - cert-manager creates temporary HTTPRoute resources for /.well-known/acme-challenge/*
#    - HTTPRoutes reference the Gateway via parentRefs (configured in ClusterIssuer)
#    - Gateway routes these HTTPRoutes normally (HTTP listener on port 80 required)
#    - Let's Encrypt validates by accessing the challenge file via HTTP
#    - Once validated, cert-manager stores certificate in the Secret
#    - Gateway reads from the Secret (Gateway just routes HTTP traffic - no special config)
#    - Does NOT work for wildcard domains - only exact domain matches
resource "kubectl_manifest" "wildcard_certificate" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "wildcard-devops-dasmeta-com-tls"
      namespace = "istio-system"
    }
    spec = {
      secretName = "wildcard-devops-dasmeta-com-tls"
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
      dnsNames = [
        "*.devops.dasmeta.com",
        "devops.dasmeta.com"
      ]
    }
  })

  depends_on = [module.this]
}
