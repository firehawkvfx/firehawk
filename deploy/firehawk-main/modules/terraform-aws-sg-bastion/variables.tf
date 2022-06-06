
variable "name" {
  description = "The name used to define resources in this module"
  type        = string
  default     = "bastion"
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy into. Leave an empty string to use the Default VPC in this region."
  type        = string
  default     = null
}

variable "common_tags" {
  description = "A map of common tags to assign to the resources created by this module"
  type        = map(string)
  default     = {}
}

variable "remote_cloud_public_ip_cidr" {
  description = "The remote cloud IP public address that will access the bastion (cloud 9)"
  type = string
}

variable "remote_cloud_private_ip_cidr" {
  description = "The remote cloud private IP address that will access the bastion (cloud 9)"
  type = string
}

variable "onsite_public_ip" {
  description = "The public ip address of your onsite location to enable access to security groups and openVPN."
  type = string
}

variable "bucket_extension_vault" {
    description = "The bucket extension where the terraform remote state resides"
    type = string
}