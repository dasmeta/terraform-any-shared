data "external" "pass" {
  program = ["bash", "${path.module}/get_data.sh", "${var.op_password}", "${var.op_secret_key}", "${var.op_account_address}", "${var.op_email}", "${var.op_item}", "${var.op_vault_name}", "${var.op_item_type}"]
}
