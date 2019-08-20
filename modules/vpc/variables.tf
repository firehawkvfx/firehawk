#vpc variables

variable "region" {
  default = "ap-southeast-2"
}

variable "sleep" {
  default = false
}

# NAT gateway allows outbound internet access for instances in the private subnets.  
# this will be required if running softnas updates and potentially the softnas license server.
variable "enable_nat_gateway" {
  default = true
}

variable "create_vpc" {
  default = true
}

variable "create_openvpn" {
  default = true
}

# #172.16.135.0/24 will be reserved for the remote subnet
# variable "private_remote_subnet" {
#   default = "172.16.135.0/24"
# }

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "azs" {
  default = []
}

variable "private_subnets" {
  default = []
}

variable "public_subnets" {
  default = []
}

# due to aws security group limits, we need a single range to encompass all private subnets for softnas security groups to not exceed the limit.
variable "all_private_subnets_cidr_range" {
}

#vpn variables

variable "remote_ip_cidr" {
}

variable "route_zone_id" {
}

variable "key_name" {
}

variable "private_key" {
}

variable "local_key_path" {
}

variable "cert_arn" {
}

variable "public_domain_name" {
}

variable "openvpn_user" {
}

variable "openvpn_user_pw" {
}

variable "openvpn_admin_user" {
}

variable "openvpn_admin_pw" {
}

variable "vpn_cidr" {
}

variable "bastion_ip" {
}