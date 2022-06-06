include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

dependencies {
  paths = [
    "../../terraform-aws-render-vpc-vault-vpc-peering",
    "../../terraform-aws-deadline-db",
    "../../terraform-aws-sg-rendernode/module",
    "../../terraform-aws-user-data-rendernode/module",
    "../../../../firehawk-main/modules/terraform-aws-sg-bastion",
    "../../../../firehawk-main/modules/terraform-aws-sg-vpn",
    "../../../../firehawk-main/modules/vault",
    "../../../../firehawk-main/modules/terraform-aws-iam-profile-rendernode"
    ]
}