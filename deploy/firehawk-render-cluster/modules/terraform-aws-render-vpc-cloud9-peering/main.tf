data "aws_region" "current" {}

data "terraform_remote_state" "rendervpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-render-vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  rendervpc_id = try(data.terraform_remote_state.rendervpc.outputs.vpc_id, "")
}
data "aws_vpc" "primary" { # The primary is the VPC defined by the common tags var.
  count = length(local.rendervpc_id) > 0 ? 1 : 0
  default = false
  id = local.rendervpc_id
  # tags    = var.common_tags_rendervpc
}
data "aws_vpc" "secondary" { # The secondary VPC
  default = false
  id = var.vpc_id_main_provisioner
}
resource "aws_vpc_peering_connection" "primary2secondary" {
  count = length(data.aws_vpc.primary) > 0 ? 1 : 0
  vpc_id      = data.aws_vpc.primary[0].id   # Primary VPC ID.
  peer_vpc_id = data.aws_vpc.secondary.id # Secondary VPC ID.
  auto_accept = true                      # Flags that the peering connection should be automatically confirmed. This only works if both VPCs are owned by the same account.
  tags = merge( var.common_tags_rendervpc, { "peer_to" : "cloud9" } )
  # # AWS Account ID. This can be dynamically queried using the
  # # aws_caller_identity data resource.
  # # https://www.terraform.io/docs/providers/aws/d/caller_identity.html
  # peer_owner_id = "${data.aws_caller_identity.current.account_id}"
}
data "aws_route_table" "rendervpc_private" {
  count = length(data.aws_vpc.primary) > 0 ? 1 : 0
  tags = merge( var.common_tags_rendervpc, { "area" : "private" } )
}
data "aws_route_table" "rendervpc_public" {
  count = length(data.aws_vpc.primary) > 0 ? 1 : 0
  tags = merge( var.common_tags_rendervpc, { "area" : "public" } )
}
data "aws_route_table" "deployervpc_private" {
  count = length(data.aws_vpc.primary) > 0 ? 1 : 0
  tags = merge( var.common_tags_deployervpc, { "area" : "private" } )
}
data "aws_route_table" "deployervpc_public" {
  count = length(data.aws_vpc.primary) > 0 ? 1 : 0
  tags = merge( var.common_tags_deployervpc, { "area" : "public" } )
}
resource "aws_route" "primaryprivate2secondary" {
  count = length(data.aws_vpc.primary) > 0 ? 1 : 0
  route_table_id            = data.aws_route_table.rendervpc_private[0].id
  destination_cidr_block    = data.aws_vpc.secondary.cidr_block               # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
resource "aws_route" "primarypublic2secondary" {
  count = length(data.aws_vpc.primary) > 0 ? 1 : 0
  route_table_id            = data.aws_route_table.rendervpc_public[0].id
  destination_cidr_block    = data.aws_vpc.secondary.cidr_block               # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
resource "aws_route" "secondaryprivate2primary" {
  count = length(data.aws_vpc.primary) > 0 ? 1 : 0
  route_table_id            = data.aws_route_table.deployervpc_private[0].id      # ID of VPC 2 main route table.
  destination_cidr_block    = data.aws_vpc.primary[0].cidr_block                 # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}
resource "aws_route" "secondarypublic2primary" {
  count = length(data.aws_vpc.primary) > 0 ? 1 : 0
  route_table_id            = data.aws_route_table.deployervpc_public[0].id      # ID of VPC 2 main route table.
  destination_cidr_block    = data.aws_vpc.primary[0].cidr_block                 # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary[0].id # ID of VPC peering connection.
}