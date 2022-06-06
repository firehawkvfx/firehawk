# Attach a policy to a bucket allowing access to a multi account role
terraform {
  required_version = ">= 0.13.5"
}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "shared_bucket_policy" {
  bucket = var.bucket_id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "s3MultiAccountSharePolicy",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${var.bucket_arn}",
        "${var.bucket_arn}/*"
      ],
      "Principal": {
        "AWS": [
          "${data.aws_caller_identity.current.account_id}"
        ]
      }
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${var.bucket_arn}",
        "${var.bucket_arn}/*"
      ],
      "Principal": {
        "AWS": [
          "${var.multi_account_role_arn}"
        ]
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${var.multi_account_role_arn}"
        ]
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "${var.bucket_arn}/*"
      ],
      "Condition": {
          "StringEquals": {
              "s3:x-amz-acl": "bucket-owner-full-control"
          }
      }
    }
  ]
}
POLICY
}