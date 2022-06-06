terraform {
  required_version = ">= 0.13.5"
}

resource "aws_iam_role_policy" "provisioner_firehawk" {
  name   = var.name
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.provisioner_firehawk.json
}

data "aws_iam_policy_document" "provisioner_firehawk" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RunInstances",
      "ec2:CreateSecurityGroup",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "cloudformation:CreateStack",
      "cloudformation:DescribeStacks",
      "cloudformation:DescribeStackEvents",
      "cloudformation:DescribeStackResources",
      "ec2:TerminateInstances",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      # Codedeploy Logs
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "cloudformation:DeleteStack"
    ]
    resources = ["arn:aws:cloudformation:*:*:stack/aws-cloud9-*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:security-group/*"
    ]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/Name"
      values   = ["aws-cloud9-*"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:ListInstanceProfiles",
      "iam:GetInstanceProfile"
    ]
    resources = [
      "arn:aws:iam::*:instance-profile/cloud9/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::*:role/service-role/AWSCloud9SSMAccessRole"
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}
