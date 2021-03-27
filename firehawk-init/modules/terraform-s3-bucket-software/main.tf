# This template creates an S3 bucket and a role with access to share with other AWS account ARNS.  By default the current account id (assumed to be your main account) is added to the list of ARNS to able assume the role (even though it is unnecessary, since it has access through another seperate policy) and access the bucket to demonstrate the role, but other account ID's / ARNS can be listed as well.

provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}

data "aws_caller_identity" "current" {}
locals {
  common_tags = merge( var.common_tags, { role = "shared bucket" } )
  share_with_arns = concat( [ data.aws_caller_identity.current.account_id ], var.share_with_arns )
  # vault_map = element( concat( data.vault_generic_secret.installers_bucket.*.data, list({}) ), 0 )
  # bucket_name = var.use_vault && contains( keys(local.vault_map), "value" ) ? lookup( local.vault_map, "value", var.bucket_name) : var.bucket_name
  bucket_name = var.installers_bucket
}

# See https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa for the origin of some of this code.

# data "vault_generic_secret" "installers_bucket" { # The name of the bucket is defined in vault  
#   count = var.use_vault ? 1 : 0
#   path = "main/aws/installers_bucket"
# }
resource "aws_s3_bucket" "shared_bucket" {
  bucket = local.bucket_name
  acl    = "private"
  versioning {
    enabled = false
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = merge(
    {"description" = "Used for storing files for reuse accross accounts."},
    local.common_tags,
  )
}
resource "aws_s3_bucket_public_access_block" "backend" { # https://medium.com/dnx-labs/terraform-remote-states-in-s3-d74edd24a2c4
  bucket = aws_s3_bucket.shared_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# we create a role that would be used for cross account access to the bucket.
resource "aws_iam_role" "multi_account_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.multi_account_assume_role_policy.json
}
# Define who is allowed to assume the role
data "aws_iam_policy_document" "multi_account_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = local.share_with_arns
    }
    actions = ["sts:AssumeRole"]
  }
}
# Define policy for the bucket restricting access to the role
module "iam_policies_s3_shared_bucket" {
  source = "../../modules/aws-iam-policies-s3-shared-bucket"
  bucket_name = local.bucket_name
  multi_account_role_arn = aws_iam_role.multi_account_role.arn
}

# Define policy for the role allowing access to the bucket.
module "iam_policies_s3_multi_account_role" {
  source = "../../modules/aws-iam-policies-s3-multi-account-role"
  name = "MultiAccountRolePolicyS3BucketAccess_${var.conflictkey}"
  iam_role_id = aws_iam_role.multi_account_role.id
  shared_bucket_arn = aws_s3_bucket.shared_bucket.arn
}