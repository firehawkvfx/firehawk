variable "key_name" {}
variable "private_key" {}

variable "vpn_private_ip" {}

variable "vpc_id" {}

variable "private_subnets" {
  default = []
}

variable "all_private_subnets_cidr_range" {}

variable "private_subnets_cidr_blocks" {
  default = []
}

variable "public_subnets_cidr_blocks" {
  default = []
}



variable "public_domain" {}

variable "volumes" {
  default = []
}

variable "mounts" {
  default = []
}

variable "sleep" {
  default = false
}

variable "s3_disk_size" {}

variable "bastion_private_ip" {}

variable "bastion_ip" {}

variable "skip_update" {
  default = false
}

variable "vpn_cidr" {}
variable "remote_subnet_cidr" {}

variable "remote_ip_cidr" {}


variable "softnas_role_name" {
  default = "SoftNAS_HA_IAM"
}

variable "cloudformation_stack_name" {}
variable "cloudformation_role_stack_name" {}

variable "softnas1_private_ip1" {}

variable "softnas1_private_ip2" {}

variable "softnas2_private_ip1" {}

variable "softnas2_private_ip2" {}

#softnas provides no ability to query the ami you will need by region.  it must be added to the map manually.
variable "instance_type" {
  type = "map"

  default = {
    low = "m4.xlarge",
    high = "r5.xlarge"
  }
}

variable "softnas_mode" {
  default="low"
}

variable "aws_region" {}

variable "selected_ami" {
  type = "map"

  default = {
    low_ap-southeast-2 = "ami-a24a98c0",
    #high_ap-southeast-2 = "ami-5e7ea03c"
    high_ap-southeast-2 = "ami-058203bb6a3250775"
  }
}