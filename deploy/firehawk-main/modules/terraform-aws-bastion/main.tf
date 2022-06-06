data "aws_region" "current" {}
data "terraform_remote_state" "vaultvpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  vpc_id = length( try(data.terraform_remote_state.vaultvpc.outputs.vpc_id, "") ) > 0 ? data.terraform_remote_state.vaultvpc.outputs.vpc_id : ""
}
data "aws_vpc" "primary" {
  count   = length(local.vpc_id) > 0 ? 1 : 0
  default = false
  id      = local.vpc_id
}
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = length(local.vpc_id) > 0 ? [local.vpc_id] : []
  }
  tags = {
    area = "public"
  }
}
locals {
  common_tags      = var.common_tags
  vpc_cidr         = length(data.aws_vpc.primary) > 0 ? data.aws_vpc.primary[0].cidr_block : ""
  public_subnets   = length(data.aws_subnets.public) > 0 ? tolist(data.aws_subnets.public.ids) : []
  onsite_public_ip = var.onsite_public_ip
  instance_name    = "${lookup(local.common_tags, "vpcname", "default")}_bastion_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
}
module "bastion" {
  source                 = "./modules/bastion"
  name                   = local.instance_name
  bastion_ami_id         = var.bastion_ami_id
  consul_cluster_tag_key = var.consul_cluster_tag_key
  consul_cluster_name    = var.consul_cluster_name
  aws_key_name           = var.aws_key_name # The aws pem key name can optionally be enabled for debugging, but generally SSH certificates should be used instead.
  aws_internal_domain    = var.aws_internal_domain
  aws_external_domain    = var.aws_external_domain
  vpc_id                 = local.vpc_id
  vpc_cidr               = local.vpc_cidr
  # permitted_cidr_list      = ["${local.onsite_public_ip}/32", var.remote_cloud_public_ip_cidr, var.remote_cloud_private_ip_cidr]
  public_subnet_ids        = local.public_subnets
  route_public_domain_name = var.route_public_domain_name
  route_zone_id            = "none"
  public_domain_name       = "none"
  common_tags              = local.common_tags
  bucket_extension_vault   = var.bucket_extension_vault
  resourcetier_vault       = var.resourcetier_vault
  vpcname_vaultvpc         = var.vpcname_vaultvpc
}
