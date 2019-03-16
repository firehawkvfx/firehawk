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

variable "key_name" {}

#contents of the my_key.pem file to connect to the vpn.
variable "private_key" {}

variable "ami" {
  #v2.5
  #default = "ami-7777b515"
  #v2.6.1
  default = "ami-05fdd828e5a7530b0"
}

variable "instance_type" {
  default = "m4.large"
}

variable "cert_arn" {}

# public domain name withou www
variable "public_domain_name" {}

variable "openvpn_admin_user" {}

variable "openvpn_user" {}
variable "openvpn_user_pw" {}
variable "openvpn_admin_pw" {}

variable "local_key_path" {}

variable "sleep" {
  default = false
}

variable "remote_subnet_cidr" {}

variable "igw_id" {}

module "openvpn" {
  #source = "github.com/firehawkvfx/tf_aws_openvpn"

  source = "../tf_aws_openvpn"

  #start vpn will initialise service locally to connect
  #start_vpn = false
  igw_id = "${var.igw_id}"

  #create_openvpn = "${var.create_openvpn}"

  name = "openvpn_ec2"
  # VPC Inputs
  vpc_id             = "${var.vpc_id}"
  vpc_cidr           = "${var.vpc_cidr}"
  vpn_cidr           = "${var.vpn_cidr}"
  public_subnet_ids  = "${var.public_subnet_ids}"
  remote_vpn_ip_cidr = "${var.remote_vpn_ip_cidr}"
  remote_subnet_cidr = "${var.remote_subnet_cidr}"
  # EC2 Inputs
  key_name       = "${var.key_name}"
  private_key    = "${var.private_key}"
  local_key_path = "${var.local_key_path}"
  ami            = "${var.ami}"
  instance_type  = "${var.instance_type}"
  # Network Routing Inputs.  source destination checks are disable for nat gateways or routing on an instance.
  source_dest_check = false
  # ELB Inputs
  cert_arn = "${var.cert_arn}"
  # DNS Inputs
  public_domain_name   = "${var.public_domain_name}"
  route_zone_id = "${var.route_zone_id}"
  # OpenVPN Inputs
  openvpn_user       = "${var.openvpn_user}"
  openvpn_user_pw    = "${var.openvpn_user_pw}"
  openvpn_admin_user = "${var.openvpn_admin_user}" # Note: Don't choose "admin" username. Looks like it's already reserved.
  openvpn_admin_pw   = "${var.openvpn_admin_pw}"
  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep}"
}

output "id" {
  value = "${module.openvpn.id}"
}

output "private_ip" {
  value = "${module.openvpn.private_ip}"
}

output "public_ip" {
  value = "${module.openvpn.public_ip}"
}
