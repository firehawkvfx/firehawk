include {
  path = find_in_parent_folders()
}

variable "init" {
  default = false
}

variable "configure_vault" {
  default = false
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  init = var.init
  configure_vault = var.configure_vault
  # skip = ( lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? "false" : "true" )
  skip = ( local.configure_vault == "true" ? "false" : "true" )
}

inputs = merge(
  local.common_vars.inputs,
  { 
    "init" : local.init,
    "configure_vault" : local.configure_vault 
  }
)

dependencies {
  paths = [
    "../vault"
    ]
}

skip = local.skip

terraform {
  source = "github.com/firehawkvfx/firehawk-main.git//modules/vault-configuration?ref=test-pull-request-236"
}

# To initialise vault values (after logging in with root token):
# TF_VAR_configure_vault=true TF_VAR_init=true terragrunt plan -out="tfplan" && terragrunt apply "tfplan"

# To configure vault
# TF_VAR_configure_vault=true terragrunt plan -out="tfplan" && terragrunt apply "tfplan"