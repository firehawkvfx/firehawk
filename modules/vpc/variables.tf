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
  default = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "private_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

#vpn variables

variable "remote_ip_cidr" {}

variable "route_zone_id" {}

variable "key_name" {}

variable "private_key" {}

variable "local_key_path" {}

variable "cert_arn" {}

variable "public_domain_name" {}

variable "openvpn_user" {}
variable "openvpn_user_pw" {}

variable "openvpn_admin_user" {}

variable "openvpn_admin_pw" {}

variable "vpn_cidr" {}
