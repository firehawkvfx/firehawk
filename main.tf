provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  #  access_key = "${var.aws_access_key}"
  #  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

module "vpc" {
  source = "./modules/vpc"

  #sleep will disable the nat gateway to save cost during idle time.
  sleep = "${var.sleep}"
}

#options for gateway type are centos7 and pcoip
variable "gateway_type" {
  default = "pcoip"
}

module "vpn" {
  source = "./modules/vpn"

  vpc_id   = "${module.vpc.vpc_id}"
  vpc_cidr = "${module.vpc.vpc_cidr_block}"

  #the cidr range that the vpn will assign to remote addresses within the vpc if routing.
  vpn_cidr = "${var.vpn_cidr}"

  #the remote public address that will connect to the openvpn instance
  remote_vpn_ip_cidr = "${var.remote_ip_cidr}"

  public_subnet_ids = "${module.vpc.public_subnets}"

  #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.
  route_zone_id      = "${var.route_zone_id}"
  key_name           = "${var.key_name}"
  private_key        = "${file("${var.local_key_path}")}"
  local_key_path     = "${var.local_key_path}"
  cert_arn           = "${var.cert_arn}"
  public_domain_name = "${var.public_domain_name}"
  openvpn_user       = "${var.openvpn_user}"
  openvpn_admin_user = "${var.openvpn_admin_user}"
  openvpn_admin_pw   = "${var.openvpn_admin_pw}"

  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep}"
}

#A single softnas instance that resides in a private subnet for high performance nfs storage
variable "softnas_skip_update" {
  default = true
}

module "softnas" {
  source = "./modules/softnas"

  vpn_private_ip              = "${module.vpn.private_ip}"
  key_name                    = "${var.key_name}"
  private_key                 = "${file("${var.local_key_path}")}"
  vpc_id                      = "${module.vpc.vpc_id}"
  private_subnets             = "${module.vpc.private_subnets}"
  private_subnets_cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"
  public_subnets_cidr_blocks  = "${module.vpc.public_subnets_cidr_blocks}"
  bastion_private_ip          = "${module.pcoipgw.private_ip}"
  volumes                     = "${var.volumes}"
  mounts                      = "${var.mounts}"

  #skipping os updates will allow faster rollout, but may be non functional
  skip_update = "${var.softnas_skip_update}"

  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep}"
}

#PCOIP Gateway.  This is a graphical instance that serves as a gateway into the vpc should vpn access fail.
variable "pcoip_skip_update" {
  default = true
}

module "pcoipgw" {
  source = "./modules/pcoipgw"

  #options for gateway type are centos7 and pcoip
  gateway_type      = "${var.gateway_type}"
  vpc_id            = "${module.vpc.vpc_id}"
  vpc_cidr          = "${module.vpc.vpc_cidr_block}"
  remote_ip_cidr    = "${var.remote_ip_cidr}"
  public_subnet_ids = "${module.vpc.public_subnets}"

  #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.
  key_name    = "${var.key_name}"
  private_key = "${file("${var.local_key_path}")}"
  skip_update = "${var.pcoip_skip_update}"

  #skipping os updates will allow faster rollout, but may be non functional
  skip_update = "${var.pcoip_skip_update}"

  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep}"
}
