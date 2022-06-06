locals {
  common_tags          = var.common_tags
  common_tags_vaultvpc = var.common_tags_vaultvpc
}

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
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  rendervpc_id = length( try(data.terraform_remote_state.rendervpc.outputs.vpc_id, "") ) > 0 ? data.terraform_remote_state.rendervpc.outputs.vpc_id : ""
  vaultvpc_id = length( try(data.terraform_remote_state.vaultvpc.outputs.vpc_id, "") ) > 0 ? data.terraform_remote_state.vaultvpc.outputs.vpc_id : ""
}
data "aws_vpc" "primary" { # The primary is the VPC defined by the common tags var.
  count = length(local.rendervpc_id) > 0 ? 1 : 0
  default = false
  id = local.rendervpc_id
  # tags    = local.common_tags
}
data "aws_vpc" "secondary" { # The secondary VPC
  count = length(local.vaultvpc_id) > 0 ? 1 : 0
  default = false
  id = local.vaultvpc_id
}
resource "aws_vpc_peering_connection" "primary2secondary" {
  count = (length(local.rendervpc_id) > 0 && length(local.vaultvpc_id) > 0) ? 1 : 0
  vpc_id      = local.rendervpc_id   # Primary VPC ID.
  peer_vpc_id = local.vaultvpc_id # Secondary VPC ID.
  auto_accept = true                      # Flags that the peering connection should be automatically confirmed. This only works if both VPCs are owned by the same account.
  tags = merge( local.common_tags, { "peer_to" : "vault" } )
  # # AWS Account ID. This can be dynamically queried using the
  # # aws_caller_identity data resource.
  # # https://www.terraform.io/docs/providers/aws/d/caller_identity.html
  # peer_owner_id = "${data.aws_caller_identity.current.account_id}"
}
data "aws_route_table" "primary_private" {
  count = length(local.rendervpc_id) > 0 ? 1 : 0
  vpc_id = local.rendervpc_id
  tags = merge(local.common_tags, { "area" : "private" })
}
data "aws_route_table" "primary_public" {
  count = length(local.rendervpc_id) > 0 ? 1 : 0
  vpc_id = local.rendervpc_id
  tags = merge(local.common_tags, { "area" : "public" })
}
resource "aws_route" "primaryprivate2secondary" {
  count = (length(local.rendervpc_id) > 0 && length(local.vaultvpc_id) > 0) ? 1 : 0
  route_table_id            = data.aws_route_table.primary_private[0].id
  destination_cidr_block    = data.aws_vpc.secondary[0].cidr_block               # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
resource "aws_route" "primarypublic2secondary" {
  count = (length(local.rendervpc_id) > 0 && length(local.vaultvpc_id) > 0) ? 1 : 0
  route_table_id            = data.aws_route_table.primary_public[0].id
  destination_cidr_block    = data.aws_vpc.secondary[0].cidr_block               # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
data "aws_route_table" "secondary_private" {
  count = length(local.vaultvpc_id) > 0 ? 1 : 0
  vpc_id = local.vaultvpc_id
  tags = merge(local.common_tags_vaultvpc, { "area" : "private" })
}

data "aws_route_table" "secondary_public" {
  count = length(local.vaultvpc_id) > 0 ? 1 : 0
  vpc_id = local.vaultvpc_id
  tags = merge(local.common_tags_vaultvpc, { "area" : "public" })
}
resource "aws_route" "secondaryprivate2primary" {
  count = (length(local.rendervpc_id) > 0 && length(local.vaultvpc_id) > 0) ? 1 : 0
  route_table_id            = data.aws_route_table.secondary_private[0].id
  destination_cidr_block    = data.aws_vpc.primary[0].cidr_block                 # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
resource "aws_route" "secondarypublic2primary" {
  count = (length(local.rendervpc_id) > 0 && length(local.vaultvpc_id) > 0) ? 1 : 0
  route_table_id            = data.aws_route_table.secondary_public[0].id
  destination_cidr_block    = data.aws_vpc.primary[0].cidr_block                 # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
