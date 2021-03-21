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

terraform {
  before_hook "before_hook_1" {
    commands = ["apply", "plan", "destroy"]
    execute  = ["source", "./update_vars.sh"]
  }
  inputs {
    vpcname     = "vaultvpc"
    projectname = "firehawk-main" # A tag to recognise resources created in this project
  }
}