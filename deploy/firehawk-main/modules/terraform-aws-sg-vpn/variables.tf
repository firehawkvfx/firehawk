
variable "name" {
  description = "The name used to define resources in this module"
  type        = string
  default     = "bastion"
}
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
variable "onsite_private_subnet_cidr" {
  description = "The subnet CIDR Range of your onsite private subnet. This is also the subnet where your VPN client resides in. eg: 192.168.1.0/24"
  type        = string
}
variable "bucket_extension" {
  description = "The extension for cloud storage used to label your S3 storage buckets (eg: example.com, my-name-at-gmail.com). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html"
  type        = string
}
