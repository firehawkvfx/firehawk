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

variable "bucket_extension" {
  description = "The extension for cloud storage used to label your S3 storage buckets (eg: example.com, my-name-at-gmail.com). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html"
  type = string
}