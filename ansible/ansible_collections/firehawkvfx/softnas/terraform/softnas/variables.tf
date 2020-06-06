variable "key_name" {
}

variable "common_tags" {}

variable "private_key" {
}

variable "vpn_private_ip" {
}

variable "vpc_id" {
}

variable "private_subnets" {
  default = []
}

variable "vpc_cidr" {
}

variable "private_subnets_cidr_blocks" {
  default = []
}

variable "public_subnets_cidr_blocks" {
  default = []
}

variable "firehawk_path" {}

variable "public_domain" {
}

variable "volumes" {
  default = []
}

variable "mounts" {
  default = []
}

variable "sleep" {
  default = false
}

variable "s3_disk_size" {
}

variable "bastion_private_ip" {
}

variable "bastion_ip" {
}

variable "skip_update" {
  default = false
}

variable "vpn_cidr" {
}

variable "remote_subnet_cidr" {
}

variable "remote_ip_cidr" {
}

variable "softnas_storage" {
}

variable "remote_mounts_on_local" {
}

variable "softnas_ssh_user" {
}

variable "softnas1_private_ip1" {
}

variable "softnas1_private_ip2" {
}

variable "softnas2_private_ip1" {
}

variable "softnas2_private_ip2" {
}

#softnas provides no ability to query the ami you will need by region.  it must be added to the map manually.
variable "instance_type" {
  type = map(string)

  default = {
    low  = "m4.xlarge"
    high = "m4.2xlarge"
  }
}

variable "softnas_mode" {
  default = "low"
}

variable "aws_region" {
}

variable "selected_ami" {
  type = map(string)

  default = {
    low_ap-southeast-2 = "ami-a24a98c0"
    # 4.2.4 enterprise consumption
    # high_ap-southeast-2 = "ami-05de939bacdc06d34"
    # 4.3.0 platinum consumption
    high_ap-southeast-2 = "ami-051ec062f31c60ee4"
  }
}

