variable "name" {
}

resource "aws_cloudformation_stack" "SoftNASRole" {
  name         = var.name
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
  template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-role.json"
}

output "softnas_role_id" {
  value = aws_cloudformation_stack.SoftNASRole.outputs["SoftnasRoleID"]
}

output "softnas_role_arn" {
  value = aws_cloudformation_stack.SoftNASRole.outputs["SoftnasARN"]
}

output "softnas_role_name" {
  value = aws_cloudformation_stack.SoftNASRole.outputs["SoftNasRoleName"]
}

