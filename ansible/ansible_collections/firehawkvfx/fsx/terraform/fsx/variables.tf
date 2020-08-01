variable "bucket_extension" {}

variable "fsx_storage" {
}

variable "subnet_ids" {
    default = []
}

variable "common_tags" {}

variable "vpc_id" {}

variable "vpn_cidr" {}

variable "private_subnets_cidr_blocks" {
    # default = []
}

variable "vpc_cidr" {}

variable "public_subnets_cidr_blocks" {
    # default = []
}

variable "remote_subnet_cidr" {}

variable "remote_ip_cidr" {}