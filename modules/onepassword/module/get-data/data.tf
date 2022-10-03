data "external" "pass" {
  program = ["bash", "${path.module}/test.sh", "${var.op_password}", "${var.op_secret_key}", "${var.op_account_address}", "${var.op_email}", "${var.op_item}", "${var.op_vault_name}", "${var.op_item_type}"]
}


output "pass" {
  value     = data.external.pass.result["pass"]
  sensitive = true
}
