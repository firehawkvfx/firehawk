variable "bucket_arn" {
  description = "The bucket ARN to apply the policy to."
  type = string
}
variable "bucket_id" {
  description = "The bucket ID to apply the policy to."
  type = string
}
variable "multi_account_role_arn" {
  description = "The multi account role ARN that is able to be assumed for access to the bucket."
  type = string
}