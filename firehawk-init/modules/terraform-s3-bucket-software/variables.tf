variable "share_with_arns" {
  description = "A list of other account ARN's to allow assume role to access the S3 bucket."
  type = list(string)
  default = []
}

# variable "use_vault" {
#   description = "If true, will aquire the bucket name from vault"
#   type = bool
#   default = true
# }

# variable "bucket_name" {
#   description = "The name of the s3 bucket to create if not using a vault path."
#   type = string
#   default = ""
# }

variable "installers_bucket" {
  description = "The S3 Bucket to persist installation and software to"
  type = string
}

# variable "bucket_extension" {
#   description = "The extension for cloud storage used to label your S3 storage buckets (eg: example.com, my-name-at-gmail.com). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html"
#   type = string
# }

# variable "bucket_prefix" {
#   description = "The prefix for the bucket name"
#   type = string
#   default = "software"
# }

variable "role_name" {
  description = "Name of the role that multiple accounts can assume for access to the bucket."
  type = string
  default = "multi_account_role"
}
variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}
variable "conflictkey" {
    description = "The conflictkey is a unique name for each deployement usuallly consisting of the resourcetier and the pipeid."
    type = string
}