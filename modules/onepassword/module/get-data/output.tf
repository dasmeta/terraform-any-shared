output "pass" {
  value     = data.external.pass.result["pass"]
  sensitive = true
}
