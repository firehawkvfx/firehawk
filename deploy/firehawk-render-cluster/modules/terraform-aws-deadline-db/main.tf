provider "null" {}

provider "aws" {}

data "aws_region" "current" {}

data "terraform_remote_state" "rendervpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-render-vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "terraform_remote_state" "vaultvpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-main/modules/vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "aws_vpc" "rendervpc" {
  count = length( try(data.terraform_remote_state.rendervpc.outputs.vpc_id, "") ) > 0 ? 1 : 0
  default = false
  id = data.terraform_remote_state.rendervpc.outputs.vpc_id
}
data "aws_vpc" "vaultvpc" {
  count = length( try(data.terraform_remote_state.vaultvpc.outputs.vpc_id, "") ) > 0 ? 1 : 0
  default = false
  id = data.terraform_remote_state.vaultvpc.outputs.vpc_id
}
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = length(data.aws_vpc.rendervpc) > 0 ? [data.aws_vpc.rendervpc[0].id] : []
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
    values = length(data.aws_vpc.rendervpc) > 0 ? [data.aws_vpc.rendervpc[0].id] : []
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
  count = length(data.aws_vpc.rendervpc) > 0 ? 1 : 0
  vpc_id = data.aws_vpc.rendervpc[0].id
  tags   = tomap({"area": "public"})
}
data "aws_route_tables" "private" {
  count = length(data.aws_vpc.rendervpc) > 0 ? 1 : 0
  vpc_id = data.aws_vpc.rendervpc[0].id
  tags   = tomap({"area": "private"})
}
data "terraform_remote_state" "bastion_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/terraform-aws-sg-bastion/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "terraform_remote_state" "vpn_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-render-cluster/modules/terraform-aws-sg-vpn/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

locals {
  common_tags                = var.common_tags
  mount_path                 = var.resourcetier
  vpc_id                     = length(data.aws_vpc.rendervpc) > 0 ? data.aws_vpc.rendervpc[0].id : ""
  vpn_cidr                   = var.vpn_cidr
  onsite_private_subnet_cidr = var.onsite_private_subnet_cidr
  private_subnet_ids         = tolist(data.aws_subnets.private.ids)
  private_subnet_cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  onsite_public_ip           = var.onsite_public_ip
  private_route_table_ids    = length(data.aws_route_tables.private) > 0 ? data.aws_route_tables.private[0].ids : []
  instance_name              = "${lookup(local.common_tags, "vpcname", "default")}_deadlinedbvaultclient_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
}
module "deadline_db_instance" {
  source                      = "./modules/aws-ec2-deadline-db"
  name                        = local.instance_name
  deadline_db_ami_id          = var.deadline_db_ami_id
  consul_cluster_name         = var.consul_cluster_name
  consul_cluster_tag_key      = var.consul_cluster_tag_key
  aws_internal_domain         = var.aws_internal_domain
  vpc_id                      = local.vpc_id
  bucket_extension            = var.bucket_extension
  bucket_extension_vault      = var.bucket_extension_vault
  private_subnet_ids          = local.private_subnet_ids
  permitted_cidr_list         = ["${local.onsite_public_ip}/32", var.remote_cloud_public_ip_cidr, var.remote_cloud_private_ip_cidr, local.onsite_private_subnet_cidr, local.vpn_cidr, data.aws_vpc.rendervpc[0].cidr_block, data.aws_vpc.vaultvpc[0].cidr_block]
  permitted_cidr_list_private = [var.remote_cloud_private_ip_cidr, local.onsite_private_subnet_cidr, local.vpn_cidr]
  security_group_ids = concat(
    try([data.terraform_remote_state.bastion_security_group.outputs.security_group_id], []),
    try([data.terraform_remote_state.vpn_security_group.outputs.security_group_id], []),
  )
  # security_group_ids = [ 
  #   data.terraform_remote_state.bastion_security_group.outputs.security_group_id,
  #   data.terraform_remote_state.vpn_security_group.outputs.security_group_id,
  # ]
  aws_key_name     = var.aws_key_name
  common_tags      = local.common_tags
  deadline_version = var.deadline_version
}
