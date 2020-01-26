provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  region = var.region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  #source = "../terraform-aws-vpc"
  create_vpc = var.create_vpc

  name = "firehawk-compute"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # if sleep is true, then nat is disabled to save costs during idle time.
  enable_nat_gateway     = var.sleep || false == var.enable_nat_gateway ? false : true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  #not sure if this is actually required - it seems mroe related to aws type vpn gateway as a paid service
  #enable_vpn_gateway = true

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

variable "remote_subnet_cidr" {
}

variable "route_public_domain_name" {
}

module "vpn" {
  source = "../vpn"

  create_vpn = var.create_vpc

  aws_region = var.region

  route_public_domain_name = var.route_public_domain_name

  # dummy attribute to force dependency on IGW.
  igw_id = module.vpc.igw_id

  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr

  #the cidr range that the vpn will assign to remote addresses within the vpc if routing.
  vpn_cidr           = var.vpn_cidr
  remote_subnet_cidr = var.remote_subnet_cidr

  #the remote public address that will connect to the openvpn instance
  remote_vpn_ip_cidr = var.remote_ip_cidr
  public_subnet_ids  = module.vpc.public_subnets

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.
  route_zone_id      = var.route_zone_id
  key_name           = var.key_name
  private_key        = file(var.local_key_path)
  local_key_path     = var.local_key_path
  cert_arn           = var.cert_arn
  public_domain_name = var.public_domain_name
  openvpn_user       = var.openvpn_user
  openvpn_user_pw    = var.openvpn_user_pw
  openvpn_admin_user = var.openvpn_admin_user
  openvpn_admin_pw   = var.openvpn_admin_pw

  bastion_ip = var.bastion_ip
  bastion_dependency = var.bastion_dependency

  #sleep will stop instances to save cost during idle time.
  sleep = var.sleep
}

locals {
  max_subnet_length = length(var.private_subnets)
  nat_gateway_count = length(module.vpc.natgw_ids)
}

resource "null_resource" "dependency_vpc" {
  triggers = {
    vpc_id = module.vpc.vpc_id
  }
}

resource "null_resource" "dependency_vpn" {
  triggers = {
    vpn_id = module.vpn.id
  }
}

resource "aws_route" "private_openvpn_remote_subnet_gateway" {
  count = var.create_vpc ? length(var.private_subnets) : 0
  depends_on = [
    null_resource.dependency_vpc,
    null_resource.dependency_vpn,
  ]

  route_table_id         = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block = var.remote_subnet_cidr
  instance_id            = module.vpn.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_openvpn_remote_subnet_gateway" {
  count = var.create_vpc ? length(var.private_subnets) : 0
  depends_on = [
    null_resource.dependency_vpc,
    null_resource.dependency_vpn,
  ]

  route_table_id         = element(module.vpc.public_route_table_ids, count.index)
  destination_cidr_block = var.remote_subnet_cidr
  instance_id            = module.vpn.id

  timeouts {
    create = "5m"
  }
}

### routes may be needed for traffic going back to open vpn dhcp adresses
resource "aws_route" "private_openvpn_remote_subnet_vpndhcp_gateway" {
  count = var.create_vpc ? length(var.private_subnets) : 0
  depends_on = [
    null_resource.dependency_vpc,
    null_resource.dependency_vpn,
  ]

  route_table_id         = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block = var.vpn_cidr
  instance_id            = module.vpn.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_openvpn_remote_subnet_vpndhcp_gateway" {
  count = var.create_vpc ? length(var.private_subnets) : 0
  depends_on = [
    null_resource.dependency_vpc,
    null_resource.dependency_vpn,
  ]

  route_table_id         = element(module.vpc.public_route_table_ids, count.index)
  destination_cidr_block = var.vpn_cidr
  instance_id            = module.vpn.id

  timeouts {
    create = "5m"
  }
}

# ##########################
# # Route table association
# ##########################
# resource "aws_route_table_association" "openvpn" {
#   count = "${length(var.private_subnets)}"
#   subnet_id      = "${element(module.vpc.private_subnets, count.index)}"
#   route_table_id = "${element(aws_route_table.openvpn.*.id, count.index)}"
# }
