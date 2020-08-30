provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  region = var.region
  # version = "~> 3.0"
}

variable "firehawk_init_dependency" {
}

resource "null_resource" "firehawk_init_dependency" {
  triggers = {
    firehawk_init_dependency = var.firehawk_init_dependency
  }
}

variable "common_tags" {}

locals {
  name = "firehawk_${lookup(var.common_tags, "resourcetier", "0")}_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  extra_tags = { 
    role = "vpc"
    Name = local.name
  }
}

resource "aws_vpc" "main" {
  count       = var.create_vpc ? 1 : 0

  cidr_block       = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, local.extra_tags, map("Name", format("%s", local.name)))
}

resource "aws_vpc_dhcp_options" "main" {
  count       = var.create_vpc ? 1 : 0
  domain_name          = var.private_domain # This may not be available to be customised for us-east-1
  domain_name_servers  = ["AmazonProvidedDNS"]
  tags = merge(var.common_tags, local.extra_tags, map("Name", format("dhcpoptions_%s", local.name)))
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  count       = var.create_vpc ? 1 : 0
  vpc_id          = local.vpc_id
  dhcp_options_id = local.aws_vpc_dhcp_options_id
}

resource "aws_internet_gateway" "gw" {
  count = var.create_vpc ? 1 : 0
  
  vpc_id = local.vpc_id

  tags = merge(var.common_tags, local.extra_tags, map("Name", format("igw_%s", local.name)))
}

locals {
  vpc_id = element( concat( aws_vpc.main.*.id, list("")), 0 )
  aws_vpc_dhcp_options_id = element( concat( aws_vpc_dhcp_options.main.*.id, list("")), 0 )
  aws_internet_gateway = element( concat( aws_internet_gateway.gw.*.id, list("")), 0 )
  vpc_main_route_table_id = element( concat( aws_vpc.main.*.main_route_table_id, list("")), 0 )
  vpc_cidr_block = element( concat( aws_vpc.main.*.cidr_block, list("")), 0 )
  private_subnets = aws_subnet.private_subnet.*.id
  private_subnet1_id = element( concat( aws_subnet.private_subnet.*.id, list("")), 0 )
  private_subnet2_id = element( concat( aws_subnet.private_subnet.*.id, list("")), 1 )
  public_subnets = aws_subnet.public_subnet.*.id
  private_route_table_ids = aws_route_table.private.*.id
  public_route_table_ids = aws_route_table.public.*.id
  private_route53_zone_id = element( concat( aws_route53_zone.private.*.id, list("")), 0 )
}

resource "aws_route53_zone" "private" { # the private hosted zone is used for host names privately ending with the domain name.
  count = var.create_vpc ? 1 : 0

  name = var.private_domain
  vpc {
    vpc_id = local.vpc_id
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet" {
  count = var.create_vpc ? length( var.public_subnets ) : 0
  vpc_id                  = local.vpc_id

  availability_zone = element( data.aws_availability_zones.available.names, count.index )
  cidr_block              = element( var.public_subnets, count.index )
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.gw]

  tags = merge(var.common_tags, local.extra_tags, map("Name", format("public%s_%s", count.index, local.name)))
}

resource "aws_subnet" "private_subnet" {
  count = var.create_vpc ? length( var.private_subnets ) : 0
  vpc_id     = local.vpc_id

  availability_zone = element( data.aws_availability_zones.available.names, count.index )
  cidr_block = element(var.private_subnets, count.index)
  tags = merge(var.common_tags, local.extra_tags, map("Name", format("private%s_%s", count.index, local.name)))
}

resource "aws_eip" "nat" { 
  count = var.create_vpc && var.enable_nat_gateway && var.sleep == false ? 1 : 0

  vpc = true
  depends_on                = [aws_internet_gateway.gw]

  tags = merge(var.common_tags, local.extra_tags, map("Name", format("%s", local.name)))
}

resource "aws_nat_gateway" "gw" { # We use a single nat gateway currently to save cost.
  count = var.create_vpc && var.enable_nat_gateway && var.sleep == false ? 1 : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element( aws_subnet.public_subnet.*.id, count.index )
  tags = merge(var.common_tags, local.extra_tags, map("Name", format("%s", local.name)))
}

resource "aws_route_table" "private" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = local.vpc_id
  tags = merge(var.common_tags, local.extra_tags, map("Name", "${local.name}_private"))
}

resource "aws_route" "private_nat_gateway" {
  count = var.create_vpc ? 1 : 0
  route_table_id         = element(concat(aws_route_table.private.*.id, list("")), 0)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(concat(aws_nat_gateway.gw.*.id, list("")), 0)
  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "public" {
  count       = var.create_vpc ? 1 : 0
  vpc_id = local.vpc_id
  tags = merge(var.common_tags, local.extra_tags, map("Name", "${local.name}_public"))
}

resource "aws_route" "public_gateway" {
  count = var.create_vpc ? 1 : 0
  route_table_id         = element(concat(aws_route_table.public.*.id, list("")), 0)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[count.index].id
  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private_associations" {
  depends_on = [ aws_subnet.private_subnet ]
  count = var.create_vpc ? length( local.private_subnets ) : 0

  subnet_id      = element( aws_subnet.private_subnet.*.id, count.index )
  route_table_id = element( aws_route_table.private.*.id, 0 )
}

resource "aws_route_table_association" "public_associations" {
  depends_on = [ aws_subnet.public_subnet ]
  count = var.create_vpc ? length( local.public_subnets ) : 0

  subnet_id      = element( aws_subnet.public_subnet.*.id, count.index )
  route_table_id = element( aws_route_table.public.*.id, 0 )
}

### Route 53 resolver for DNS


resource "aws_security_group" "resolver" {
  count = var.create_vpc ? 1 : 0
  name        = format("resolver_%s", local.name)
  vpc_id      = local.vpc_id
  description = "Route 53 Resolver security group"

  tags = merge(var.common_tags, local.extra_tags, map("Name", format("resolver_%s", local.name)))

  ingress {
    protocol    = "-1"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [var.vpc_cidr, var.vpn_cidr, var.remote_subnet_cidr, var.remote_vpn_ip_cidr]

    description = "all incoming traffic from vpc, vpn dhcp, and remote subnet"
  }

  egress {
    protocol    = "-1"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [var.vpc_cidr, var.vpn_cidr, var.remote_subnet_cidr, var.remote_ip_cidr]

    description = "all incoming traffic from vpc, vpn dhcp, and remote subnet"
  }
}

resource "aws_route53_resolver_endpoint" "main" {
  count = var.create_vpc ? 1 : 0

  name      = "main"
  direction = "INBOUND"

  security_group_ids = aws_security_group.resolver.*.id

  ip_address {
    subnet_id = local.private_subnet1_id
    ip        = cidrhost(element( var.public_subnets, 0 ), 3)
  }

  ip_address {
    subnet_id = local.private_subnet2_id
    ip        = cidrhost(element( var.public_subnets, 1 ), 3)
  }

  tags = merge(var.common_tags, local.extra_tags, map("Name", format("resolver_%s", local.name)))
}

resource "aws_route53_resolver_rule" "sys" {
  count = var.create_vpc ? 1 : 0
  
  domain_name = var.private_domain
  rule_type   = "SYSTEM"
}

# module "vpc" { # this can simplify things but it is an external dependency, so it is left here latent incase needed.
#   source = "terraform-aws-modules/vpc/aws"
#   version = "~> 2.44.0"

#   create_vpc = var.create_vpc

#   name = local.name
#   cidr = var.vpc_cidr

#   azs             = var.azs
#   private_subnets = var.private_subnets
#   public_subnets  = var.public_subnets

#   # if sleep is true, then nat is disabled to save costs during idle time.
#   enable_nat_gateway     = var.sleep || false == var.enable_nat_gateway ? false : true
#   single_nat_gateway     = true
#   one_nat_gateway_per_az = false

#   #not sure if this is actually required - it seems mroe related to aws type vpn gateway as a paid service
#   #enable_vpn_gateway = true

#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = merge(map("Name", format("%s", local.name)), var.common_tags, local.extra_tags)
  
# }

variable "remote_subnet_cidr" {
}

variable "route_public_domain_name" {
}

module "vpn" {
  source = "../vpn"

  create_vpn = var.create_vpc

  aws_region = var.region

  route_public_domain_name = var.route_public_domain_name
  private_domain_name = var.private_domain

  # dummy attribute to force dependency on IGW.
  igw_id = local.aws_internet_gateway

  vpc_id   = local.vpc_id
  vpc_cidr = var.vpc_cidr

  #the cidr range that the vpn will assign to remote addresses within the vpc if routing.
  vpn_cidr           = var.vpn_cidr
  remote_subnet_cidr = var.remote_subnet_cidr

  private_route_table_ids = local.private_route_table_ids
  public_route_table_ids  = local.public_route_table_ids

  #the remote public address that will connect to the openvpn instance
  remote_vpn_ip_cidr = var.remote_ip_cidr
  public_subnet_ids  = local.public_subnets

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.
  route_zone_id      = var.route_zone_id
  aws_key_name           = var.aws_key_name
  private_key        = file(var.aws_private_key_path)
  aws_private_key_path     = var.aws_private_key_path
  cert_arn           = var.cert_arn
  public_domain_name = var.public_domain_name
  openvpn_user       = var.openvpn_user
  openvpn_user_pw    = var.openvpn_user_pw
  openvpn_admin_user = var.openvpn_admin_user
  openvpn_admin_pw   = var.openvpn_admin_pw

  bastion_ip = var.bastion_ip
  bastion_dependency = var.bastion_dependency
  firehawk_init_dependency = var.firehawk_init_dependency

  #sleep will stop instances to save cost during idle time.
  sleep = var.sleep

  common_tags = var.common_tags
}

# resource "null_resource" "dependency_vpc" {
#   triggers = {
#     vpc_id = local.vpc_id
#   }
# }

# resource "null_resource" "dependency_vpn" {
#   triggers = {
#     vpn_id = module.vpn.id
#   }
# }