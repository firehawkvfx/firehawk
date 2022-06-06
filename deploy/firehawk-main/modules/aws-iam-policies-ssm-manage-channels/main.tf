terraform {
  required_version = ">= 0.13.5"
}

resource "aws_iam_role_policy" "ssm_manage_channels" {
  name   = var.name
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.ssm_manage_channels.json
}

data "aws_iam_policy_document" "ssm_manage_channels" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ssm:UpdateInstanceInformation"
    ]
    resources = ["*"]
  }
}
