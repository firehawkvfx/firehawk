include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

dependencies {
  paths = [ # not strictly dependencies, but if they fail, there is no point in continuing to deploy a vpc or anything else.
    "../terraform-aws-render-vpc-vault-vpc-peering", 
    "../terraform-aws-render-vpc-cloud9-peering"
    ]
}

skip = true # this module should be deprecated if using the vpn module