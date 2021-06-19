data "aws_region" "current" {}
data "terraform_remote_state" "terraform_aws_sqs_ssh" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "init/modules/terraform-aws-sqs-ssh/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "terraform_remote_state" "terraform_aws_sqs_deadline_cert" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "init/modules/terraform-aws-sqs-deadline-cert/terraform.tfstate"
    region = data.aws_region.current.name
  }
}