variable "name" {
    description = "The name for the policy"
    type = string
    default = "S3ReadWrite"
}

variable "iam_role_id" {
    description = "The aws_iam_role role id to attach the policy to"
    type = string
}