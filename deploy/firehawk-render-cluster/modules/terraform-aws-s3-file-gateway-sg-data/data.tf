# This is a module example of how to use data resources as variable inputs to other modules.
# See an example here https://github.com/gruntwork-io/terragrunt/issues/254

provider "aws" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "cloud_s3_gateway" {
  name = "/firehawk/resourcetier/${var.resourcetier}/cloud_s3_gateway"
}
data "aws_ssm_parameter" "cloud_s3_gateway_mount_target" {
  name = "/firehawk/resourcetier/${var.resourcetier}/cloud_s3_gateway_mount_target"
}
data "aws_ssm_parameter" "cloud_s3_gateway_size" {
  name = "/firehawk/resourcetier/${var.resourcetier}/cloud_s3_gateway_size"
}
data "aws_s3_bucket" "rendering_bucket" {
  bucket        = var.s3_bucket_name
}
data "terraform_remote_state" "rendervpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-render-vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  rendervpc_id = length( try(data.terraform_remote_state.rendervpc.outputs.vpc_id, "" ) ) > 0 ? data.terraform_remote_state.rendervpc.outputs.vpc_id : ""
}
data "aws_vpc" "rendervpc" {
  count = length(local.rendervpc_id) > 0 ? 1 : 0
  default = false
  id = local.rendervpc_id
}
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = length(local.rendervpc_id) > 0 ? [local.rendervpc_id] : []
  }
  tags = {
    area = "private"
  }
}
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = length(local.rendervpc_id) > 0 ? [local.rendervpc_id] : []
  }
  tags = {
    area = "public"
  }
}
data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}