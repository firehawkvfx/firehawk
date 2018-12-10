provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  #  access_key = "${var.aws_access_key}"
  #  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

module "vpc" {
  source = "./modules/vpc"
}

module "vpn" {
  source = "./modules/vpn"

  vpc_id             = "${module.vpc.vpc_id}"
  vpc_cidr           = "${module.vpc.vpc_cidr_block}"
  vpn_cidr           = "${module.vpc.vpc_cidr_block}"
  remote_vpn_ip_cidr = "${var.remote_vpn_ip_cidr}"
  public_subnet_ids  = "${module.vpc.public_subnets}"

  #provided route 53 zone id will be modified to have a subdomain to access vpn
  route_zone_id      = "${var.route_zone_id}"
  key_name           = "${var.key_name}"
  private_key        = "${file("${var.local_key_path}")}"
  cert_arn           = "${var.cert_arn}"
  public_domain_name = "${var.public_domain_name}"
  openvpn_user       = "${var.openvpn_user}"
  openvpn_admin_user = "${var.openvpn_admin_user}"
  openvpn_admin_pw   = "${var.openvpn_admin_pw}"
}
