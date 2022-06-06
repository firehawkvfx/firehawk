data "aws_region" "current" {}
data "terraform_remote_state" "vaultvpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-main/modules/vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "aws_vpc" "primary" { # this vpc
  count = length( try(data.terraform_remote_state.vaultvpc.outputs.vpc_id, "") ) > 0 ? 1 : 0
  default = false
  id = data.terraform_remote_state.vaultvpc.outputs.vpc_id
  # tags    = local.common_tags
}
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = length( try(data.terraform_remote_state.vaultvpc.outputs.vpc_id, "") ) > 0 ? [data.terraform_remote_state.vaultvpc.outputs.vpc_id] : []
  }
  tags = {
    area = "private"
  }
}
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}
data "terraform_remote_state" "bastion_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/terraform-aws-sg-bastion/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

locals {
  vaultvpc_tags = {
    vpcname     = var.vpcname_vaultvpc,
    projectname = "firehawk-main"
  }
  bastion_tags = merge(local.common_tags, {
    role  = "bastion"
    route = "public"
  })
  common_tags = var.common_tags
  vpcname     = local.common_tags["vpcname"]
  mount_path  = var.resourcetier
  vpc_id      = length(data.aws_vpc.primary) > 0 ? data.aws_vpc.primary[0].id : ""
  vpc_cidr    = length(data.aws_vpc.primary) > 0 ? data.aws_vpc.primary[0].cidr_block : ""

  vpn_cidr                   = var.vpn_cidr
  onsite_private_subnet_cidr = var.onsite_private_subnet_cidr

  private_subnet_ids         = length(data.aws_subnets.private) > 0 ? tolist(data.aws_subnets.private.ids) : []
  onsite_public_ip           = var.onsite_public_ip
}
module "vault_client" {
  source              = "./modules/vault-client"
  name                = "${local.vpcname}_vaultclient_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
  vault_client_ami_id = var.vault_client_ami_id

  consul_cluster_name    = var.consul_cluster_name
  consul_cluster_tag_key = var.consul_cluster_tag_key
  aws_internal_domain    = var.aws_internal_domain
  vpc_id                 = local.vpc_id
  vpc_cidr               = local.vpc_cidr
  private_subnet_ids     = local.private_subnet_ids
  permitted_cidr_list    = ["${local.onsite_public_ip}/32", var.remote_cloud_public_ip_cidr, var.remote_cloud_private_ip_cidr, local.onsite_private_subnet_cidr, local.vpn_cidr, var.combined_vpcs_cidr]
  security_group_ids     = [ try(data.terraform_remote_state.bastion_security_group.outputs.security_group_id, null) ]

  aws_key_name = var.aws_key_name
  common_tags  = local.common_tags

  bucket_extension_vault = var.bucket_extension_vault
  resourcetier_vault     = var.resourcetier_vault
  vpcname_vaultvpc          = var.vpcname_vaultvpc
}
