terraform {
  required_version = ">= 0.13.5"
}
resource "aws_iam_role_policy" "policy" {
  name   = var.name
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.policy_doc.json
}
data "aws_iam_policy_document" "policy_doc" {
  statement { # see https://medium.com/avmconsulting-blog/best-practice-rules-for-aws-secrets-manager-97caaff6cea5
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]
    resources = [var.kms_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [var.secret_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
  }
}