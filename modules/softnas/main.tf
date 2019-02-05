#variable "name" {}
resource "aws_cloudformation_stack" "SoftNASRole" {
  name         = "${var.cloudformation_role_stack_name}"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
  template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-role.json"
}

output "softnas_role_id" {
  value = "${aws_cloudformation_stack.SoftNASRole.outputs["SoftnasRoleID"]}"
}

output "softnas_role_arn" {
  value = "${aws_cloudformation_stack.SoftNASRole.outputs["SoftnasARN"]}"
}

output "softnas_role_name" {
  value = "${aws_cloudformation_stack.SoftNASRole.outputs["SoftNasRoleName"]}"
}

resource "random_uuid" "test" {}

resource "aws_cloudformation_stack" "SoftNAS1Stack" {
  depends_on = ["aws_cloudformation_stack.SoftNASRole"]

  name               = "SoftNAS1-${random_uuid.test.result}"
  capabilities       = ["CAPABILITY_IAM"]
  timeout_in_minutes = "60"

  parameters = {
    SoftnasRoleName     = "SoftNAS_HA_IAM"
    KeyName             = "${var.key_name}"
    SoftnasUserPassword = "${var.softnas_user_password}"
    InstanceName        = "SoftNAS1_PlatinumConsumptionLowerCompute"
    AMI                 = "ami-a24a98c0"
    NasType             = "m4.xlarge"
    PrivateIPEth0NAS1   = "${var.softnas1_private_ip1}"
    PrivateIPEth1NAS1   = "${var.softnas1_private_ip2}"

    #security groups will open access to some public facing instances via their private ips. 
    #1st is the vpn
    ADBastion1PrivateIP = "${var.vpn_private_ip}"

    #2nd is likely some other bastion / gateway that you will use to access the softnas instance.  This provides an alternative if there are issues with the vpn.
    ADBastion2PrivateIP = "${var.bastion_private_ip}"
    PrivateSubnet1CIDR  = "${var.private_subnets_cidr_blocks[0]}"
    VPCID               = "${var.vpc_id}"
    VPNCIDR             = "${var.vpn_cidr}"
    PrivateSubnet1ID    = "${var.private_subnets[0]}"
    PrivateSubnet2CIDR  = "${var.private_subnets_cidr_blocks[1]}"
    PrivateSubnet2ID    = "${var.private_subnets[1]}"
    PublicSubnet1CIDR   = "${var.public_subnets_cidr_blocks[0]}"
    PublicSubnet2CIDR   = "${var.public_subnets_cidr_blocks[1]}"

    SoftnasExportPath = "${var.softnas1_export_path}"
  }

  template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-1az.json"
}

output "softnas1_instanceid" {
  value = "${aws_cloudformation_stack.SoftNAS1Stack.outputs["InstanceID"]}"
}

output "softnas1_private_ip" {
  value = "${aws_cloudformation_stack.SoftNAS1Stack.outputs["InstanceIP"]}"
}

# Attach existing ebs volumes to the softnas instance.  if a volume has been initialised previously, it will be detected by softnas.
# we iterate over the volumes and mounts to attach them to the softnas instance 

resource "aws_volume_attachment" "softnas1_ebs_att" {
  count       = "${length(var.softnas1_volumes)}"
  device_name = "${element(var.softnas1_mounts, count.index)}"
  volume_id   = "${element(var.softnas1_volumes, count.index)}"
  instance_id = "${aws_cloudformation_stack.SoftNAS1Stack.outputs["InstanceID"]}"
}

resource "aws_cloudformation_stack" "SoftNAS2Stack" {
  depends_on = ["aws_cloudformation_stack.SoftNASRole"]

  name               = "SoftNAS2-${random_uuid.test.result}"
  capabilities       = ["CAPABILITY_IAM"]
  timeout_in_minutes = "60"

  parameters = {
    SoftnasRoleName     = "SoftNAS_HA_IAM"
    KeyName             = "${var.key_name}"
    SoftnasUserPassword = "${var.softnas_user_password}"
    InstanceName        = "SoftNAS1_PlatinumConsumptionHigherCompute"
    AMI                 = "ami-5e7ea03c"
    NasType             = "m5.2xlarge"
    PrivateIPEth0NAS1   = "${var.softnas2_private_ip1}"
    PrivateIPEth1NAS1   = "${var.softnas2_private_ip2}"

    #security groups will open access to some public facing instances via their private ips. 
    #1st is the vpn
    ADBastion1PrivateIP = "${var.vpn_private_ip}"

    #2nd is likely some other bastion / gateway that you will use to access the softnas instance.  This provides an alternative if there are issues with the vpn.
    ADBastion2PrivateIP = "${var.bastion_private_ip}"
    PrivateSubnet1CIDR  = "${var.private_subnets_cidr_blocks[0]}"
    VPCID               = "${var.vpc_id}"
    VPNCIDR             = "${var.vpn_cidr}"
    PrivateSubnet1ID    = "${var.private_subnets[0]}"
    PrivateSubnet2CIDR  = "${var.private_subnets_cidr_blocks[1]}"
    PrivateSubnet2ID    = "${var.private_subnets[1]}"
    PublicSubnet1CIDR   = "${var.public_subnets_cidr_blocks[0]}"
    PublicSubnet2CIDR   = "${var.public_subnets_cidr_blocks[1]}"

    SoftnasExportPath = "${var.softnas2_export_path}"
  }

  template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-1az.json"
}

output "softnas2_instanceid" {
  value = "${aws_cloudformation_stack.SoftNAS2Stack.outputs["InstanceID"]}"
}

output "softnas2_private_ip" {
  value = "${aws_cloudformation_stack.SoftNAS2Stack.outputs["InstanceIP"]}"
}

resource "aws_volume_attachment" "softnas2_ebs_att" {
  count       = "${length(var.softnas2_volumes)}"
  device_name = "${element(var.softnas2_mounts, count.index)}"
  volume_id   = "${element(var.softnas2_volumes, count.index)}"
  instance_id = "${aws_cloudformation_stack.SoftNAS2Stack.outputs["InstanceID"]}"
}

# todo : need to report success at correct time after it has started.  see email from steven melnikov at softnas to check how to do this.

# we need to append data to the end of /etc/export.  since the instance is inside a private subnet, a vpn connection must be active prior to configuration
# this wont work until a vpn can be started by terraform.  currently, this code exists in the cloudformation template.
# ansible may be a better way to do this.

#wakeup a node after sleep
resource "null_resource" "start-node" {
  count = "${var.sleep ? 0 : 1}"

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_cloudformation_stack.SoftNAS1Stack.outputs["InstanceID"]}"
  }
}

resource "null_resource" shutdownsoftnas {
  count = "${var.sleep ? 1 : 0}"

  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_cloudformation_stack.SoftNAS1Stack.outputs["InstanceID"]}"

    command = <<EOT
      aws ec2 stop-instances --instance-ids ${aws_cloudformation_stack.SoftNAS1Stack.outputs["InstanceID"]}
      aws ec2 stop-instances --instance-ids ${aws_cloudformation_stack.SoftNAS2Stack.outputs["InstanceID"]}
  EOT
  }
}
