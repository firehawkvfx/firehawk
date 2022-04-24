remote_state {
  backend = "s3"
  generate = {
    path      = "s3-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "state.terraform.${get_env("TF_VAR_bucket_extension", "")}"
    key            = "predeploy/${path_relative_to_include()}/terraform.tfstate"
    region         = "${get_env("AWS_DEFAULT_REGION", "")}"
    encrypt        = true
    dynamodb_table = "locks.state.terraform.${get_env("TF_VAR_bucket_extension", "")}"
  }
}