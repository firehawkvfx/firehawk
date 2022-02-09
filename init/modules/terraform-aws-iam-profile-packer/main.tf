### This role and profile allows instances access to S3 buckets to aquire and push back downloaded softwre to provision with.  It also has prerequisites for consul and vault access.
resource "aws_iam_role" "instance_role" {
  name = var.packer_iam_profile_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = merge( var.common_tags, map( "role", "packer") )
}
resource "aws_iam_instance_profile" "instance_profile" {
  name = aws_iam_role.instance_role.name
  role = aws_iam_role.instance_role.name
}
data "aws_iam_policy_document" "assume_role" { # Determines the services able to assume the role.  Any entity assuming this role will be able to authenticate to vault.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
# Policy Allowing Read and write access to S3
module "iam_policies_s3_read_write" {
  source = "github.com/firehawkvfx/firehawk-main.git//modules/aws-iam-policies-s3-read-write?ref=v0.0.27"
  name = "S3ReadWrite_${var.conflictkey}"
  iam_role_id = aws_iam_role.instance_role.id
}
# # Policy to query the identity of the current role.  Required for Vault.
# module "iam_policies_get_caller_identity" {
#   source = "../../modules/aws-iam-policies-get-caller-identity"
#   name = "STSGetCallerIdentity_${var.conflictkey}"
#   iam_role_id = aws_iam_role.instance_role.id
# }
# # Adds policies necessary for running Consul
# module "consul_iam_policies_for_client" {
#   source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.7.7"

#   iam_role_id = aws_iam_role.instance_role.id
# }
