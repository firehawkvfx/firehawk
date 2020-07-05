variable "aws_key_name" {
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

variable "init_aws_local_workstation" {}

variable "softnas_instance_type" {
  default = "m4.xlarge"
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

variable "softnas_volatile" {}

variable "envtier" {}