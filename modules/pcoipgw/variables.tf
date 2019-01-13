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

variable "key_name" {
  default = "my_key_pair"
}

#contents of the my_key_pair.pem file to connect to the instance.
variable "private_key" {}

#this ami id is for southeast-ap-2 sydney only.  todo - changes will need to be made to pull a list of ami's
variable "ami" {
  default = "ami-0b292fed58bac1726"
}

variable "instance_type" {
  default = "g3.4xlarge"
}

variable "user" {
  default = "centos"
}
