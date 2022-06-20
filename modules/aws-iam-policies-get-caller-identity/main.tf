terraform {
  required_version = ">= 0.13.5"
}

resource "aws_iam_role_policy" "get_caller_identity" {
  name = var.name
  role = var.iam_role_id
  policy = data.aws_iam_policy_document.get_caller_identity.json
}

data "aws_iam_policy_document" "get_caller_identity" {
  statement {
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}