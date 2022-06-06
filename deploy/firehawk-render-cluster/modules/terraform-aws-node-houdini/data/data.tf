# This is a module example of how to use data resources as variable inputs to other modules.
# See an example here https://github.com/gruntwork-io/terragrunt/issues/254

provider "aws" {}

data "aws_region" "current" {}

data "terraform_remote_state" "user_data" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-user-data-rendernode/module/terraform.tfstate"
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
data "terraform_remote_state" "vaultvpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-main/modules/vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
# data "aws_vpc" "rendervpc" {
#   default = false
#   tags    = var.common_tags_rendervpc
# }
# data "aws_vpc" "vaultvpc" {
#   default = false
#   tags    = var.common_tags_vaultvpc
# }