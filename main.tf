provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  region = var.aws_region
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  # version = "~> ${var.aws_provider_version}"
}

data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}

variable "CI_JOB_ID" {}
variable "active_pipeline" {}

# if var.pgp_public_key contains keybase, then use that.  else take the contents of the var as a file on disc
locals {
  pgp_public_key = length(regexall(".*keybase:.*", var.pgp_public_key)) > 0 ? var.pgp_public_key : filebase64("/secrets/keys/gpg_pub_key.gpg.pub")
  common_tags = {
    environment  = "${var.envtier}"
    pipelineid   = "${var.active_pipeline}"
    owner        = "${data.aws_canonical_user_id.current.display_name}"
    accountid    = "${data.aws_caller_identity.current.account_id}"
    terraform    = "true"
  }
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

variable "aws_provider_version" {}

variable "private_subnet1" {
}

variable "private_subnet2" {
}

variable "public_subnet1" {
}

variable "public_subnet2" {
}

module "firehawk_init" {
  # Firehawk init uses Ansible to provision local onsite vm's and workstations.
  source = "./modules/firehawk_init"

  firehawk_init = true
  
  storage_user_access_key_id = module.storage_user.storage_user_access_key_id
  storage_user_secret = module.storage_user.storage_user_secret

  install_houdini = var.install_houdini
  install_deadline_db = var.install_deadline_db
  install_deadline_rcs = var.install_deadline_rcs
  install_deadline_worker = var.install_deadline_worker
}

module "vpc" {

  firehawk_init_dependency = module.firehawk_init.local-provisioning-complete
  source = "./modules/vpc"

  create_vpc = var.enable_vpc

  route_public_domain_name = var.route_public_domain_name

  #sleep will disable the nat gateway to save cost during idle time.
  sleep              = var.sleep
  enable_nat_gateway = var.enable_nat_gateway

  azs = var.azs

  private_subnets = [var.private_subnet1, var.private_subnet2]
  public_subnets  = [var.public_subnet1, var.public_subnet2]

  vpc_cidr = var.vpc_cidr

  #vpn variables

  #the cidr range that the vpn will assign to remote addresses within the vpc if routing.
  vpn_cidr = var.vpn_cidr

  #the remote public address that will connect to the openvpn instance and other public instances
  remote_ip_cidr = var.remote_ip_cidr

  #the remote private cidr range of the subnet the openvpn client reside in.  used if you intend to use the client as a router / gateway for other nodes in your private network.
  remote_subnet_cidr = var.remote_subnet_cidr

  #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.

  key_name           = var.key_name
  private_key        = file(var.local_key_path)
  local_key_path     = var.local_key_path
  route_zone_id      = var.route_zone_id
  public_domain_name = var.public_domain
  cert_arn           = var.cert_arn
  openvpn_user       = var.openvpn_user
  openvpn_user_pw    = var.openvpn_user_pw
  openvpn_admin_user = var.openvpn_admin_user
  openvpn_admin_pw   = var.openvpn_admin_pw

  bastion_ip         = module.bastion.public_ip
  bastion_dependency = module.bastion.bastion_dependency

  common_tags = local.common_tags
}

variable "node_skip_update" {
  default = false
}

module "bastion" {
  source = "./modules/bastion"

  create_vpc = var.enable_vpc

  name = "bastion_pipeid${lookup(local.common_tags, "pipelineid", "0")}"

  route_public_domain_name = var.route_public_domain_name

  # region will determine the ami
  region = var.aws_region

  #options for gateway type are centos7 and pcoip
  vpc_id                      = module.vpc.vpc_id
  vpc_cidr                    = var.vpc_cidr
  vpn_cidr                    = var.vpn_cidr
  remote_ip_cidr              = var.remote_ip_cidr
  public_subnet_ids           = module.vpc.public_subnets
  public_subnets_cidr_blocks  = module.vpc.public_subnets_cidr_blocks
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  remote_subnet_cidr          = var.remote_subnet_cidr

  key_name       = var.key_name
  local_key_path = var.local_key_path
  private_key    = file(var.local_key_path)

  route_zone_id      = var.route_zone_id
  public_domain_name = var.public_domain

  #skipping os updates will allow faster rollout for testing.
  skip_update = var.node_skip_update

  #sleep will stop instances to save cost during idle time.
  sleep = var.sleep

  common_tags = local.common_tags
}

output "vpn_private_ip" {
  value = module.vpc.vpn_private_ip
}

# if a new image is detected, TF will update the spot template and spot plugin json settings
# consider using md5 of spot template to trigger an update.
# alternative do it manually with
# terraform taint null_resource.provision_deadline_spot[0]
# terraform apply

module "storage_user" {
  source          = "./modules/storage_user"
  pgp_public_key = local.pgp_public_key
  common_tags = local.common_tags
}

output "storage_user_access_key_id" {
  value = module.storage_user.storage_user_access_key_id
}

output "storage_user_secret" {
  value = module.storage_user.storage_user_secret
}

module "deadline" {
  source          = "./modules/deadline"
  pgp_public_key = local.pgp_public_key
  remote_ip_cidr  = var.remote_ip_cidr
  cidr_list       = concat([var.remote_subnet_cidr, var.remote_ip_cidr], module.vpc.private_subnets_cidr_blocks)
  common_tags = local.common_tags
}

output "spot_access_key_id" {
  value = module.deadline.spot_access_key_id
}

resource "null_resource" "dependency_deadline_spot" {
  triggers = {
    spot_access_key_id = module.deadline.spot_access_key_id
    spot_secret        = module.deadline.spot_secret
  }
}

locals {
  config_template_file_path = "/deployuser/ansible/ansible_collections/firehawkvfx/deadline/roles/deadline_spot/files/config_template.json"
  override_config_template_file_path = "/secrets/overrides/ansible/ansible_collections/firehawkvfx/deadline/roles/deadline_spot/files/config_template.json"
}

resource "null_resource" "provision_deadline_spot" {
  count      = (var.aws_nodes_enabled && var.provision_deadline_spot_plugin) ? 1 : 0
  depends_on = [null_resource.dependency_deadline_spot, module.node.ami_id, module.firehawk_init.local-provisioning-complete]

  triggers = {
    ami_id                  = module.node.ami_id
    config_template_sha1    = "${sha1(file( fileexists(local.override_config_template_file_path) ? local.override_config_template_file_path : local.config_template_file_path))}"
    deadline_spot_sha1      = "${sha1(file("/deployuser/ansible/ansible_collections/firehawkvfx/deadline/deadline_spot.yaml"))}"
    deadline_spot_role_sha1 = "${sha1(file("/deployuser/ansible/ansible_collections/firehawkvfx/deadline/roles/deadline_spot/tasks/main.yml"))}"
    deadline_roles_tf_sha1  = "${sha1(file("/deployuser/modules/deadline/main.tf"))}"
    spot_access_key_id      = module.deadline.spot_access_key_id
    spot_secret             = module.deadline.spot_secret
    volume_size             = var.node_centos_volume_size
    volume_type             = var.node_centos_volume_type
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      export SHOWCOMMANDS=true; set -x
      cd /deployuser
      echo ${module.deadline.spot_access_key_id}
      echo ${module.deadline.spot_secret}
      ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/deadline/deadline_spot.yaml -v --extra-vars 'volume_type=${var.node_centos_volume_type} volume_size=${var.node_centos_volume_size} ami_id=${module.node.ami_id} snapshot_id=${module.node.snapshot_id} subnet_id=${module.vpc.private_subnets[0]} spot_instance_profile_arn="${module.deadline.spot_instance_profile_arn}" security_group_id=${module.node.security_group_id} spot_access_key_id=${module.deadline.spot_access_key_id} spot_secret=${module.deadline.spot_secret} account_id=${lookup(local.common_tags, "accountid", "0")}'
EOT
  }
}


# to debug only
output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

# todo : this option is deprecated.  must be pcoip.  previous options for gateway type are centos7 and pcoip
variable "gateway_type" {
  default = "pcoip"
}

variable "allow_prebuilt_softnas_ami" { # after an initial deployment a base AMI and any software updates are run, a prebuilt ami is created.  Once it exists, it will be used in future deployments until the base ami is altered.
  default = true
}


# A single softnas instance that resides in a private subnet for high performance nfs storage

module "softnas" {  
  softnas_storage                = var.softnas_storage
  source                         = "./ansible/ansible_collections/firehawkvfx/softnas/terraform/softnas"

  init_aws_local_workstation = module.firehawk_init.init_aws_local_workstation

  allow_prebuilt_softnas_ami = var.allow_prebuilt_softnas_ami

  aws_region                     = var.aws_region
  softnas_instance_type          = var.softnas_instance_type
  vpn_private_ip                 = module.vpc.vpn_private_ip
  softnas_ssh_user               = var.softnas_ssh_user
  key_name                       = var.key_name
  private_key                    = file(var.local_key_path)
  vpc_id                         = module.vpc.vpc_id
  vpn_cidr                       = var.vpn_cidr
  public_domain                  = var.public_domain
  private_subnets                = module.vpc.private_subnets
  private_subnets_cidr_blocks    = module.vpc.private_subnets_cidr_blocks
  vpc_cidr = var.vpc_cidr
  public_subnets_cidr_blocks     = module.vpc.public_subnets_cidr_blocks
  remote_subnet_cidr             = var.remote_subnet_cidr
  remote_ip_cidr                 = var.remote_ip_cidr
  bastion_private_ip             = module.vpc.vpn_private_ip
  bastion_ip                     = module.bastion.public_ip
  softnas1_private_ip1           = var.softnas1_private_ip1
  softnas1_private_ip2           = var.softnas1_private_ip2
  softnas2_private_ip1           = var.softnas2_private_ip1
  softnas2_private_ip2           = var.softnas2_private_ip2

  remote_mounts_on_local = var.remote_mounts_on_local == true ? true : false

  #skipping os updates will allow faster rollout, but may be non functional
  skip_update = var.softnas_skip_update

  firehawk_path = var.firehawk_path

  #sleep will stop instances to save cost during idle time.
  sleep = var.sleep

  common_tags = local.common_tags
}

variable "pcoip_sleep_after_creation" {
  default = false
}

variable "pcoip_skip_update" {
  default = false
}

# module "pcoipgw" {
#   source = "./modules/pcoipgw"
#   name   = "gateway"

#   #options for gateway type are centos7 and pcoip
#   gateway_type      = "${var.gateway_type}"
#   vpc_id            = "${module.vpc.vpc_id}"
#   vpc_cidr          = "${var.vpc_cidr}"
#   vpn_cidr          = "${var.vpn_cidr}"
#   remote_ip_cidr    = "${var.remote_ip_cidr}"
#   public_subnet_ids = "${module.vpc.public_subnets}"

#   bastion_ip = "${module.bastion.public_ip}"

#   key_name    = "${var.key_name}"
#   private_key = "${file("${var.local_key_path}")}"

#   #skipping os updates will allow faster rollout for testing, but may be non functional
#   skip_update = "${var.pcoip_skip_update}"

#   route_zone_id      = "${var.route_zone_id}"
#   public_domain_name = "${var.public_domain}"

#   #sleep will stop instances to save cost during idle time.
#   sleep                      = "${var.sleep}"
#   pcoip_sleep_after_creation = "${var.pcoip_sleep_after_creation}"

#   private_subnets_cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"
#   remote_subnet_cidr          = "${var.remote_subnet_cidr}"

#   openfirehawkserver = "${var.openfirehawkserver}"

#   houdini_license_server_address = "${var.houdini_license_server_address}"
# }




module "workstation" {
  source = "./modules/workstation_pcoip"
  name   = "workstation_pcoip_pipeid${lookup(local.common_tags, "pipelineid", "0")}"

  workstation_enabled = var.workstation_enabled

  #options for gateway type are centos7 and pcoip
  gateway_type   = var.gateway_type
  vpc_id         = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
  vpn_cidr       = var.vpn_cidr
  remote_ip_cidr = var.remote_ip_cidr

  key_name    = var.key_name
  private_key = file(var.local_key_path)

  #skipping os updates will allow faster rollout for testing, but may be non functional
  skip_update = var.pcoip_skip_update
  aws_nodes_enabled = var.aws_nodes_enabled

  public_domain_name = var.public_domain

  # dependencies
  softnas_private_ip1             = module.softnas.softnas1_private_ip
  provision_softnas_volumes       = module.softnas.provision_softnas_volumes
  attach_local_mounts_after_start = module.softnas.attach_local_mounts_after_start
  bastion_ip                      = module.bastion.public_ip

  #sleep will stop instances to save cost during idle time.
  sleep                      = var.sleep
  pcoip_sleep_after_creation = var.pcoip_sleep_after_creation

  private_subnet_ids          = module.vpc.private_subnets
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  remote_subnet_cidr          = var.remote_subnet_cidr

  openfirehawkserver = var.openfirehawkserver

  houdini_license_server_address = var.houdini_license_server_address

  common_tags = local.common_tags
}

variable "node_sleep_on_create" {
  default = true
}

module "node" {
  
  # need to ensure mounts exist on start 
  source = "./modules/node_centos"
  name   = "centos_pipeid${lookup(local.common_tags, "pipelineid", "0")}"

  # region will determine the ami
  region = var.aws_region

  # the iam instance profile provide credentials for s3 read and write access, the ability to list instance states, and read tags to join deadline groups when launched in a spot fleet
  instance_profile_name = module.deadline.spot_instance_profile_name

  # options for gateway type are centos7 and pcoip
  vpc_id                      = module.vpc.vpc_id
  vpc_cidr                    = var.vpc_cidr
  vpn_cidr                    = var.vpn_cidr
  remote_ip_cidr              = var.remote_ip_cidr
  private_subnet_ids          = module.vpc.private_subnets
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  remote_subnet_cidr          = var.remote_subnet_cidr

  # dependencies
  vpn_private_ip                 = module.vpc.vpn_private_ip
  dependency = module.firehawk_init.local-provisioning-complete
  softnas_private_ip1             = module.softnas.softnas1_private_ip
  provision_softnas_volumes       = module.softnas.provision_softnas_volumes
  attach_local_mounts_after_start = module.softnas.attach_local_mounts_after_start
  bastion_ip                      = module.bastion.public_ip

  openfirehawkserver = var.openfirehawkserver

  instance_type = var.node_centos_instance_type

  volume_size = var.node_centos_volume_size

  key_name       = var.key_name
  local_key_path = var.local_key_path
  private_key    = file(var.local_key_path)

  #skipping os updates will allow faster rollout for testing.
  skip_update = var.node_skip_update

  # when a vpn is being installed, or before that point, site mounts must be disabled
  aws_nodes_enabled = var.aws_nodes_enabled

  #sleep will stop instances to save cost during idle time.
  sleep = var.sleep

  wakeable = var.node_wakeable

  install_houdini = var.install_houdini
  install_deadline_worker = var.install_deadline_worker
  houdini_license_server_address = var.houdini_license_server_address

  common_tags = local.common_tags
}

output "snapshot_id" {
  value = module.node.snapshot_id
}

output "base_ami" {
  value = module.softnas.base_ami
}

output "prebuilt_softnas_ami_list" {
  value = module.softnas.prebuilt_softnas_ami_list
}

output "use_prebuilt_softnas_ami" {
  value = module.softnas.use_prebuilt_softnas_ami
}

output "node_ami_id" {
  value = module.node.ami_id
}
