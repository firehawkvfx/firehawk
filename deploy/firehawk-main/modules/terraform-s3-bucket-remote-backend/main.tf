locals {
  common_tags = merge( var.common_tags, tomap({"role":"terraform remote state"} ) )
}

# See https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa for the origin of some of this code.

resource "aws_s3_bucket" "terraform_state" {
  bucket = "state.terraform.${var.bucket_extension}"

  tags = merge(
    {"description" = "Used for Terraform remote state configuration. DO NOT DELETE this Bucket unless you know what you are doing."},
    local.common_tags,
  )
}

resource "aws_s3_bucket_acl" "acl_config" {
  bucket = aws_s3_bucket.terraform_state.id
  acl    = "private"
}
resource "aws_s3_bucket_versioning" "versioning_config" {
  # Enable versioning so we can see the full revision history of our
  # state files

  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_config" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backend" { # https://medium.com/dnx-labs/terraform-remote-states-in-s3-d74edd24a2c4
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "locks.state.terraform.${var.bucket_extension}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

# If a user has restricted permissions the following IAM permissions are required to use the remote state
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": "s3:ListBucket",
#       "Resource": "arn:aws:s3:::mybucket"
#     },
#     {
#       "Effect": "Allow",
#       "Action": ["s3:GetObject", "s3:PutObject"],
#       "Resource": "arn:aws:s3:::mybucket/path/to/my/key"
#     }
#   ]
# }