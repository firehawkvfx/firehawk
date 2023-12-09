include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../firehawk-modules/modules/terraform-aws-iam-profile-lighthouse"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  resourcetier = local.common_vars.inputs.common_tags["resourcetier"]
  region = local.common_vars.inputs.common_tags["region"]
}

inputs = merge(local.common_vars.inputs, {
  "region"                  = local.region,
  "vpn_scripts_bucket_name" = "nebula.scripts.${local.resourcetier}.firehawkvfx.com",
  "vpn_certs_bucket_name"   = "nebula.certs.${local.resourcetier}.firehawkvfx.com"
})
