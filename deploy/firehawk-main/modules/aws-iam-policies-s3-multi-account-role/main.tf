# Attach a policy to a multi account role allowing read and write access to a specific S3 Bucket
terraform {
  required_version = ">= 0.13.5"
}
resource "aws_iam_role_policy" "multi_account_role" {
  name   = var.name
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.multi_account_policy_s3_bucket.json
}
data "aws_iam_policy_document" "multi_account_policy_s3_bucket" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [var.shared_bucket_arn]
  }
  statement {
    effect = "Allow"
    actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
    ]
    resources = ["${var.shared_bucket_arn}/*"]
  }
}

# If a user has restricted permissions the following IAM permissions are required to use the bucket
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
#       "Resource": "arn:aws:s3:::mybucket/path/to/something"
#     }
#   ]
# 