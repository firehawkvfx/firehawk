include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

terraform {
  source = "${get_env("TF_VAR_firehawk_path", "")}/modules/terraform-aws-iam-profile-vault-client"
}