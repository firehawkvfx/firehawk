variable "fsx_storage_enabled" {
  description = "Bool enabling FSX storage"
  type        = bool
  default     = true
}
variable "fsx_storage_capacity" {
  description = "Storage capacity (default in GB)"
  type        = string
  default     = "1200"
}
variable "rendering_bucket" {
  description = "The path to the S3 Bucket for the FSX backend"
  type        = string
}
variable "subnet_ids" {
  description = "The list of subnet ID's for FSX endpoints."
  type        = list(string)
  default     = []
}
variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}
variable "vpc_id" {
  description = "The ID of the VPC to deploy into. Leave an empty string to use the Default VPC in this region."
  type        = string
  default     = null
}
variable "sleep" {
  description = "Sleep if true may temporarily be used to destroy some resources to reduce idle costs."
  type        = bool
  default     = false
}
variable "permitted_cidr_list_private" {
  description = "The list of CIDR blocks to allow acces to FSX"
  type        = list(string)
  default     = []
}
variable "fsx_record_enabled" {
  description = "Whether to add a DNS record using Route 53"
  type        = bool
  default     = false
}
variable "private_route53_zone_id" {
  default = null
}
variable "fsx_hostname" {
  default = "fsx"
}