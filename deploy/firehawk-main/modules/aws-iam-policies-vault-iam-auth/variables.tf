variable "name" {
    description = "The name for the policy"
    type = string
    default = "VaultIAMAuth"
}

variable "iam_role_id" {
    description = "The aws_iam_role role id to attach the policy to"
    type = string
}

# variable "iam_role_name" {
#     description = "The aws_iam_role role name to attach the policy to"
#     type = string
# }

variable "share_with_arns" {
  description = "A list of other account ARN's to allow assume role to access the S3 bucket."
  type = list(string)
  default = []
}