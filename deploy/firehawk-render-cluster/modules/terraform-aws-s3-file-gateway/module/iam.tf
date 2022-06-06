# This module originated from https://github.com/davebuildscloud/terraform_file_gateway/blob/master/terraform

data "aws_iam_policy_document" "policy_document" {
  statement {
    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [
      var.aws_s3_bucket_arn
    ]

    effect = "Allow"
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]

    resources = [
      "${var.aws_s3_bucket_arn}/*",
    ]

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "storagegateway.amazonaws.com",
      ]

      type = "Service"
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource "aws_iam_role" "role" {
  name               = "${var.application}-${var.resourcetier}-${var.role}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
  description        = "IAM role for file gateway"
}

resource "aws_iam_policy" "iam_policy" {
  name   = "${var.application}-${var.resourcetier}-${var.role}-bucket-access"
  policy = data.aws_iam_policy_document.policy_document.json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.role.id
  policy_arn = aws_iam_policy.iam_policy.arn
}