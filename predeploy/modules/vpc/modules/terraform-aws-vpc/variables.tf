#vpc variables

variable "create_vpc" {
  description = "Defines if the VPC should be created.  Setting this to false when the VPC exists will destroy the VPC."
  type        = bool
  default     = true
}

variable "sleep" {
  description = "Sleep will disable the nat gateway and shutdown instances to save cost during idle time."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "NAT gateway allows outbound internet access for instances in the private subnets."
  type        = bool
  default     = true
}

variable "private_subnets" {
  description = "The list of private subnet CIDR blocks to place private instances within."
  type        = list(string)
}

variable "public_subnets" {
  description = "The list of public subnet CIDR blocks to place public facing instances within."
  type        = list(string)
}

variable "vpc_cidr" {
  description = "The CIDR block that contains all subnets within the VPC."
  type        = string
}

# variable "remote_cloud_private_ip_cidr" {
#   description = "The remote private address that will connect to the bastion instance and other public instances.  This is used to limit inbound access to public facing hosts like the VPN from your site's public IP."
#   type        = string
#   default     = null
# }

# variable "remote_cloud_public_ip_cidr" {
#   description = "The remote public address that will connect to the bastion instance and other public instances.  This is used to limit inbound access to public facing hosts like the VPN from your site's public IP."
#   type        = string
#   default     = null
# }

variable "vpc_name" {
  description = "The name to associate with the VPC"
  type        = string
}

variable "common_tags" {
  description = "A map of common tags to assign to the resources created by this module"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "The AWS Region to create all resources in for this module."
  type        = string
  default     = null
}

# variable "instance_type" {
#   description = "The instance type to use for the VPN"
#   type        = string
#   default     = "t3.micro"
# }
