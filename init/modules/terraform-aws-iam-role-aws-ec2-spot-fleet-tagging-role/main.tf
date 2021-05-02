## This role allows spot fleets started by deadline to have tags assigned to instances.  Only one per account is possble, so it is created during init. 
resource "aws_iam_role" "service_role" {
  name = "aws-ec2-spot-fleet-tagging-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = merge( var.common_tags, map( "role", "deadline") )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
  ]
}
data "aws_iam_policy_document" "assume_role" { # Determines the services able to assume the role.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }
  }
}