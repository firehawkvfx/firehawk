remote_state {
  backend = "s3"
  generate = {
    path      = "s3-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "state.terraform.$TF_VAR_bucket_extension"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "$AWS_DEFAULT_REGION"
    encrypt        = true
    dynamodb_table = "locks.state.terraform.$TF_VAR_bucket_extension"
  }
}
