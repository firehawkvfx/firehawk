# This is a module example of how to use data resources as variable inputs to other modules.
# See an example here https://github.com/gruntwork-io/terragrunt/issues/254

data "aws_region" "current" {}
data "terraform_remote_state" "bastion_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/terraform-aws-sg-bastion/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "terraform_remote_state" "vpn_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-sg-vpn/terraform.tfstate"
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
data "terraform_remote_state" "rendervpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-render-vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  vaultvpc_id  = length( try(data.terraform_remote_state.vaultvpc.outputs.vpc_id, "") ) > 0 ? data.terraform_remote_state.vaultvpc.outputs.vpc_id : ""
  rendervpc_id = length( try(data.terraform_remote_state.rendervpc.outputs.vpc_id, "") ) > 0 ? data.terraform_remote_state.rendervpc.outputs.vpc_id : ""
}
data "aws_vpc" "rendervpc" {
  count = length(local.rendervpc_id) > 0 ? 1 : 0
  default = false
  id      = local.rendervpc_id
}
data "aws_vpc" "vaultvpc" {
  count = length(local.vaultvpc_id) > 0 ? 1 : 0
  default = false
  id      = local.vaultvpc_id
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
output "bastion_security_group" {
  value = try(data.terraform_remote_state.bastion_security_group.outputs.security_group_id, null)
}
output "vpn_security_group" {
  value = try(data.terraform_remote_state.vpn_security_group.outputs.security_group_id, null)
}
output "rendervpc_id" {
  value = local.rendervpc_id
}
output "vaultvpc_id" {
  value = local.vaultvpc_id
}
output "rendervpc_cidr" {
  value = length(data.aws_vpc.rendervpc) > 0 ? data.aws_vpc.rendervpc[0].cidr_block : ""
}
output "vaultvpc_cidr" {
  value = length(data.aws_vpc.vaultvpc) > 0 ? data.aws_vpc.vaultvpc[0].cidr_block : ""
}
output "private_subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.private : s.cidr_block]
}
