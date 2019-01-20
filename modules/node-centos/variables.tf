variable "name" {
  default = "pcoipgw"
}

variable "vpc_id" {}

#example "10.0.0.0/16"
variable "vpc_cidr" {}

# remote_ip_cidr is the ip address of the remote host / user intending to connect over vpn. eg '197.125.62.53/32'
#example "125.254.24.255/32"
variable "remote_ip_cidr" {}

# examples ["subnet-0a7554f56af4d6d0a", "subnet-0257c7f8b1d68b6e4"]
variable "public_subnet_ids" {
  default = []
}

variable "private_subnet_ids" {
  default = []
}

variable "key_name" {
  default = "my_key_pair"
}

#contents of the my_key_pair.pem file to connect to the instance.
variable "private_key" {}

#CentOS Linux 7 x86_64 HVM EBS ENA 1805_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-77ec9308.4 (ami-d8c21dba)
variable "ami_map" {
  type = "map"

  default = {
    ap-southeast-2 = "ami-d8c21dba"
  }
}

variable "instance_type" {
  default = "t2.micro"
}

variable "user" {
  default = "centos"
}

variable "sleep" {
  default = false
}

variable "skip_update" {
  default = true
}

variable "vpn_cidr" {}

variable "region" {}
