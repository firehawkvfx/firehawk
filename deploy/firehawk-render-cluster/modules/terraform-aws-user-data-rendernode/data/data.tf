# This is a module example of how to use data resources as variable inputs to other modules.
# See an example here https://github.com/gruntwork-io/terragrunt/issues/254

provider "aws" {}

data "aws_region" "current" {}

data "terraform_remote_state" "fsx" { # read the fsx export info
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-fsx/module/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

data "terraform_remote_state" "file_gateway" { # read the nfs export info
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-s3-file-gateway/module/terraform.tfstate"
    region = data.aws_region.current.name
  }
}