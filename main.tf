provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  #  access_key = "${var.aws_access_key}"
  #  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
  
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
  source                         = "./modules/softnas"
  cloudformation_role_stack_name = "${var.softnas1_cloudformation_role_name}"

  #softnas_role = "${module.softnas_role.softnas_role_name}"

  cloudformation_stack_name   = "FCB-SoftNAS1Stack"
  vpn_private_ip              = "${module.vpc.vpn_private_ip}"
  key_name                    = "${var.key_name}"
  private_key                 = "${file("${var.local_key_path}")}"
  vpc_id                      = "${module.vpc.vpc_id}"
  vpn_cidr                    = "${var.vpn_cidr}"
  private_subnets             = "${module.vpc.private_subnets}"
  private_subnets_cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"
  public_subnets_cidr_blocks  = "${module.vpc.public_subnets_cidr_blocks}"
  bastion_private_ip          = "${module.vpc.vpn_private_ip}"
  softnas_user_password       = "${var.softnas_user_password}"

  #softnas_role_name = "${module.softnas_role.softnas_role_name}"

  softnas1_private_ip1 = "${var.softnas1_private_ip1}"
  softnas1_private_ip2 = "${var.softnas1_private_ip2}"
  softnas1_export_path = "${var.softnas1_export_path}"
  softnas1_volumes     = "${var.softnas1_volumes}"
  softnas1_mounts      = "${var.softnas1_mounts}"
  softnas2_private_ip1 = "${var.softnas2_private_ip1}"
  softnas2_private_ip2 = "${var.softnas2_private_ip2}"
  softnas2_export_path = "${var.softnas2_export_path}"
  softnas2_volumes     = "${var.softnas2_volumes}"
  softnas2_mounts      = "${var.softnas2_mounts}"
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

# module "node" {
#   source = "./modules/node_centos"
#   name   = "centos"

#   # region will determine the ami
#   region = "${var.region}"

#   #options for gateway type are centos7 and pcoip
#   vpc_id                      = "${module.vpc.vpc_id}"
#   vpc_cidr                    = "${module.vpc.vpc_cidr_block}"
#   vpn_cidr                    = "${var.vpn_cidr}"
#   remote_ip_cidr              = "${var.remote_ip_cidr}"
#   private_subnet_ids          = "${module.vpc.private_subnets}"
#   private_subnets_cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"
#   remote_subnet_cidr          = "${var.remote_subnet_cidr}"

#   key_name                       = "${var.key_name}"
#   local_key_path                 = "${var.local_key_path}"
#   private_key                    = "${file("${var.local_key_path}")}"
#   deadline_certificates_location = "${var.deadline_certificates_location}"
#   deadline_prefix                = "${var.deadline_prefix}"
#   deadline_installers_filename   = "${var.deadline_installers_filename}"

#   #skipping os updates will allow faster rollout for testing.
#   skip_update = "${var.node_skip_update}"

#   #sleep will stop instances to save cost during idle time.
#   sleep = "${var.sleep || var.node_sleep_on_create}"

#   deadline_user                       = "${var.deadline_user}"
#   deadline_user_password              = "${var.deadline_user_password}"
#   deadline_samba_server_address       = "${var.deadline_samba_server_address}"
#   deadline_samba_server_hostname      = "${var.deadline_samba_server_hostname}"
#   deadline_proxy_root_dir             = "${var.deadline_proxy_root_dir}"
#   deadline_user_uid                   = "${var.deadline_user_uid}"
#   deadline_proxy_certificate          = "${var.deadline_proxy_certificate}"
#   deadline_proxy_certificate_password = "${var.deadline_proxy_certificate_password}"
#   deadline_db_ssl_password            = "${var.deadline_db_ssl_password}"
#   deadline_client_certificate         = "${var.deadline_client_certificate}"

#   houdini_license_server_address = "${var.houdini_license_server_address}"

#   #softnas_private_ip        = "${module.softnas.private_ip}"
#   time_zone_info_path_linux = "${lookup(var.time_zone_info_path_linux, "Australia_Sydney")}"

#   softnas_private_ip1 = "${var.softnas1_private_ip1}"
#   softnas_export_path = "${var.softnas1_export_path}"
#   softnas_mount_path  = "${var.softnas1_mount_path}"
# }

module "bastion" {
  source = "./modules/bastion"

  name = "bastion"

  # region will determine the ami
  region = "${var.region}"

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

  #skipping os updates will allow faster rollout for testing.
  skip_update = "${var.node_skip_update}"

  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep || var.node_sleep_on_create}"

  #softnas_private_ip        = "${module.softnas.private_ip}"
  time_zone_info_path_linux = "${lookup(var.time_zone_info_path_linux, "Australia_Sydney")}"
}
