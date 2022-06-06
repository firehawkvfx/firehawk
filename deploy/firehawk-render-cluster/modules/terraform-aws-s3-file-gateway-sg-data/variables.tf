variable "bucket_extension" {
  description = "The bucket extension where the software installers reside"
  type        = string
}
variable "s3_bucket_name" {
  description = "The bucket name for the endpoint."
  type        = string
}
variable "resourcetier" {
  description = "The resource tier speicifies a unique name for a resource based on the environment.  eg:  dev, green, blue, main."
  type        = string
}