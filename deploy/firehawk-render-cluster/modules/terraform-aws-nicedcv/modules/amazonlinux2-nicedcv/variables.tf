variable "name" {
  description = "The name used to define resources in this module"
  type        = string
  default     = "workstation_amazonlinux2_nicedcv"
}
variable "workstation_amazonlinux2_nicedcv_ami_id" {
  description = "The prebuilt AMI for the vault client host. This should be a private ami you have built with packer."
  type        = string
}
variable "create_vpc" {
  description = "If used in a submodule, it is possible to selectively destroy resources by setting this to false."
  type        = bool
  default     = true
}
variable "vpc_id" {
  description = "The ID of the VPC to deploy into. Leave an empty string to use the Default VPC in this region."
  type        = string
  default     = null
}
# variable "vpc_cidr" {
#   description = "The CIDR block that contains all subnets within the VPC."
#   type        = string
# }

# variable "vpn_cidr" {
#   description = "The CIDR range that the vpn will assign using DHCP.  These are virtual addresses for routing traffic."
#   type        = string
# }

variable "common_tags" {
  description = "A map of common tags to assign to the resources created by this module"
  type        = map(string)
  default     = {}
}

# variable "common_tags_vaultvpc" {
#   description = "Common tags for resources in the vault vpc / firehawk-main project."
#   type        = map(string)
# }

# variable "common_tags_rendervpc" {
#   description = "Common tags for resources in the render vpc / firehawk-render-cluster project."
#   type        = map(string)
# }
variable "permitted_cidr_list" {
  description = "The list of CIDR blocks, (including public CIDR's) that will be able to access the host."
  type        = list(string)
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
variable "aws_key_name" {
  description = "The name of the AWS PEM key for access to the VPN instance"
  type        = string
  default     = null
}
variable "private_subnet_ids" {
  description = "The list of private subnets to deploy into.  Currently only the first subnet is used."
  type        = list(string)
}
variable "instance_type" {
  description = "The AWS instance type to use."
  type        = string
  default     = "t3.micro"
}
variable "node_skip_update" {
  description = "Skipping node updates is not recommended, but it is available to speed up deployment tests when diagnosing problems"
  type        = bool
  default     = false
}
variable "consul_cluster_name" {
  description = "What to name the Consul server cluster and all of its associated resources"
  type        = string
}
variable "consul_cluster_tag_key" {
  description = "The tag the Consul EC2 Instances will look for to automatically discover each other and form a cluster."
  type        = string
}
variable "aws_internal_domain" {
  description = "The domain used to resolve internal FQDN hostnames."
  type        = string
}
variable "bucket_extension_vault" {
    description = "The bucket extension where the terraform remote state resides"
    type = string
}
variable "bucket_extension" {
    description = "The bucket extension where the software installers reside"
    type = string
}

variable "deadline_version" {
  description = "The deadline version to install"
  type        = string
}