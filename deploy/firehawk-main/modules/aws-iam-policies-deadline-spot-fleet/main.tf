terraform {
  required_version = ">= 0.13.5"
}

resource "aws_iam_role_policy" "launch_spot_fleet" {
  name   = var.name
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.launch_spot_fleet.json
}

data "aws_iam_policy_document" "launch_spot_fleet" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateTags",
      "ec2:RequestSpotFleet",
      "ec2:ModifySpotFleetRequest",
      "ec2:CancelSpotFleetRequests",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeSpotFleetInstances",
      "ec2:DescribeSpotFleetRequestHistory"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["arn:aws:iam::*:role/aws-ec2-spot-fleet-tagging-role"]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:ListRoles",
      "iam:ListInstanceProfiles"
    ]
    resources = ["*"]
  }
}