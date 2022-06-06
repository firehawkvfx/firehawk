variable "name" {
    description = "The name for the policy"
    type = string
    default = "ProvisionerFirehawk"
}

variable "iam_role_id" {
    description = "The aws_iam_role role id to attach the policy to"
    type = string
}