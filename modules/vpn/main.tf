variable "vpc_id" {}

variable "vpc_cidr" {}

#example 10.0.0.0/16
variable "vpn_cidr" {}

# remote_vpn_ip_cidr is the ip address of the remote host / user intending to connect over vpn. eg '197.125.62.53/32'
variable "remote_vpn_ip_cidr" {}

# examples ["subnet-0a7554f56af4d6d0a", "subnet-0257c7f8b1d68b6e4"]
variable "public_subnet_ids" {
  default = []
}

variable "route_zone_id" {}

variable "key_name" {
  default = "my_key_pair"
}

#contents of the my_key_pair.pem file to connect to the vpn.
variable "private_key" {}

variable "ami" {
  default = "ami-7777b515"
}

variable "instance_type" {
  default = "m4.large"
}

variable "cert_arn" {}

# public domain name withou www
variable "public_domain_name" {}

variable "openvpn_admin_user" {}

variable "openvpn_user" {}

variable "openvpn_admin_pw" {}

variable "sleep" {
  default = false
}

module "openvpn" {
  #source = "github.com/firehawkvfx/tf_aws_openvpn"
  source = "../tf_aws_openvpn"
  name   = "openVPN"

  # VPC Inputs
  vpc_id             = "${var.vpc_id}"
  vpc_cidr           = "${var.vpc_cidr}"
  vpn_cidr           = "${var.vpn_cidr}"
  public_subnet_ids  = "${var.public_subnet_ids}"
  remote_vpn_ip_cidr = "${var.remote_vpn_ip_cidr}"

  # EC2 Inputs
  key_name = "${var.key_name}"

  private_key   = "${var.private_key}"
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"

  # ELB Inputs
  cert_arn = "${var.cert_arn}"

  # DNS Inputs
  domain_name   = "${var.public_domain_name}"
  route_zone_id = "${var.route_zone_id}"

  # OpenVPN Inputs
  openvpn_user       = "${var.openvpn_user}"
  openvpn_admin_user = "${var.openvpn_admin_user}" # Note: Don't choose "admin" username. Looks like it's already reserved.
  openvpn_admin_pw   = "${var.openvpn_admin_pw}"

  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep}"
}

output "private_ip" {
  value = "${module.openvpn.private_ip}"
}

output "public_ip" {
  value = "${module.openvpn.public_ip}"
}
