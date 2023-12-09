include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../firehawk-modules/modules/terraform-aws-iam-profile-lighthouse"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = merge(local.common_vars.inputs, {
  "region"                  = "ap-southeast-2",
  "vpn_scripts_bucket_name" = "nebula.scripts.${var.resourcetier}.firehawkvfx.com",
  "vpn_certs_bucket_name"   = "nebula.certs.${var.resourcetier}.firehawkvfx.com"
})

dependencies {}
