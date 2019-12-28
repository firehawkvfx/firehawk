variable "vpc_id" {
}

variable "vpc_cidr" {
}

#example 10.0.0.0/16
variable "vpn_cidr" {
}

variable "bastion_ip" {
}

# remote_vpn_ip_cidr is the ip address of the remote host / user intending to connect over vpn. eg '197.125.62.53/32'
variable "remote_vpn_ip_cidr" {
}

# examples ["subnet-0a7554f56af4d6d0a", "subnet-0257c7f8b1d68b6e4"]
variable "public_subnet_ids" {
  default = []
}

variable "route_zone_id" {
}

variable "key_name" {
}

#contents of the my_key.pem file to connect to the vpn.
variable "private_key" {
}

variable "ami" {
  # open vpn ami id / version
  #v2.7.5
  default = "ami-0d8ba0e9e6b6d18b7"
}

variable "instance_type" {
  default = "m5.xlarge"
}

variable "cert_arn" {
}

# public domain name withou www
variable "public_domain_name" {
}

variable "openvpn_admin_user" {
}

variable "openvpn_user" {
}

variable "openvpn_user_pw" {
}

variable "openvpn_admin_pw" {
}

variable "local_key_path" {
}

variable "sleep" {
  default = false
}

variable "remote_subnet_cidr" {
}

variable "igw_id" {
}

variable "private_subnets" {
  default = []
}

variable "public_subnets" {
  default = []
}

variable "route_public_domain_name" {}

variable "create_vpn" {}

variable "openvpn_v2_7_5" {
  type = map(string)
  default = {
        "eu-north-1": "ami-039e147d",
        "ap-south-1": "ami-00b7bb451c0c20931",
        "eu-west-3": "ami-046a4e41b1e9b05de",
        "eu-west-2": "ami-0d8328d4870bdb740",
        "eu-west-1": "ami-0cb4952aadb21a730",
        "ap-northeast-2": "ami-0ee35e6d85611600d",
        "ap-northeast-1": "ami-0fb7d2efacd90133b",
        "sa-east-1": "ami-01ed0cb648aab86b9",
        "ca-central-1": "ami-027ea0cc4e34dbf65",
        "ap-southeast-1": "ami-086b2468bd6cf03ae",
        "ap-southeast-2": "ami-0d8ba0e9e6b6d18b7",
        "eu-central-1": "ami-01a95ada398994de8",
        "us-east-1": "ami-0ca1c6f31c3fb1708",
        "us-east-2": "ami-06b7ca1fe6197b6ff",
        "us-west-1": "ami-0f2426a96b5ca8a0c",
        "us-west-2": "ami-034692da3c6768a18"
    }
}

variable "aws_region" {}

module "openvpn" {
  #source = "github.com/firehawkvfx/tf_aws_openvpn"

  create_vpn = var.create_vpn

  source = "../tf_aws_openvpn"

  route_public_domain_name = var.route_public_domain_name

  #start vpn will initialise service locally to connect
  #start_vpn = false
  igw_id = var.igw_id

  #create_openvpn = "${var.create_openvpn}"
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  name = "openvpn_ec2"

  # VPC Inputs
  vpc_id             = var.vpc_id
  vpc_cidr           = var.vpc_cidr
  vpn_cidr           = var.vpn_cidr
  public_subnet_ids  = var.public_subnet_ids
  remote_vpn_ip_cidr = var.remote_vpn_ip_cidr
  remote_subnet_cidr = var.remote_subnet_cidr

  # EC2 Inputs
  key_name       = var.key_name
  private_key    = var.private_key
  local_key_path = var.local_key_path
  ami            = lookup(var.openvpn_v2_7_5, var.aws_region)
  instance_type  = var.instance_type

  # Network Routing Inputs.  source destination checks are disable for nat gateways or routing on an instance.
  source_dest_check = false

  # ELB Inputs
  cert_arn = var.cert_arn

  # DNS Inputs
  public_domain_name = var.public_domain_name
  route_zone_id      = var.route_zone_id

  # OpenVPN Inputs
  openvpn_user       = var.openvpn_user
  openvpn_user_pw    = var.openvpn_user_pw
  openvpn_admin_user = var.openvpn_admin_user # Note: Don't choose "admin" username. Looks like it's already reserved.
  openvpn_admin_pw   = var.openvpn_admin_pw

  bastion_ip = var.bastion_ip

  #sleep will stop instances to save cost during idle time.
  sleep = var.sleep
}

output "id" {
  value = module.openvpn.id
}

output "private_ip" {
  value = module.openvpn.private_ip
}

output "public_ip" {
  value = module.openvpn.public_ip
}

