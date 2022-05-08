locals {
  common_tags = var.common_tags
}

resource "random_pet" "env" {
  length = 2
}

resource "aws_kms_key" "the_key" {
  description             = var.description
  deletion_window_in_days = 10
  tags                    = merge(tomap({"Name": "${var.name_prefix}-${random_pet.env.id}"}), local.common_tags)
}

resource "aws_ssm_parameter" "kms_key_id_parameter" {
  name  = var.ssm_parameter_name_kms_key_id
  type  = "SecureString"
  overwrite = true
  value = aws_kms_key.the_key.id
  tags  = merge(tomap({"Name": var.name_prefix}), local.common_tags)
}
