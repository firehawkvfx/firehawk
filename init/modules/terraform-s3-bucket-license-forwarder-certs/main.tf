provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 4.1.0"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}

locals {
  bucket_name = "ublcerts.${var.bucket_extension}"
  common_tags = {
    environment  = var.environment
    resourcetier = var.resourcetier
    conflictkey  = var.conflictkey
    # The conflict key defines a name space where duplicate resources in different deployments sharing this name are prevented from occuring.  This is used to prevent a new deployment overwriting and existing resource unless it is destroyed first.
    # examples might be blue, green, dev1, dev2, dev3...dev100.  This allows us to lock deployments on some resources.
    pipelineid = var.pipelineid
    owner      = data.aws_canonical_user_id.current.display_name
    accountid  = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    terraform  = "true"
    role = "deadline license forwarder"
  }
}

# See https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa for the origin of some of this code.

resource "aws_s3_bucket" "license_forwarder_cert_bucket" {
  bucket = local.bucket_name
  tags = merge(
    {"description" = "Used for Terraform remote state configuration. DO NOT DELETE this Bucket unless you know what you are doing."},
    local.common_tags,
  )
}
resource "aws_s3_bucket_acl" "acl_config" {
  bucket = aws_s3_bucket.license_forwarder_cert_bucket.id
  acl    = "private"
}
resource "aws_s3_bucket_versioning" "versioning_config" {
  bucket = aws_s3_bucket.license_forwarder_cert_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_config" {
  bucket = aws_s3_bucket.license_forwarder_cert_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "base_folder" {
  bucket  = aws_s3_bucket.license_forwarder_cert_bucket.id
  acl     = "private"
  key     =  "ublcertszip/"
  content_type = "application/x-directory"
}

resource "aws_s3_bucket_public_access_block" "backend" { # https://medium.com/dnx-labs/terraform-remote-states-in-s3-d74edd24a2c4
  depends_on = [aws_s3_bucket.license_forwarder_cert_bucket]
  bucket = aws_s3_bucket.license_forwarder_cert_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "terraform_remote_state" "deadline_db_profile" { # The deadline DB instance role / profile is read to be given permission to read from the bucket 
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "init/modules/terraform-aws-iam-profile-deadline-db/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

module "iam_policies_s3_license_forwarder_certs_bucket" { # policy for the bucket allowing access by the role
  source = "../../../deploy/firehawk-main/modules/aws-iam-policies-s3-license-forwarder-certs-bucket"
  depends_on = [aws_s3_bucket.license_forwarder_cert_bucket]
  bucket_name = local.bucket_name
  multi_account_role_arn = data.terraform_remote_state.deadline_db_profile.outputs.instance_role_arn
}

module "iam_policies_s3_multi_account_role" { # Define policy for the role allowing access to the bucket.
  source = "../../../deploy/firehawk-main/modules/aws-iam-policies-s3-multi-account-role"
  depends_on = [aws_s3_bucket.license_forwarder_cert_bucket]
  name = "MultiAccountRolePolicyS3BucketDeadlineLicenseForwarderAccess_${var.conflictkey}"
  iam_role_id = data.terraform_remote_state.deadline_db_profile.outputs.instance_role_id
  shared_bucket_arn = aws_s3_bucket.license_forwarder_cert_bucket.arn
}

