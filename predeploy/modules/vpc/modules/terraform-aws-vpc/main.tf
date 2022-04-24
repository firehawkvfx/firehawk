locals {
  name = var.vpc_name
  extra_tags = {
    role = "vpc"
    Name = local.name
  }
  vpc_tags = merge(var.common_tags, local.extra_tags, tomap({ "Name" : local.name }))
}

resource "aws_vpc" "primary" { # primary should be the main vpc, or hub.
  count                = var.create_vpc ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.vpc_tags
}

resource "aws_vpc_dhcp_options" "primary" {
  count                = var.create_vpc ? 1 : 0
  domain_name          = "service.consul"
  domain_name_servers  = ["127.0.0.1", "AmazonProvidedDNS"]
  ntp_servers          = ["127.0.0.1"]
  netbios_name_servers = ["127.0.0.1"]
  netbios_node_type    = 2
  tags                 = merge(var.common_tags, local.extra_tags, tomap({ "Name" : format("dhcpoptions_%s", local.name) }))
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  count           = var.create_vpc ? 1 : 0
  vpc_id          = local.vpc_id
  dhcp_options_id = local.aws_vpc_dhcp_options_id
}

resource "aws_internet_gateway" "gw" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(var.common_tags, local.extra_tags, tomap({ "Name" : format("igw_%s", local.name) }))
}

locals {
  vpc_id                  = element(concat(aws_vpc.primary.*.id, tolist([""])), 0)
  aws_vpc_dhcp_options_id = element(concat(aws_vpc_dhcp_options.primary.*.id, tolist([""])), 0)
  aws_internet_gateway    = element(concat(aws_internet_gateway.gw.*.id, tolist([""])), 0)
  private_subnets         = var.create_vpc ? aws_subnet.private_subnet.*.id : []
  subnet_names = [
    for i in range(length(var.private_subnets)) : format("private%s_%s", i, local.name)
  ]
  public_subnets             = var.create_vpc ? aws_subnet.public_subnet.*.id : []
  public_subnets_cidr_blocks = var.public_subnets
  private_route_table_ids    = aws_route_table.private.*.id
  public_route_table_ids     = aws_route_table.public.*.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet" {
  depends_on              = [aws_vpc.primary, aws_internet_gateway.gw]
  count                   = var.create_vpc ? length(var.public_subnets) : 0
  vpc_id                  = local.vpc_id
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  cidr_block              = element(var.public_subnets, count.index)
  map_public_ip_on_launch = true
  tags                    = merge(var.common_tags, local.extra_tags, tomap({ "area" : "public" }), tomap({ "Name" : format("public%s_%s", count.index, local.name) }))
}

locals {

}

resource "aws_subnet" "private_subnet" {
  depends_on        = [aws_vpc.primary]
  count             = var.create_vpc ? length(var.private_subnets) : 0
  vpc_id            = local.vpc_id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block        = element(var.private_subnets, count.index)
  tags              = merge(var.common_tags, local.extra_tags, tomap({ "area" : "private" }), tomap({ "Name" : format("private%s_%s", count.index, local.name) }))
}

resource "aws_eip" "nat" {
  count      = var.create_vpc && var.enable_nat_gateway && var.sleep == false ? 1 : 0
  vpc        = true
  depends_on = [aws_internet_gateway.gw]
  tags       = merge(var.common_tags, local.extra_tags, tomap({"Name": format("%s", local.name)}))
}

resource "aws_nat_gateway" "gw" { # We use a single nat gateway currently to save cost.
  count         = var.create_vpc && var.enable_nat_gateway && var.sleep == false ? 1 : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)
  tags          = merge(var.common_tags, local.extra_tags, tomap({"Name": format("%s", local.name)}))
}

resource "aws_route_table" "private" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(var.common_tags, local.extra_tags, tomap({ "area" : "private" }), tomap({ "Name" : "${local.name}_private" }))
}

resource "aws_route" "private_nat_gateway" {
  count                  = var.create_vpc && var.enable_nat_gateway && var.sleep == false ? 1 : 0
  route_table_id         = element(concat(aws_route_table.private.*.id, tolist([""])), 0)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(concat(aws_nat_gateway.gw.*.id, tolist([""])), 0)
  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "public" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(var.common_tags, local.extra_tags, tomap({ "area" : "public" }), tomap({ "Name" : "${local.name}_public" }))
}

resource "aws_route" "public_gateway" {
  count                  = var.create_vpc ? 1 : 0
  route_table_id         = element(concat(aws_route_table.public.*.id, tolist([""])), 0)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[count.index].id
  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private_associations" {
  depends_on     = [aws_vpc.primary, aws_subnet.private_subnet]
  count          = var.create_vpc ? length(var.public_subnets) : 0
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, 0)
}

resource "aws_route_table_association" "public_associations" {
  depends_on     = [aws_vpc.primary, aws_subnet.public_subnet]
  count          = var.create_vpc ? length(var.public_subnets) : 0
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, 0)
}
