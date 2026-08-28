# Research: Optional Authentik ingress

## Official chart support

Authentik chart `2026.5.6` exposes `server.ingress` with enabled state,
annotations, ingress class, host list and TLS list. Its Service stays internal,
so chart ingress is the correct place to model public routing.

## TLS decision

The module uses cert-manager's standard ClusterIssuer annotation and binds the
configured hostname to a named TLS Secret. `force-ssl-redirect` is module-owned
to keep the route HTTPS-only.

## DNS decision

DNS stays external. `dasmeta/terraform-cloudflare-complete` provides a records
module, but zone adoption/import and Cloudflare credentials are independent of
the reusable Authentik chart wrapper.
