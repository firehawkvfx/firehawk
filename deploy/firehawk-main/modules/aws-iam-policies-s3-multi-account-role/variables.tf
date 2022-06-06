variable "name" {
  description = "The name for this policy"
  default = "MultiAccountRolePolicyS3BucketAccess"
}
variable "iam_role_id" {
  description = "The Role ID to attach the policy to."
  type = string
}
variable "shared_bucket_arn" {
  description = "The shared bucket ARN the role will be allowed to access"
  type = string
}