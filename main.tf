provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  #  access_key = "${var.aws_access_key}"
  #  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"

  # in a dev environment these 3 version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 1.60"
}

provider "null" {
  version = "~> 2.0"
}

provider "random" {
  version = "~> 2.0"
}

variable "enable_nat_gateway" {
  default = true
}

variable "private_subnet1" {}
variable "private_subnet2" {}
variable "public_subnet1" {}
variable "public_subnet2" {}


module "vpc" {
  source = "./modules/vpc"

  #sleep will disable the nat gateway to save cost during idle time.
  sleep              = "${var.sleep}"
  enable_nat_gateway = "${var.enable_nat_gateway}"

  private_subnets = ["${var.private_subnet1}", "${var.private_subnet2}"]
  public_subnets = ["${var.public_subnet1}", "${var.public_subnet2}"]
  
  all_private_subnets_cidr_range = "10.0.0.0/18"

  #vpn variables

  #the cidr range that the vpn will assign to remote addresses within the vpc if routing.
  vpn_cidr = "${var.vpn_cidr}"
  #the remote public address that will connect to the openvpn instance and other public instances
  remote_ip_cidr = "${var.remote_ip_cidr}"
  #the remote private cidr range of the subnet the openvpn client reside in.  used if you intend to use the client as a router / gateway for other nodes in your private network.
  remote_subnet_cidr = "${var.remote_subnet_cidr}"

  #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.

  key_name           = "${var.key_name}"
  private_key        = "${file("${var.local_key_path}")}"
  local_key_path     = "${var.local_key_path}"
  route_zone_id      = "${var.route_zone_id}"
  public_domain_name = "${var.public_domain}"
  cert_arn           = "${var.cert_arn}"
  openvpn_user       = "${var.openvpn_user}"
  openvpn_user_pw    = "${var.openvpn_user_pw}"
  openvpn_admin_user = "${var.openvpn_admin_user}"
  openvpn_admin_pw   = "${var.openvpn_admin_pw}"
}

module "bastion" {
  source = "./modules/bastion"

  name = "bastion"

  # region will determine the ami
  region = "${var.aws_region}"

  #options for gateway type are centos7 and pcoip
  vpc_id                      = "${module.vpc.vpc_id}"
  vpc_cidr                    = "${module.vpc.vpc_cidr_block}"
  vpn_cidr                    = "${var.vpn_cidr}"
  remote_ip_cidr              = "${var.remote_ip_cidr}"
  public_subnet_ids           = "${module.vpc.public_subnets}"
  public_subnets_cidr_blocks  = "${module.vpc.public_subnets_cidr_blocks}"
  private_subnets_cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"
  remote_subnet_cidr          = "${var.remote_subnet_cidr}"

  key_name       = "${var.key_name}"
  local_key_path = "${var.local_key_path}"
  private_key    = "${file("${var.local_key_path}")}"

  route_zone_id      = "${var.route_zone_id}"
  public_domain_name = "${var.public_domain}"

  #skipping os updates will allow faster rollout for testing.
  skip_update = "${var.node_skip_update}"

  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep}"
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
  source                         = "./modules/softnas"
  cloudformation_role_stack_name = "${var.softnas1_cloudformation_role_name}"

  #softnas_role = "${module.softnas_role.softnas_role_name}"

  cloudformation_stack_name      = "FCB-SoftNAS1Stack"
  aws_region = "${var.aws_region}"
  softnas_mode = "${var.softnas_mode}"
  vpn_private_ip                 = "${module.vpc.vpn_private_ip}"
  key_name                       = "${var.key_name}"
  private_key                    = "${file("${var.local_key_path}")}"
  vpc_id                         = "${module.vpc.vpc_id}"
  vpn_cidr                       = "${var.vpn_cidr}"
  public_domain = "${var.public_domain}"
  private_subnets                = "${module.vpc.private_subnets}"
  private_subnets_cidr_blocks    = "${module.vpc.private_subnets_cidr_blocks}"
  all_private_subnets_cidr_range = "${module.vpc.all_private_subnets_cidr_range}"
  public_subnets_cidr_blocks     = "${module.vpc.public_subnets_cidr_blocks}"
  remote_subnet_cidr             = "${var.remote_subnet_cidr}"
  remote_ip_cidr                 = "${var.remote_ip_cidr}"
  bastion_private_ip             = "${module.vpc.vpn_private_ip}"
  bastion_ip = "${module.bastion.public_ip}"
  softnas1_private_ip1 = "${var.softnas1_private_ip1}"
  softnas1_private_ip2 = "${var.softnas1_private_ip2}"
  softnas1_mounts = "${var.softnas1_mounts}"
  softnas2_private_ip1 = "${var.softnas2_private_ip1}"
  softnas2_private_ip2 = "${var.softnas2_private_ip2}"
  softnas2_mounts = "${var.softnas2_mounts}"
  s3_disk_size = "${var.s3_disk_size}"
  #skipping os updates will allow faster rollout, but may be non functional
  skip_update = "${var.softnas_skip_update}"
  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep}"
}

# softnas 1 must exist before softnas 2 does.  there are limits with dependencys and rols that require this.
# todo when dependencys work, split the module up.  run a loop

variable "pcoip_sleep_after_creation" {
  default = true
}

variable "pcoip_skip_update" {
  default = true
}

# module "pcoipgw" {
#   source = "./modules/pcoipgw"
#   name   = "pcoip"

#   #options for gateway type are centos7 and pcoip
#   gateway_type      = "${var.gateway_type}"
#   vpc_id            = "${module.vpc.vpc_id}"
#   vpc_cidr          = "${module.vpc.vpc_cidr_block}"
#   vpn_cidr          = "${var.vpn_cidr}"
#   remote_ip_cidr    = "${var.remote_ip_cidr}"
#   public_subnet_ids = "${module.vpc.public_subnets}"

#   key_name    = "${var.key_name}"
#   private_key = "${file("${var.local_key_path}")}"

#   #skipping os updates will allow faster rollout for testing, but may be non functional
#   skip_update = "${var.pcoip_skip_update}"

#   #sleep will stop instances to save cost during idle time.
#   sleep                      = "${var.sleep}"
#   pcoip_sleep_after_creation = "${var.pcoip_sleep_after_creation}"
# }

variable "node_skip_update" {
  default = false
}

variable "node_sleep_on_create" {
  default = true
}

module "node" {
  source = "./modules/node_centos"
  name   = "centos"

  # region will determine the ami
  region = "${var.aws_region}"

  # options for gateway type are centos7 and pcoip
  vpc_id                      = "${module.vpc.vpc_id}"
  vpc_cidr                    = "${module.vpc.vpc_cidr_block}"
  vpn_cidr                    = "${var.vpn_cidr}"
  remote_ip_cidr              = "${var.remote_ip_cidr}"
  private_subnet_ids          = "${module.vpc.private_subnets}"
  private_subnets_cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"
  remote_subnet_cidr          = "${var.remote_subnet_cidr}"
  provision_softnas_volumes = "${module.softnas.provision_softnas_volumes}"
  bastion_ip = "${module.bastion.public_ip}"

  key_name       = "${var.key_name}"
  local_key_path = "${var.local_key_path}"
  private_key    = "${file("${var.local_key_path}")}"

  #skipping os updates will allow faster rollout for testing.
  skip_update = "${var.node_skip_update}"
  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep}"

  houdini_license_server_address = "${var.houdini_license_server_address}"
  softnas_private_ip1            = "${module.softnas.softnas1_private_ip}"
}
