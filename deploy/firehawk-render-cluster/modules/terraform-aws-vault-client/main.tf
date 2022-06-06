data "aws_region" "current" {}
data "aws_vpc" "primary" { # this vpc
  default = false
  tags    = local.common_tags
}
data "aws_vpc" "vaultvpc" { # vault vpc
  default = false
  tags    = local.vaultvpc_tags
}
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.primary.id]
  }
  tags = {
    area = "public"
  }
}
data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.primary.id]
  }
  tags = {
    area = "private"
  }
}
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_route_tables" "public" {
  vpc_id = data.aws_vpc.primary.id
  tags   = merge(local.common_tags, { "area" : "public" })
}

data "aws_route_tables" "private" {
  vpc_id = data.aws_vpc.primary.id
  tags   = merge(local.common_tags, { "area" : "public" })
}

# data "aws_security_group" "bastion" { # Aquire the security group ID for external bastion hosts, these will require SSH access to this internal host.  Since multiple deployments may exist, the pipelineid allows us to distinguish between unique deployments.
#   tags = local.bastion_tags # Since we deploy vault alongside this account, pipelineid will probably not be an issue...  At some point we will need to create a dependency of the vault vpc output and what tags we should be using with multi account and CI.
#   vpc_id = data.aws_vpc.vaultvpc.id
# }

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
  bastion_tags = merge(local.vaultvpc_tags, {
    role  = "bastion"
    route = "public"
  })
  common_tags = var.common_tags
  vpcname     = local.common_tags["vpcname"]
  mount_path  = var.resourcetier
  vpc_id      = data.aws_vpc.primary.id
  vpc_cidr    = data.aws_vpc.primary.cidr_block

  vpn_cidr                   = var.vpn_cidr
  onsite_private_subnet_cidr = var.onsite_private_subnet_cidr

  private_subnet_ids         = tolist(data.aws_subnets.private.ids)
  private_subnet_cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  onsite_public_ip           = var.onsite_public_ip
  private_route_table_ids    = data.aws_route_tables.private.ids
}
module "vault_client" {
  source              = "../../../firehawk-main/modules/terraform-aws-vault-client/modules/vault-client" # this should reference a tgged version of the git hub repo in production.
  name                = "${local.vpcname}_vaultclient_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
  vault_client_ami_id = var.vault_client_ami_id

  consul_cluster_name    = var.consul_cluster_name
  consul_cluster_tag_key = var.consul_cluster_tag_key
  aws_internal_domain    = var.aws_internal_domain
  vpc_id                 = local.vpc_id
  vpc_cidr               = local.vpc_cidr

  private_subnet_ids  = local.private_subnet_ids
  permitted_cidr_list = ["${local.onsite_public_ip}/32", var.remote_cloud_public_ip_cidr, var.remote_cloud_private_ip_cidr, local.onsite_private_subnet_cidr, local.vpn_cidr]
  security_group_ids  = [try(data.terraform_remote_state.bastion_security_group.outputs.security_group_id,null)]

  aws_key_name           = var.aws_key_name
  common_tags            = local.common_tags
  bucket_extension_vault = var.bucket_extension_vault
  resourcetier_vault     = var.resourcetier_vault
  vpcname_vaultvpc          = var.vpcname_vaultvpc
}
