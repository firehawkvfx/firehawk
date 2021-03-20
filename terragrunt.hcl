remote_state {
  backend = "s3"
  generate = {
    path      = "s3-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "state.terraform.${var.bucket_extension}"

    key = "${path_relative_to_include()}/terraform.tfstate"
    region         = var.aws_default_region
    encrypt        = true
    dynamodb_table = "locks.state.terraform.${var.bucket_extension}"
  }
}