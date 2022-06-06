variable "common_tags" {
  description = "A map of common tags to assign to the resources created by this module"
  type        = map(string)
  default     = {}
}
variable "onsite_public_ip" {
  description = "The public ip address of your onsite location to enable access to security groups and openVPN."
  type        = string
}
variable "combined_vpcs_cidr" {
  description = "Terraform will automatically configure multiple VPCs and subnets within this CIDR range for any resourcetier ( dev / green / blue / main )."
  type        = string
}
variable "vpn_cidr" {
  description = "The CIDR range that the vpn will assign using DHCP.  These are virtual addresses for routing traffic."
  type        = string
}
variable "vpc_id" {
  description = "The ID of the VPC to deploy into. Leave an empty string to use the Default VPC in this region."
  type        = string
  default     = null
}
variable "onsite_private_subnet_cidr" {
  description = "The subnet CIDR Range of your onsite private subnet. This is also the subnet where your VPN client resides in. eg: 192.168.1.0/24"
  type        = string
}
variable "permitted_cidr_list_private" {
  description = "The list of private CIDR blocks that will be able to access the host."
  type        = list(string)
}
variable "security_group_ids" {
  description = "The list of security group ID's that have SSH access to the node"
  type        = list(string)
  default     = null
}
variable "permitted_cidr_list" {
  description = "The list of CIDR blocks, (including public CIDR's) that will be able to access the host."
  type        = list(string)
}