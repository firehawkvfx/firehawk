# Attach a policy to a bucket allowing access to a multi account role
terraform {
  required_version = ">= 0.13.5"
}
data "aws_caller_identity" "current" {}
data "aws_s3_bucket" "license_forwarder_cert_bucket" {
  bucket = var.bucket_name
}
resource "aws_s3_bucket_policy" "license_forwarder_cert_bucket_policy" {
  bucket = data.aws_s3_bucket.license_forwarder_cert_bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "s3MultiAccountLicenseForwarderSharePolicy",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${data.aws_s3_bucket.license_forwarder_cert_bucket.arn}",
        "${data.aws_s3_bucket.license_forwarder_cert_bucket.arn}/*"
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
        "${data.aws_s3_bucket.license_forwarder_cert_bucket.arn}",
        "${data.aws_s3_bucket.license_forwarder_cert_bucket.arn}/*"
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
        "${data.aws_s3_bucket.license_forwarder_cert_bucket.arn}/*"
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