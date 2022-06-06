include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

skip = true # profiles are only created during init since the output names are required to configure vault iam access

inputs = local.common_vars.inputs