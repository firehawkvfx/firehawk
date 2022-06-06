data "aws_region" "current" {}

data "aws_vpc" "rendervpc" {
  default = false
  tags    = var.common_tags_rendervpc
}
data "aws_vpc" "vaultvpc" {
  default = false
  tags    = var.common_tags_vaultvpc
}
data "aws_internet_gateway" "gw" {
  # default = false
  tags = local.common_tags
}
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.rendervpc.id]
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
    values = [data.aws_vpc.rendervpc.id]
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
  vpc_id = data.aws_vpc.rendervpc.id
  tags   = tomap({"area": "public"})
}
data "aws_route_tables" "private" {
  vpc_id = data.aws_vpc.rendervpc.id
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
  vpc_id                     = data.aws_vpc.rendervpc.id
  aws_internet_gateway       = data.aws_internet_gateway.gw.id
  vpn_cidr                   = var.vpn_cidr
  onsite_private_subnet_cidr = var.onsite_private_subnet_cidr
  private_subnet_ids         = tolist(data.aws_subnets.private.ids)
  private_subnet_cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  onsite_public_ip           = var.onsite_public_ip
  private_route_table_ids    = data.aws_route_tables.private.ids
  instance_name              = "${lookup(local.common_tags, "vpcname", "default")}_workstationamazonlinux2nicedcv_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
}
module "workstation_amazonlinux2_nicedcv" {
  source                                  = "./modules/amazonlinux2-nicedcv"
  name                                    = local.instance_name
  workstation_amazonlinux2_nicedcv_ami_id = var.workstation_amazonlinux2_nicedcv_ami_id
  consul_cluster_name                     = var.consul_cluster_name
  consul_cluster_tag_key                  = var.consul_cluster_tag_key
  aws_internal_domain                     = var.aws_internal_domain
  vpc_id                                  = local.vpc_id
  bucket_extension_vault                  = var.bucket_extension_vault
  bucket_extension                        = var.bucket_extension
  private_subnet_ids                      = local.private_subnet_ids
  permitted_cidr_list                     = ["${local.onsite_public_ip}/32", var.remote_cloud_public_ip_cidr, var.remote_cloud_private_ip_cidr, local.onsite_private_subnet_cidr, local.vpn_cidr, data.aws_vpc.rendervpc.cidr_block, data.aws_vpc.vaultvpc.cidr_block]
  permitted_cidr_list_private             = [var.remote_cloud_private_ip_cidr, local.onsite_private_subnet_cidr, local.vpn_cidr]
  security_group_ids = [
    try(data.terraform_remote_state.bastion_security_group.outputs.security_group_id,null),
    try(data.terraform_remote_state.vpn_security_group.outputs.security_group_id,null),
  ]
  aws_key_name = var.aws_key_name
  common_tags  = local.common_tags
  deadline_version = var.deadline_version
}
