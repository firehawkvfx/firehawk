### deadline spot instance IAM policy.  This allows instances launched by a spot fleet template to be recognised by deadline, and must be assigned when creating a spot fleet template.

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

resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  role       = aws_iam_role.spot_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy" "spot_instance_role_worker_policy" {
  name = "SlaveStatement"
  role = aws_iam_role.spot_instance_role.id

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

# to limit access to a specific bucket, see here - https://aws.amazon.com/blogs/security/writing-iam-policies-how-to-grant-access-to-an-amazon-s3-bucket/
resource "aws_iam_role_policy" "spot_instance_role_s3_policy" {
  name = "S3ReadWrite"
  role = aws_iam_role.spot_instance_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::*"]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "spot_instance_role_describe_policy" {
  name = "DescribeInstances"
  role = aws_iam_role.spot_instance_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "spot_instance_profile" {
  name = aws_iam_role.spot_instance_role.name
  role = aws_iam_role.spot_instance_role.name
}

output "spot_instance_profile_arn" {
  value = aws_iam_instance_profile.spot_instance_profile.arn
}
output "spot_instance_profile_name" {
  value = aws_iam_instance_profile.spot_instance_profile.name
}

### deadline spot fleet user IAM


resource "aws_iam_user_group_membership" "deadline_spot_group_membership" {
  user = aws_iam_user.deadline_spot_deployment_user.name

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
  group = aws_iam_group.deadline_spot_group.id

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
            "Resource": "*"
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
            "Resource": "*"
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
            ]
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
            "Resource": "*"
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
            "Resource": "*"
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
            "Resource": "*"
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
            "Resource": "*"
        },
        {
            "Sid": "S3Permissions",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "*"
            ]
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
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_user" "deadline_spot_deployment_user" {
  name = "deadline_spot_deployment_user"
  force_destroy = true
}

resource "aws_iam_access_key" "deadline_spot_access_key" {
  user    = aws_iam_user.deadline_spot_deployment_user.name
  pgp_key = var.keybase_pgp_key
  # pgp key: normally in format 'keybase:my_username'
  # see https://www.hiroom2.com/2016/08/14/ubuntu-16-04-create-gpg-key/ to create pgp key in ubuntu
}

output "spot_access_key_id" {
  value = aws_iam_access_key.deadline_spot_access_key.id
}

output "spot_secret" {
  value = aws_iam_access_key.deadline_spot_access_key.encrypted_secret
}