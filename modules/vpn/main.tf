variable "vpc_id" {
  default = "vpc-01b4c015c07050a71"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpn_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_ids" {
  default = ["subnet-0a7554f56af4d6d0a", "subnet-0257c7f8b1d68b6e4"]
}

variable "route_zone_id" {}

variable "key_name" {
  default = "my_key_pair"
}

variable "private_key" {}

variable "ami" {
  default = "ami-7777b515"
}

variable "instance_type" {
  default = "m4.large"
}

variable "cert_arn" {}

variable "public_domain_name" {
  default = "www.firehawkvfx.com"
}

variable "openvpn_admin_user" {
  default = "StackAdmin"
}

variable "openvpn_user" {
  default = "openvpnuser"
}

variable "openvpn_admin_pw" {
  default = "ChangeThisPassword99Times"
}

module "openvpn" {
  source = "github.com/terraform-community-modules/tf_aws_openvpn"
  name   = "openVPN"

  # VPC Inputs
  vpc_id            = "${var.vpc_id}"
  vpc_cidr          = "${var.vpc_cidr}"
  vpn_cidr          = "${var.vpn_cidr}"
  public_subnet_ids = "${var.public_subnet_ids}"

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
}
