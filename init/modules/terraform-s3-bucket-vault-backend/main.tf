
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}

locals {
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
    role = "terraform remote state"
  }
}

# See https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa for the origin of some of this code.

resource "aws_s3_bucket" "vault_backend" {
  bucket = "vault.${var.bucket_extension}"
  tags = merge(
    {"description" = "Used for Terraform remote state configuration. DO NOT DELETE this Bucket unless you know what you are doing."},
    local.common_tags,
  )
}
resource "aws_s3_bucket_acl" "acl_config" {
  bucket = aws_s3_bucket.vault_backend.id
  acl    = "private"
}
resource "aws_s3_bucket_versioning" "versioning_config" {
  # Enable versioning so we can see the full revision history of our
  # state files
  bucket = aws_s3_bucket.vault_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_config" {
  # Enable server-side encryption by default
  bucket = aws_s3_bucket.vault_backend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backend" { # https://medium.com/dnx-labs/terraform-remote-states-in-s3-d74edd24a2c4
  bucket = aws_s3_bucket.vault_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}