variable "onsite_private_subnet_cidr" {
  description = "The subnet CIDR Range of your onsite private subnet. This is also the subnet where your VPN client resides in. eg: 192.168.1.0/24"
  type        = string
}
variable "vpn_cidr" {
  description = "The CIDR range that the vpn will assign using DHCP.  These are virtual addresses for routing traffic."
  type        = string
}
variable "common_tags_vaultvpc" {
  description = "Common tags for resources in the vault vpc / firehawk-main project."
  type        = map(string)
}

variable "common_tags_rendervpc" {
  description = "Common tags for resources in the render vpc / firehawk-render-cluster project."
  type        = map(string)
}