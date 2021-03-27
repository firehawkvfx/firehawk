provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}

resource "random_pet" "env" {
  length = 2
}
locals {
  common_tags = var.common_tags
}

resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10
  tags                    = merge(map("Name", "vault-kms-unseal-${random_pet.env.id}"), local.common_tags)
}

resource "aws_ssm_parameter" "vault_kms_unseal" {
  name  = "/firehawk/resourcetier/${var.resourcetier}/vault_kms_unseal_key_id"
  type  = "SecureString"
  overwrite = true
  value = aws_kms_key.vault.id
  tags  = merge(map("Name", "vault_kms_unseal_key_id"), local.common_tags)
}

data "aws_ssm_parameter" "vault_kms_unseal" {
  depends_on = [aws_ssm_parameter.vault_kms_unseal]
  name       = "/firehawk/resourcetier/${var.resourcetier}/vault_kms_unseal_key_id"
}

data "aws_kms_key" "vault" {
  key_id = data.aws_ssm_parameter.vault_kms_unseal.value
}
