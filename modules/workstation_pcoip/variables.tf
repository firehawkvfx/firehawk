variable "name" {
}

variable "common_tags" {}

variable "vpc_id" {
}

variable "vpc_cidr" {
}

# remote_ip_cidr is the ip address of the remote host / user intending to connect over vpn. eg '197.125.62.53/32'
variable "remote_ip_cidr" {
}

variable "vpn_cidr" {
}

variable "public_subnet_ids" {
  default = []
}

variable "private_subnet_ids" {
  default = []
}

variable "aws_key_name" {
}

variable "workstation_enabled" {
}

#contents of the my_key.pem file to connect to the instance.
variable "private_key" {
}

#this ami id is for southeast-ap-2 sydney only.  todo - changes will need to be made to pull a list of ami's

#options for gateway type are centos7 and pcoip
variable "gateway_type" {
  default = "pcoip"
}

variable "aws_nodes_enabled" {
  default = false
}

variable "instance_type_map" {
  type = map(string)

  default = {
    pcoip   = "g4dn.xlarge"
    centos7 = "t2.micro"
  }
}

variable "instance_type" {
  default = "g4dn.xlarge"
}

variable "user" {
  default = "centos"
}

variable "sleep" {
  default = false
}

variable "skip_update" {
  default = false
}

variable "bastion_ip" {
}

variable "pcoip_sleep_after_creation" {
  default = false
}

variable "instance_profile_name" {}

variable "install_houdini" {}

variable "install_deadline_worker" {}

variable "vpn_private_ip" {}