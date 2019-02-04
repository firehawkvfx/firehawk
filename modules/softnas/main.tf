variable "key_name" {}
variable "private_key" {}

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

variable "volumes" {
  default = []
}

variable "mounts" {
  default = []
}

variable "sleep" {
  default = false
}

variable "bastion_private_ip" {}

variable "skip_update" {
  default = false
}

variable "softnas_private_ip1" {
  default = "10.0.1.11"
}

variable "softnas_private_ip2" {
  default = "10.0.1.12"
}

variable "softnas_export_path" {
  default = "/naspool2/nasvol2"
}


variable "vpn_cidr" {}

variable "softnas_user_password" {}

variable "cloudformation_role_name" {}

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
    SoftnasUserPassword = "${var.softnas_user_password}"
    NasType             = "m4.xlarge"
    PrivateIPEth0NAS1   = "${var.softnas_private_ip1}"
    PrivateIPEth1NAS1   = "${var.softnas_private_ip2}"

    #security groups will open access to some public facing instances via their private ips. 
    #1st is the vpn
    ADBastion1PrivateIP = "${var.vpn_private_ip}"

    #2nd is likely some other bastion / gateway that you will use to access the softnas instance.  This provides an alternative if there are issues with the vpn.
    ADBastion2PrivateIP = "${var.bastion_private_ip}"
    PrivateSubnet1CIDR  = "${var.private_subnets_cidr_blocks[0]}"
    VPCID               = "${var.vpc_id}"
    VPNCIDR = "${var.vpn_cidr}"
    PrivateSubnet1ID    = "${var.private_subnets[0]}"
    PrivateSubnet2CIDR  = "${var.private_subnets_cidr_blocks[1]}"
    PrivateSubnet2ID    = "${var.private_subnets[1]}"
    PublicSubnet1CIDR   = "${var.public_subnets_cidr_blocks[0]}"
    PublicSubnet2CIDR   = "${var.public_subnets_cidr_blocks[1]}"

    SoftnasExportPath = "${var.softnas_export_path}"
  }

  template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-1az.json"
}

output "instanceid" {
  value = "${aws_cloudformation_stack.SoftNASStack.outputs["InstanceID"]}"
}

output "private_ip" {
  value = "${aws_cloudformation_stack.SoftNASStack.outputs["InstanceIP"]}"
}

# Attach existing ebs volumes to the softnas instance.  if a volume has been initialised previously, it will be detected by softnas.
# we iterate over the volumes and mounts to attach them to the softnas instance 

resource "aws_volume_attachment" "ebs_att" {
  count       = "${length(var.volumes)}"
  device_name = "${element(var.mounts, count.index)}"
  volume_id   = "${element(var.volumes, count.index)}"
  instance_id = "${aws_cloudformation_stack.SoftNASStack.outputs["InstanceID"]}"
}

# todo : need to report success at correct time after it has started.  see email from steven melnikov at softnas to check how to do this.

# we need to append data to the end of /etc/export.  since the instance is inside a private subnet, a vpn connection must be active prior to configuration
# this wont work until a vpn can be started by terraform.  currently, this code exists in the cloudformation template.
# ansible may be a better way to do this.

#wakeup a node after sleep
resource "null_resource" "start-node" {
  count = "${var.sleep ? 0 : 1}"

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_cloudformation_stack.SoftNASStack.outputs["InstanceID"]}"
  }
}

resource "null_resource" shutdownsoftnas {
  count = "${var.sleep ? 1 : 0}"

  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_cloudformation_stack.SoftNASStack.outputs["InstanceID"]}"
  }
}
