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
  aws_kms_key_tags = merge(map("Name", "vault-kms-token-${random_pet.env.id}"), local.common_tags)
}

resource "aws_kms_key" "vault" {
  description             = "Vault token secret key"
  deletion_window_in_days = 10
  tags                    = local.aws_kms_key_tags
}

resource "aws_ssm_parameter" "vault_kms_token" {
  name  = "/firehawk/resourcetier/${var.resourcetier}/vault_kms_token_key_id"
  type  = "SecureString"
  overwrite = true
  value = aws_kms_key.vault.id
  tags  = merge(map("Name", "vault_kms_token_key_id"), local.common_tags)
}

data "aws_ssm_parameter" "vault_kms_token" {
  depends_on = [aws_ssm_parameter.vault_kms_token]
  name       = "/firehawk/resourcetier/${var.resourcetier}/vault_kms_token_key_id"
}

data "aws_kms_key" "vault" {
  key_id = data.aws_ssm_parameter.vault_kms_token.value
}
