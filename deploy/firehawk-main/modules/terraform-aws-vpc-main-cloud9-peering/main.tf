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
  vaultvpc = try(data.terraform_remote_state.vaultvpc.outputs.vpc_id, "")
}
data "aws_vpc" "primary" { # The primary is the VPC defined by the common tags var.
  count   = length(local.vaultvpc) > 0 ? 1 : 0
  default = false
  id      = local.vaultvpc
  # tags    = var.common_tags_vaultvpc
}
data "aws_vpc" "secondary" { # The secondary is the VPC containing the cloud 9 instance. 
  id = var.vpc_id_main_provisioner
}
resource "aws_vpc_peering_connection" "primary2secondary" {
  count       = length(local.vaultvpc) > 0 ? 1 : 0
  vpc_id      = data.aws_vpc.primary[0].id # Primary VPC ID.
  peer_vpc_id = data.aws_vpc.secondary.id  # Secondary VPC ID.
  auto_accept = true                       # Flags that the peering connection should be automatically confirmed. This only works if both VPCs are owned by the same account.

  # # AWS Account ID. This can be dynamically queried using the
  # # aws_caller_identity data resource.
  # # https://www.terraform.io/docs/providers/aws/d/caller_identity.html
  # peer_owner_id = "${data.aws_caller_identity.current.account_id}"
}
data "aws_route_table" "primary_private" {
  count  = length(local.vaultvpc) > 0 ? 1 : 0
  vpc_id = local.vaultvpc
  tags   = merge(var.common_tags_vaultvpc, { "area" : "private" })
}
data "aws_route_table" "primary_public" {
  count  = length(local.vaultvpc) > 0 ? 1 : 0
  vpc_id = local.vaultvpc
  tags   = merge(var.common_tags_vaultvpc, { "area" : "public" })
}
data "aws_route_table" "secondary_private" {
  vpc_id = data.aws_vpc.secondary.id
  tags   = merge(var.common_tags_deployervpc, { "area" : "private" })
}
data "aws_route_table" "secondary_public" {
  vpc_id = data.aws_vpc.secondary.id
  tags   = merge(var.common_tags_deployervpc, { "area" : "public" })
}
resource "aws_route" "primaryprivate2secondary" {
  count                     = length(local.vaultvpc) > 0 ? 1 : 0
  route_table_id            = data.aws_route_table.primary_private[0].id
  destination_cidr_block    = data.aws_vpc.secondary.cidr_block                  # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
resource "aws_route" "primarypublic2secondary" {
  count                     = length(local.vaultvpc) > 0 ? 1 : 0
  route_table_id            = data.aws_route_table.primary_public[0].id
  destination_cidr_block    = data.aws_vpc.secondary.cidr_block                  # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
resource "aws_route" "secondaryprivate2primary" {
  count                     = length(local.vaultvpc) > 0 ? 1 : 0
  route_table_id            = data.aws_route_table.secondary_private.id          # ID of VPC 2 main route table.
  destination_cidr_block    = data.aws_vpc.primary[0].cidr_block                 # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
resource "aws_route" "secondarypublic2primary" {
  count                     = length(local.vaultvpc) > 0 ? 1 : 0
  route_table_id            = data.aws_route_table.secondary_public.id           # ID of VPC 2 main route table.
  destination_cidr_block    = data.aws_vpc.primary[0].cidr_block                 # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
