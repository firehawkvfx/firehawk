variable "gateway_name" {
  description = "The friendly name to assign to the storage gateway"
}
variable "permitted_cidr_list_private" {
  description = "The list of CIDR blocks to allow acces to Filegateway"
  type        = list(string)
  default     = []
}
variable "permitted_cidr_list_provisioner" {
  description = "The list of CIDR blocks to allow acces to Filegateway"
  type        = list(string)
  default     = []
}
variable "vpc_id" {
  description = "The ID of the VPC to deploy into. Leave an empty string to use the Default VPC in this region."
  type        = string
  default     = null
}