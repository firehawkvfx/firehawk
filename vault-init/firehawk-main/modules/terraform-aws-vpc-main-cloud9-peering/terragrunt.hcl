include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

dependencies {
  paths = ["../vpc"]
}

terraform {
  source = "../../../../deploy/firehawk-main/modules/terraform-aws-vpc-main-cloud9-peering"
}