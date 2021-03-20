remote_state {
  backend = "s3"
  generate = {
    path      = "s3-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "state.terraform.dev.firehawkvfx.com"

    key = "${path_relative_to_include()}/terraform.tfstate"
    region         = ap-southeast-2
    encrypt        = true
    dynamodb_table = "locks.state.terraform.dev.firehawkvfx.com"
  }
}