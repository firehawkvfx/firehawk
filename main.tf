provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  #  access_key = "${var.aws_access_key}"
  #  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

variable "enable_nat_gateway" {
  default = true
}

module "vpc" {
  source = "./modules/vpc"

  #sleep will disable the nat gateway to save cost during idle time.
  sleep              = "${var.sleep}"
  enable_nat_gateway = "${var.enable_nat_gateway}"

  #vpn variables

  #the cidr range that the vpn will assign to remote addresses within the vpc if routing.
  vpn_cidr = "${var.vpn_cidr}"
  #the remote public address that will connect to the openvpn instance and other public instances
  remote_ip_cidr = "${var.remote_ip_cidr}"
  #the remote private cidr range of the subnet the openvpn client reside in.  used if you intend to use the client as a router / gateway for other nodes in your private network.
  remote_subnet_cidr = "${var.remote_subnet_cidr}"
  #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.
  route_zone_id      = "${var.route_zone_id}"
  key_name           = "${var.key_name}"
  private_key        = "${file("${var.local_key_path}")}"
  local_key_path     = "${var.local_key_path}"
  cert_arn           = "${var.cert_arn}"
  public_domain_name = "${var.public_domain_name}"
  openvpn_user       = "${var.openvpn_user}"
  openvpn_user_pw    = "${var.openvpn_user_pw}"
  openvpn_admin_user = "${var.openvpn_admin_user}"
  openvpn_admin_pw   = "${var.openvpn_admin_pw}"
}

# todo : this option is deprecated.  must be pcoip.  previous options for gateway type are centos7 and pcoip
variable "gateway_type" {
  default = "pcoip"
}

#A single softnas instance that resides in a private subnet for high performance nfs storage
variable "softnas_skip_update" {
  default = false
}

module "softnas" {
  source = "./modules/softnas"

  vpn_private_ip              = "${module.vpc.vpn_private_ip}"
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

#this will stop the instance upon creation.  this is useful for graphical instances which are expensive and may not need to be used immediately.
variable "pcoip_sleep_after_creation" {
  default = true
}

module "pcoipgw" {
  source = "./modules/pcoipgw"
  name   = "pcoip"

  #options for gateway type are centos7 and pcoip
  gateway_type      = "${var.gateway_type}"
  vpc_id            = "${module.vpc.vpc_id}"
  vpc_cidr          = "${module.vpc.vpc_cidr_block}"
  vpn_cidr          = "${var.vpn_cidr}"
  remote_ip_cidr    = "${var.remote_ip_cidr}"
  public_subnet_ids = "${module.vpc.public_subnets}"

  key_name    = "${var.key_name}"
  private_key = "${file("${var.local_key_path}")}"

  #skipping os updates will allow faster rollout for testing, but may be non functional
  skip_update = "${var.pcoip_skip_update}"

  #sleep will stop instances to save cost during idle time.
  sleep                      = "${var.sleep}"
  pcoip_sleep_after_creation = "${var.pcoip_sleep_after_creation}"
}

variable "node_skip_update" {
  default = true
}

variable "node_sleep_on_create" {
  default = false
}

module "node" {
  source = "./modules/node-centos"
  name   = "centos"

  # region will determine the ami
  region = "${var.region}"

  #options for gateway type are centos7 and pcoip
  vpc_id                      = "${module.vpc.vpc_id}"
  vpc_cidr                    = "${module.vpc.vpc_cidr_block}"
  vpn_cidr                    = "${var.vpn_cidr}"
  remote_ip_cidr              = "${var.remote_ip_cidr}"
  private_subnet_ids          = "${module.vpc.private_subnets}"
  private_subnets_cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"
  remote_subnet_cidr          = "${var.remote_subnet_cidr}"

  key_name                       = "${var.key_name}"
  local_key_path                 = "${var.local_key_path}"
  private_key                    = "${file("${var.local_key_path}")}"
  deadline_certificates_location = "${var.deadline_certificates_location}"
  deadline_installers_filename   = "${var.deadline_installers_filename}"

  #skipping os updates will allow faster rollout for testing.
  skip_update = "${var.node_skip_update}"

  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep || var.node_sleep_on_create}"

  deadline_user                  = "${var.deadline_user}"
  deadline_user_password         = "${var.deadline_user_password}"
  deadline_samba_server_address  = "${var.deadline_samba_server_address}"
  deadline_samba_server_hostname = "${var.deadline_samba_server_hostname}"
  deadline_user_uid              = "${var.deadline_user_uid}"
  softnas_private_ip             = "${module.softnas.private_ip}"
}
