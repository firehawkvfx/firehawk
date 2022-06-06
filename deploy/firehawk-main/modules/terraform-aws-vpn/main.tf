provider "null" {}

provider "aws" {}

data "aws_region" "current" {}

locals {
  common_tags = var.common_tags
}

data "aws_vpc" "primary" {
  count = length(var.vpc_id) > 0 ? 1 : 0
  default = false
  id = var.vpc_id
}

data "aws_internet_gateway" "gw" {
  count = length(var.vpc_id) > 0 ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
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
    values = [var.vpc_id]
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
  count = length(var.vpc_id) > 0 ? 1 : 0
  vpc_id = var.vpc_id
  tags   = merge(local.common_tags, { "area" : "public" })
}

data "aws_route_tables" "private" {
  count = length(var.vpc_id) > 0 ? 1 : 0
  vpc_id = var.vpc_id
  tags   = merge(local.common_tags, { "area" : "private" })
}

locals {
  mount_path                 = var.resourcetier
  vpc_id                     = var.vpc_id
  vpc_cidr                   = length(data.aws_vpc.primary) > 0 ? data.aws_vpc.primary[0].cidr_block : ""
  aws_internet_gateway       = length(data.aws_internet_gateway.gw) > 0 ? data.aws_internet_gateway.gw[0].id : ""
  public_subnets             = length(data.aws_subnets.public) > 0 ? sort(data.aws_subnets.public.ids) : []
  public_subnet_cidr_blocks  = [for s in data.aws_subnet.public : s.cidr_block]
  private_subnets            = length(data.aws_subnets.private) > 0 ? sort(data.aws_subnets.private.ids) : []
  private_subnet_cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  vpn_cidr                   = var.vpn_cidr
  onsite_private_subnet_cidr = var.onsite_private_subnet_cidr
  onsite_public_ip           = var.onsite_public_ip
  private_route_table_ids    = length(data.aws_route_tables.private) > 0 ? sort(data.aws_route_tables.private[0].ids) : []
  public_route_table_ids     = length(data.aws_route_tables.public) > 0 ? sort(data.aws_route_tables.public[0].ids) : []
  public_domain_name         = "none"
  route_zone_id              = "none"
  instance_name              = "${lookup(local.common_tags, "vpcname", "default")}_openvpn_ec2_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
}
data "terraform_remote_state" "openvpn_profile" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/terraform-aws-iam-profile-openvpn/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

module "vpn" {
  source                     = "./modules/tf_aws_openvpn"
  create_vpn                 = true
  security_group_attachments = var.security_group_ids
  example_role_name          = "vpn-server-vault-role" # this authenticates with a dynamically generated secret key
  name                       = local.instance_name
  ami                        = var.openvpn_server_ami
  iam_instance_profile_name  = try(data.terraform_remote_state.openvpn_profile.outputs.instance_profile_name, null) # if destroy after partial deploy, remote state may not have existed.
  resourcetier               = var.resourcetier
  conflictkey                = var.conflictkey
  # VPC Inputs
  vpc_id                     = local.vpc_id
  vpc_cidr                   = local.vpc_cidr
  vpn_cidr                   = local.vpn_cidr
  combined_vpcs_cidr         = var.combined_vpcs_cidr
  public_subnet_id           = length(local.public_subnets) > 0 ? local.public_subnets[0] : null
  remote_vpn_ip_cidr         = "${local.onsite_public_ip}/32"
  onsite_private_subnet_cidr = local.onsite_private_subnet_cidr
  private_route_table_ids    = local.private_route_table_ids
  public_route_table_ids     = local.public_route_table_ids
  route_public_domain_name   = var.route_public_domain_name
  igw_id                     = local.aws_internet_gateway
  public_subnets             = local.public_subnet_cidr_blocks
  private_subnets            = local.private_subnet_cidr_blocks
  # EC2 Inputs
  aws_key_name  = var.aws_key_name # This should be replaced with an admin level ssh cert.
  instance_type = var.instance_type
  # Network Routing Inputs.  source destination checks are disable for nat gateways or routing on an instance.
  source_dest_check = false
  # DNS Inputs
  consul_cluster_name    = var.consul_cluster_name
  consul_cluster_tag_key = var.consul_cluster_tag_key
  public_domain_name     = local.public_domain_name
  route_zone_id          = local.route_zone_id
  # # OpenVPN Inputs
  openvpn_user       = "openvpnas"
  openvpn_admin_user = "openvpnas"
  # SQS
  sqs_remote_in_vpn = var.sqs_remote_in_vpn
  host1             = var.host1
  host2             = var.host2
  sleep             = var.sleep
  common_tags       = local.common_tags
}
