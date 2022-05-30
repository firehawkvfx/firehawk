include {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_env("TF_VAR_firehawk_path", "")}/modules/vault-aws-secret-backend"
}

skip = local.skip

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  configure_vault = lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? true : false
  skip = ( local.configure_vault ? false : true )
}

dependencies {
  paths = ["../../vault-policies"]
}

inputs = local.common_vars.inputs
