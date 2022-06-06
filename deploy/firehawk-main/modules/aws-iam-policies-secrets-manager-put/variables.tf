variable "name" {
  description = "The name for the policy"
  type        = string
}
variable "iam_role_id" {
  description = "The aws_iam_role role id to attach the policy to"
  type        = string
}
variable "resourcetier" {
  description = "The resource tier uniquely defining the deployment area.  eg: dev/green/blue/main"
  type        = string
}
variable "kms_arn" {
  description = "The KMS ARN required for the secret"
  type        = string
}
variable "secret_arn" {
  description = "The secrets manager ARN."
  type        = string
}