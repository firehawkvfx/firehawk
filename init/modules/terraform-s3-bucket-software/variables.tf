variable "share_with_arns" {
  description = "A list of other account ARN's to allow assume role to access the S3 bucket."
  type        = list(string)
  default     = []
}
variable "bucketlogs_bucket" {
  description = "The bucket to store logs in"
  type        = string
}
variable "installers_bucket" {
  description = "The S3 Bucket to persist installation and software to"
  type        = string
}
variable "role_name" {
  description = "Name of the role that multiple accounts can assume for access to the bucket."
  type        = string
  default     = "multi_account_role_s3_software"
}
variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}
variable "conflictkey" {
  description = "The conflictkey is a unique name for each deployement usuallly consisting of the resourcetier and the pipeid."
  type        = string
}

variable "firehawk_path" {
  description = "The full path to firehawk-main"
  type        = string
}
