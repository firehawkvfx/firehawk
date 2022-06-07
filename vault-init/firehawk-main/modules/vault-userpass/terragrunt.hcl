include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  configure_vault = lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? true : false
  skip = ( local.configure_vault ? false : true )
}

inputs = merge(
  local.common_vars.inputs,
  {
    "configure_vault" : local.configure_vault 
  }
)

dependencies {
  paths = [
    "../vault-policies"
    ]
}

# skip = local.skip
skip = true

terraform {
  source = "../../../firehawk-main/modules/modules/vault-userpass"
}