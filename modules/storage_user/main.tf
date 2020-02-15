### storage user IAM provides permission to read and write to s3 buckets.


resource "aws_iam_user_group_membership" "s3_group_membership" {
  user = aws_iam_user.storage_user.name

  groups = [
    "${aws_iam_group.s3_admin_group.name}",
    "${aws_iam_group.query_instances_group.name}"
  ]
}

resource "aws_iam_group" "query_instances_group" {
  name = "query_instances_group"
  path = "/users/"
}

resource "aws_iam_group_policy" "query_instances_group_policy" {
  name  = "query_instances_group_policy"
  group = aws_iam_group.query_instances_group.id

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

resource "aws_iam_group" "s3_admin_group" {
  name = "s3_admin_group"
  path = "/users/"
}

resource "aws_iam_group_policy" "s3_admin_group_policy" {
  name  = "s3_admin_group_policy"
  group = aws_iam_group.s3_admin_group.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user" "storage_user" {
  name = "storage_user"
  force_destroy = true
}

resource "aws_iam_access_key" "storage_user_access_key" {
  user    = aws_iam_user.storage_user.name
  pgp_key = var.pgp_public_key
  # pgp key: normally in format 'keybase:my_username'
  # See https://www.hiroom2.com/2016/08/14/ubuntu-16-04-create-gpg-key/ to create pgp key in ubuntu
  # Also execllent documentation on pgp / gpg as an alternative to keybase http://zanussi.combell.org/bash_gpg_encrypt_decrypt.html
}

output "storage_user_access_key_id" {
  value = aws_iam_access_key.storage_user_access_key.id
}

output "storage_user_secret" {
  value = aws_iam_access_key.storage_user_access_key.encrypted_secret
}