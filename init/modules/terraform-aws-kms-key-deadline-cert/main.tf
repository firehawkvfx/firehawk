locals {
  common_tags = var.common_tags
}
resource "random_pet" "env" {
  length = 2
}
resource "aws_kms_key" "the_key" {
  description             = var.description
  deletion_window_in_days = 10
  tags                    = merge(tomap({ "Name" : "${var.name_prefix}-${random_pet.env.id}" }), local.common_tags)
}
resource "aws_kms_alias" "alias" {
  name          = "${var.kms_key_alias_name}"
  target_key_id = aws_kms_key.the_key.key_id
}
# Ensure this encrypted secret exists for later use.
resource "aws_secretsmanager_secret" "content" {
  name       = var.secrets_manager_parameter
  kms_key_id = aws_kms_key.the_key.id
}
