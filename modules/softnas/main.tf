variable "key_name" {}

variable "vpn_private_ip" {}

variable "vpc_id" {}

variable "private_subnets" {
  default = []
}

variable "private_subnets_cidr_blocks" {
  default = []
}

variable "public_subnets_cidr_blocks" {
  default = []
}

#this role should be conditionally created if it doesn't exist

resource "aws_cloudformation_stack" "SoftNASRole" {
  name         = "FCB-SoftNASRole"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
  template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-role.json"
}

resource "aws_cloudformation_stack" "SoftNASStack" {
  depends_on = ["aws_cloudformation_stack.SoftNASRole"]

  name               = "FCB-SoftNASStack"
  capabilities       = ["CAPABILITY_IAM"]
  timeout_in_minutes = "60"

  parameters = {
    KeyName             = "${var.key_name}"
    SoftnasUserPassword = "tempLogin497"
    NasType             = "m4.xlarge"
    PrivateIPEth0NAS1   = "10.0.1.11"
    PrivateIPEth1NAS1   = "10.0.1.12"

    #security groups will open access to some public facing instances via their private ips. 
    #1st is the vpn
    ADBastion1PrivateIP = "${var.vpn_private_ip}"

    #2nd is likely some other bastion / gateway
    ADBastion2PrivateIP = "10.0.101.181"
    PrivateSubnet1CIDR  = "${var.private_subnets_cidr_blocks[0]}"
    VPCID               = "${var.vpc_id}"
    PrivateSubnet1ID    = "${var.private_subnets[0]}"
    PrivateSubnet2CIDR  = "${var.private_subnets_cidr_blocks[1]}"
    PrivateSubnet2ID    = "${var.private_subnets[1]}"
    PublicSubnet1CIDR   = "${var.public_subnets_cidr_blocks[0]}"
    PublicSubnet2CIDR   = "${var.public_subnets_cidr_blocks[1]}"
  }

  template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-1az.json"
}
