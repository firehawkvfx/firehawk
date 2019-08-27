### deadline spot instance IAM policy.  This allows instances launched by a spot fleet template to be recognised by deadline, and must be assigned when creating a spot fleet template.

resource "aws_iam_policy" "spot_instance_policy" {
  name        = "spot_instance_policy"
  path        = "/"
  description = "spot_instance_policy for Deadline"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SlaveStatement",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ec2:TerminateInstances"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SQSReporting",
            "Effect": "Allow",
            "Action": [
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "sqs:ReceiveMessage",
                "sqs:SendMessage"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "spot_instance_role" {
  name = "spot_instance_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "spot_instance_role_policy" {
  name = "SlaveStatement"
  role = "${aws_iam_role.spot_instance_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SlaveStatement",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ec2:TerminateInstances"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SQSReporting",
            "Effect": "Allow",
            "Action": [
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "sqs:ReceiveMessage",
                "sqs:SendMessage"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "spot_instance_profile" {
  name = "SlaveStatement"
  role = "${aws_iam_role.spot_instance_role.name}"
}

output "spot_instance_profile_arn" {
  value = "${aws_iam_instance_profile.spot_instance_profile.arn}"
}

### deadline spot fleet user IAM


resource "aws_iam_user_group_membership" "deadline_spot_group_membership" {
  user = "${aws_iam_user.deadline_spot_user.name}"

  groups = [
    "${aws_iam_group.deadline_spot_group.name}"
  ]
}

resource "aws_iam_group" "deadline_spot_group" {
  name = "deadline_spot_group"
  path = "/users/"
}

resource "aws_iam_group_policy" "deadline_spot_group_policy" {
  name  = "deadline_spot_group_policy"
  group = "${aws_iam_group.deadline_spot_group.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "HouseCleaningStatement",
            "Effect": "Allow",
            "Action": [
                "ec2:ModifySpotFleetRequest",
                "ec2:CancelSpotFleetRequests",
                "ec2:RequestSpotFleet",
                "ec2:DescribeSpotFleetRequests",
                "ec2:DescribeSpotFleetInstances"
            ],
            "Resource": "*",
            "Condition": {
                "IpAddress" : {
                    "aws:SourceIp" : ["${var.remote_ip_cidr}"]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
                "iam:PassRole",
                "iam:ListInstanceProfiles",
                "iam:GetRole",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PutRolePolicy",
                "iam:DetachRolePolicy",
                "iam:DeleteRole",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy",
                "iam:GetUser"
            ],
            "Resource": "*",
            "Condition": {
                "IpAddress" : {
                    "aws:SourceIp" : ["${var.remote_ip_cidr}"]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "arn:aws:iam::*:role/aws-service-role/*"
        },
        {
            "Sid": "CloudFormationPermissions",
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:ListStacks",
                "cloudformation:UpdateTerminationProtection"
            ],
            "Resource": [
                "*"
            ],
            "Condition": {
                "IpAddress" : {
                    "aws:SourceIp" : ["${var.remote_ip_cidr}"]
                }
            }
        },
        {
            "Sid": "DynamoDBPermissions",
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DescribeTable",
                "dynamodb:DeleteTable",
                "dynamodb:TagResource",
                "dynamodb:UntagResource",
                "dynamodb:BatchWriteItem",
                "dynamodb:ListTagsOfResource",
                "dynamodb:Scan"
            ],
            "Resource": "*",
            "Condition": {
                "IpAddress" : {
                    "aws:SourceIp" : ["${var.remote_ip_cidr}"]
                }
            }
        },
        {
            "Sid": "SQSPermissions",
            "Effect": "Allow",
            "Action": [
                "sqs:CreateQueue",
                "sqs:GetQueueAttributes",
                "sqs:DeleteQueue",
                "sqs:ListQueueTags",
                "sqs:UntagQueue",
                "sqs:TagQueue"
            ],
            "Resource": "*",
            "Condition": {
                "IpAddress" : {
                    "aws:SourceIp" : ["${var.remote_ip_cidr}"]
                }
            }
        },
        {
            "Sid": "LambdaPermissions",
            "Effect": "Allow",
            "Action": [
                "lambda:GetFunction",
                "lambda:CreateFunction",
                "lambda:DeleteFunction",
                "lambda:GetFunctionConfiguration",
                "lambda:CreateEventSourceMapping",
                "lambda:GetEventSourceMapping",
                "lambda:DeleteEventSourceMapping",
                "lambda:AddPermission"
            ],
            "Resource": "*",
            "Condition": {
                "IpAddress" : {
                    "aws:SourceIp" : ["${var.remote_ip_cidr}"]
                }
            }
        },
        {
            "Sid": "EventPermissions",
            "Effect": "Allow",
            "Action": [
                "events:PutRule",
                "events:DescribeRule",
                "events:RemoveTargets",
                "events:DeleteRule",
                "events:PutTargets"
            ],
            "Resource": "*",
            "Condition": {
                "IpAddress" : {
                    "aws:SourceIp" : ["${var.remote_ip_cidr}"]
                }
            }
        },
        {
            "Sid": "S3Permissions",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "*"
            ],
            "Condition": {
                "IpAddress" : {
                    "aws:SourceIp" : ["${var.remote_ip_cidr}"]
                }
            }
        },
        {
            "Sid": "AutoScalingPermissions",
            "Effect": "Allow",
            "Action": [
                "application-autoscaling:DescribeScalableTargets",
                "application-autoscaling:RegisterScalableTarget",
                "application-autoscaling:DeregisterScalableTarget",
                "application-autoscaling:DescribeScalingPolicies",
                "application-autoscaling:PutScalingPolicy",
                "application-autoscaling:DeleteScalingPolicy"
            ],
            "Resource": "*",
            "Condition": {
                "IpAddress" : {
                    "aws:SourceIp" : ["${var.remote_ip_cidr}"]
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_user" "deadline_spot_user" {
  name = "deadline_spot_user"
}

resource "aws_iam_access_key" "deadline_spot_access_key" {
  user = "${aws_iam_user.deadline_spot_user.name}"
  pgp_key = "keybase:andrew_graham"
  #var.pgp_key
  # see https://www.hiroom2.com/2016/08/14/ubuntu-16-04-create-gpg-key/ to create pgp key in ubuntu
}

output "spot_access_key_id" {
  value = "${aws_iam_access_key.deadline_spot_access_key.id}"
}

output "spot_secret" {
  value = "${aws_iam_access_key.deadline_spot_access_key.encrypted_secret}"
}