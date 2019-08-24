resource "aws_iam_user" "deadline_spot_user" {
  name = "deadline_spot_user"
}

resource "aws_iam_access_key" "deadline_spot_access_key" {
  user = "${aws_iam_user.deadline_spot_user.name}"
  pgp_key = var.pgp_key
  # see https://www.hiroom2.com/2016/08/14/ubuntu-16-04-create-gpg-key/ to create pgp key in ubuntu
}

output "spot_access_key_id" {
  value = "${aws_iam_access_key.deadline_spot_access_key.id}"
}

output "spot_secret" {
  value = "${aws_iam_access_key.deadline_spot_access_key.encrypted_secret}"
}

resource "aws_iam_user_policy" "deadline_spot_user_policy" {
  name = "deadline_spot_user_policy"
  user = "${aws_iam_user.deadline_spot_user.name}"

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