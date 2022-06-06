variable "init" {
  description = "If true, will only ensure paths exist."
  type        = bool
  default     = false
}
variable "restore_defaults" {
  description = "If true, will reset all values to system defaults"
  type        = bool
  default     = false
}
variable "global_bucket_extension" {
  description = "The extension for cloud storage used to label your S3 storage buckets (eg: example.com, my-name-at-gmail.com). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. the global name will be used to create buckets in different environments.  a global bucket extension of example.com will result these buckets being created: dev.example.com, green.example.com, blue.example.com, main.example.com. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html"
  type = string
}
variable "resourcetier" {
  description = "The resource tier uniquely defining the deployment area.  eg: dev/green/blue/main"
  type        = string
}