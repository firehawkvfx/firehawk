include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  skip = ( lower(get_env("TF_VAR_init", "false"))=="true" ? "false" : "true" )
}

skip = local.skip
inputs = local.common_vars.inputs