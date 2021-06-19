data "aws_region" "current" {}
data "terraform_remote_state" "terraform_aws_sqs_ssh" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "init/modules/terraform-aws-sqs-ssh/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "terraform_remote_state" "terraform_aws_sqs_vpn" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "init/modules/terraform-aws-sqs-vpn/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "terraform_remote_state" "terraform_aws_secret_backend" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/vault-aws-secret-backend/module/terraform.tfstate"
    region = data.aws_region.current.name
  }
}