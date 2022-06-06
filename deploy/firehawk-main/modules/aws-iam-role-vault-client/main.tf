# A generic profile and role for an EC2 instance to access vault credentials to be used on something like a packer build instance or other host needing implicit access to vault.
# This module can be called multiple time to create roles with different names and different vault priveledges but the policies contained within should not be altered.  They are the minimum required set of policies.
# To give a role more permission, you should instead refer to the example firehawk-main/modules/terraform-aws-iam-profile-provisioner and reduce its permissions for your use case accordingly.
resource "aws_iam_role" "vault_client_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.vault_client_assume_role.json
  tags               = var.common_tags
}
resource "aws_iam_instance_profile" "vault_client_profile" {
  path = "/"
  role = aws_iam_role.vault_client_role.name
}
data "aws_iam_policy_document" "vault_client_assume_role" {
  # Determines the services able to assume the role.  Any entity assuming this role will be able to authenticate to vault.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
# Adds policies necessary for running consul
module "consul_iam_policies_for_client" {
  source      = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.8.0"
  iam_role_id = aws_iam_role.vault_client_role.id
}
