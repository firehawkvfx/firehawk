### This role and profile allows Deadline Resource Tracker to monitor resources created by Deadline.  Only one per account is possble, so it is created during init. 
resource "aws_iam_role" "instance_role" {
  name = "DeadlineResourceTrackerAccessRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = merge( var.common_tags, map( "role", "deadline") )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSThinkboxDeadlineResourceTrackerAccessPolicy"
  ]
}
data "aws_iam_policy_document" "assume_role" { # Determines the services able to assume the role.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}