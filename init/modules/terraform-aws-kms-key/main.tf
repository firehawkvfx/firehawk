resource "random_pet" "env" {
  length = 2
}
locals {
  common_tags = var.common_tags
  aws_kms_key_tags = merge(tomap({"Name": "vault-kms-unseal-${random_pet.env.id}"}), local.common_tags)
}

resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10
  tags                    = local.aws_kms_key_tags
}

resource "aws_ssm_parameter" "vault_kms_unseal" {
  name  = "/firehawk/resourcetier/${var.resourcetier}/vault_kms_unseal_key_id"
  type  = "SecureString"
  overwrite = true
  value = aws_kms_key.vault.id
  tags  = merge(tomap({"Name": "vault_kms_unseal_key_id"}), local.common_tags)
}

data "aws_ssm_parameter" "vault_kms_unseal" {
  depends_on = [aws_ssm_parameter.vault_kms_unseal]
  name       = "/firehawk/resourcetier/${var.resourcetier}/vault_kms_unseal_key_id"
}

data "aws_kms_key" "vault" {
  key_id = data.aws_ssm_parameter.vault_kms_unseal.value
}
