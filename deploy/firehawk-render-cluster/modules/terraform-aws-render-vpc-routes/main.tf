data "aws_vpc" "primary" {
  default = false
  tags    = var.common_tags_rendervpc
}
data "aws_vpc" "secondary" {
  default = false
  tags    = var.common_tags_vaultvpc
}
data "aws_route_tables" "public" {
  vpc_id = data.aws_vpc.primary.id
  tags   = merge(var.common_tags_rendervpc, { "area" : "public" })
}
data "aws_route_tables" "private" {
  vpc_id = data.aws_vpc.primary.id
  tags   = merge(var.common_tags_rendervpc, { "area" : "private" })
}
data "aws_vpc_peering_connection" "primary2secondary" {
  vpc_id = data.aws_vpc.primary.id
  peer_vpc_id = data.aws_vpc.secondary.id
  tags = merge( var.common_tags_rendervpc, { "peer_to" : "vault" } )
}
locals {
  private_route_table_ids = sort(data.aws_route_tables.private.ids)
  public_route_table_ids  = sort(data.aws_route_tables.public.ids)
}
# Route tables to send traffic to the remote subnet are configured once the vpn is provisioned.
resource "aws_route" "private_openvpn_remote_subnet_gateway" {
  count = length(local.private_route_table_ids)
  route_table_id         = element(concat(local.private_route_table_ids, tolist([""])), count.index)
  destination_cidr_block = var.onsite_private_subnet_cidr
  vpc_peering_connection_id = data.aws_vpc_peering_connection.primary2secondary.id
  timeouts {
    create = "5m"
  }
}
resource "aws_route" "public_openvpn_remote_subnet_gateway" {
  count = length(local.public_route_table_ids)
  route_table_id         = element(concat(local.public_route_table_ids, tolist([""])), count.index)
  destination_cidr_block = var.onsite_private_subnet_cidr
  vpc_peering_connection_id = data.aws_vpc_peering_connection.primary2secondary.id
  timeouts {
    create = "5m"
  }
}

### routes may be needed for traffic going back to open vpn dhcp adresses
resource "aws_route" "private_openvpn_remote_subnet_vpndhcp_gateway" {
  count = length(local.private_route_table_ids)
  route_table_id         = element(concat(local.private_route_table_ids, tolist([""])), count.index)
  destination_cidr_block = var.vpn_cidr
  vpc_peering_connection_id = data.aws_vpc_peering_connection.primary2secondary.id
  timeouts {
    create = "5m"
  }
}
resource "aws_route" "public_openvpn_remote_subnet_vpndhcp_gateway" {
  count = length(local.public_route_table_ids)
  route_table_id         = element(concat(local.public_route_table_ids, tolist([""])), count.index)
  destination_cidr_block = var.vpn_cidr
  vpc_peering_connection_id = data.aws_vpc_peering_connection.primary2secondary.id
  timeouts {
    create = "5m"
  }
}
