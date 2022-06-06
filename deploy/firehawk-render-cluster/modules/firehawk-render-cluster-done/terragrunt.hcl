# A dummy event to simplify refs to completion of this project build

include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

dependencies {
  paths = [
    "../terraform-aws-node-houdini/module",
    "../terraform-aws-deadline-db",
    "../terraform-aws-deadline-spot"
    ]
}