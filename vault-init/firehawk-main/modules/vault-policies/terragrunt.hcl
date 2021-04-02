include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  # init = lower(get_env("TF_VAR_init", "false"))=="true" ? true : false
  configure_vault = lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? true : false
  skip = ( local.configure_vault ? false : true )
}

inputs = local.common_vars.inputs

# inputs = merge(
#   local.common_vars.inputs,
#   { 
#     "init" : local.init,
#     "configure_vault" : local.configure_vault 
#   }
# )

dependencies {
  paths = [
    "../vault"
    ]
}

skip = local.skip

terraform {
  source = "github.com/firehawkvfx/firehawk-main.git//modules/vault-policies?ref=test-relocate-policies"

  after_hook "after_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "scripts/create-token"]
  }

}
# To initialise vault values (after logging in with root token):
# TF_VAR_configure_vault=true TF_VAR_init=true terragrunt plan -out="tfplan" && terragrunt apply "tfplan"

# To configure vault
# TF_VAR_configure_vault=true terragrunt plan -out="tfplan" && terragrunt apply "tfplan"