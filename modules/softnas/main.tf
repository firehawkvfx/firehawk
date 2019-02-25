#variable "name" {}
# resource "aws_cloudformation_stack" "SoftNASRole" {
#   name         = "${var.cloudformation_role_stack_name}"
#   capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
#   template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-role.json"
# }



resource "aws_iam_role" "softnas_role" {
  name = "SoftNAS_HA_IAM"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "sts:AssumeRole"
          ],
          "Principal": {
              "Service": [
                  "ec2.amazonaws.com"
              ]
          },
          "Effect": "Allow"
      }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "softnas_ssm_attach" {
  role       = "${aws_iam_role.softnas_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy" "softnas_policy" {
  name = "SoftNAS_HA_IAM"
  role = "${aws_iam_role.softnas_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "Stmt1444200186000",
          "Effect": "Allow",
          "Action": [
              "ec2:ModifyInstanceAttribute",
              "ec2:DescribeInstances",
              "ec2:CreateVolume",
              "ec2:DeleteVolume",
              "ec2:CreateSnapshot",
              "ec2:DeleteSnapshot",
              "ec2:CreateTags",
              "ec2:DeleteTags",
              "ec2:AttachVolume",
              "ec2:DetachVolume",
              "ec2:DescribeInstances",
              "ec2:DescribeVolumes",
              "ec2:DescribeSnapshots",
              "aws-marketplace:MeterUsage",
              "ec2:DescribeRouteTables",
              "ec2:DescribeAddresses",
              "ec2:DescribeTags",
              "ec2:DescribeInstances",
              "ec2:ModifyNetworkInterfaceAttribute",
              "ec2:ReplaceRoute",
              "ec2:CreateRoute",
              "ec2:DeleteRoute",
              "ec2:AssociateAddress",
              "ec2:DisassociateAddress",
              "s3:CreateBucket",
              "s3:Delete*",
              "s3:Get*",
              "s3:List*",
              "s3:Put*"
          ],
          "Resource": [
              "*"
          ]
      }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "softnas_profile" {
  name = "SoftNAS_HA_IAM"
  role = "${aws_iam_role.softnas_role.name}"
}

# output "softnas_role_id" {
#   value = "${aws_cloudformation_stack.SoftNASRole.outputs["SoftnasRoleID"]}"
# }

# output "softnas_role_arn" {
#   value = "${aws_cloudformation_stack.SoftNASRole.outputs["SoftnasARN"]}"
# }

# output "softnas_role_name" {
#   value = "${aws_cloudformation_stack.SoftNASRole.outputs["SoftNasRoleName"]}"
# }

#softnas provides no ability to query the ami you will need by region.  it must be added to the map manually.
variable "ami_platinum_consumption_lower_compute" {
  type = "map"

  default = {
    ap-southeast-2 = "ami-a24a98c0"
  }
}

variable "instance_type_platinum_consumption_lower_compute" {
  type = "map"

  default = {
    "m4.xlarge" = "m4.xlarge"
  }
}

variable "ami_platinum_consumption_higher_compute" {
  type = "map"

  default = {
    "ap-southeast-2" = "ami-5e7ea03c"
  }
}

variable "instance_type_platinum_consumption_higher_compute" {
  type = "map"

  default = {
    "m5.2xlarge" = "m5.2xlarge"
  }
}

resource "random_uuid" "test" {}

resource "aws_security_group" "softnas" {
  name        = "softnas"
  vpc_id      = "${var.vpc_id}"
  description = "SoftNAS security group"

  tags {
    Name = "softnas"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "all incoming traffic from remote vpn"
  }
  ingress {
    protocol    = "udp"
    from_port   = 49152
    to_port     = 65535
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = ""
  }
  ingress {
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "DNS"
  }
  ingress {
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "DNS"
  }


  ingress {
    protocol    = "tcp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "NFS"
  }
  ingress {
    protocol    = "udp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "NFS"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "rquotad, nlockmgr, mountd, status"
  }
  ingress {
    protocol    = "udp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "rquotad, nlockmgr, mountd, status"
  }
  ingress {
    protocol    = "udp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "rquotad, nlockmgr, mountd, status"
  }
  ingress {
    protocol    = "udp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "rquotad, nlockmgr, mountd, status"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "rquotad, nlockmgr, mountd, status"
  }
  ingress {
    protocol    = "udp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "rquotad, nlockmgr, mountd, status"
  }
  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "icmp"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" , "${var.public_subnets_cidr_blocks[0]}"]
    description = "ssh"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [ "${var.remote_subnet_cidr}", "${var.private_subnets_cidr_blocks}" ]
    description = "https"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}

resource "aws_network_interface" "nas1eth0" {
  subnet_id   = "${var.private_subnets[0]}"
  private_ips = ["${var.softnas1_private_ip1}"]
  security_groups = ["${aws_security_group.softnas.id}"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface" "nas1eth1" {
  subnet_id   = "${var.private_subnets[0]}"
  private_ips = ["${var.softnas1_private_ip2}"]
  security_groups = ["${aws_security_group.softnas.id}"]

  tags = {
    Name = "secondary_network_interface"
  }
}

resource "aws_instance" "softnas1" {
  ami = "${var.ami_platinum_consumption_lower_compute["ap-southeast-2"]}"
  instance_type = "${var.instance_type_platinum_consumption_lower_compute["m4.xlarge"]}"

  ebs_optimized = true

  iam_instance_profile = "${aws_iam_instance_profile.softnas_profile.name}"

  network_interface = {
    device_index = 0
    network_interface_id = "${aws_network_interface.nas1eth0.id}"
    #delete_on_termination = true
  }

  network_interface = {
    device_index = 1
    network_interface_id = "${aws_network_interface.nas1eth1.id}"
    #delete_on_termination = true
  }

  root_block_device {
    volume_size = "30"
    volume_type = "gp2"
    #device_name = "/dev/sda1"
    delete_on_termination = true
    # if specifying a snapshot, do not specify encryption.
    #encryption = false
  }

  key_name               = "${var.key_name}"
  #subnet_id              = "${var.private_subnets[0]}"
  #vpc_security_group_ids = ["${aws_security_group.node_centos.id}"]

  tags {
    Name = "SoftNAS1_PlatinumConsumptionLowerCompute"
  }
}

# resource "aws_cloudformation_stack" "SoftNAS1Stack" {
#   depends_on = ["aws_cloudformation_stack.SoftNASRole"]

#   name               = "SoftNAS1-${random_uuid.test.result}"
#   capabilities       = ["CAPABILITY_IAM"]
#   timeout_in_minutes = "60"

#   parameters = {
#     SoftnasRoleName     = "SoftNAS_HA_IAM"
#     KeyName             = "${var.key_name}"
#     SoftnasUserPassword = "${var.softnas_user_password}"
#     InstanceName        = "SoftNAS1_PlatinumConsumptionLowerCompute"
#     AMI                 = "${var.ami_platinum_consumption_lower_compute["ap-southeast-2"]}"
#     NasType             = "${var.instance_type_platinum_consumption_lower_compute["m4.xlarge"]}"
#     PrivateIPEth0NAS1   = "${var.softnas1_private_ip1}"
#     PrivateIPEth1NAS1   = "${var.softnas1_private_ip2}"

#     #security groups will open access to some public facing instances via their private ips. 
#     #1st is the vpn
#     ADBastion1PrivateIP = "${var.vpn_private_ip}"

#     #2nd is likely some other bastion / gateway that you will use to access the softnas instance.  This provides an alternative if there are issues with the vpn.
#     ADBastion2PrivateIP = "${var.bastion_private_ip}"
#     PrivateSubnet1CIDR  = "${var.private_subnets_cidr_blocks[0]}"
#     VPCID               = "${var.vpc_id}"
#     VPNCIDR             = "${var.vpn_cidr}"
#     PrivateSubnet1ID    = "${var.private_subnets[0]}"
#     PrivateSubnet2CIDR  = "${var.private_subnets_cidr_blocks[1]}"
#     PrivateSubnet2ID    = "${var.private_subnets[1]}"
#     PublicSubnet1CIDR   = "${var.public_subnets_cidr_blocks[0]}"
#     PublicSubnet2CIDR   = "${var.public_subnets_cidr_blocks[1]}"

#     SoftnasExportPath = "${var.softnas1_export_path}"
#   }

#   template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-1az.json"
# }

# output "softnas1_instanceid" {
#   value = "${aws_cloudformation_stack.SoftNAS1Stack.outputs["InstanceID"]}"
# }

# output "softnas1_private_ip" {
#   value = "${aws_cloudformation_stack.SoftNAS1Stack.outputs["InstanceIP"]}"
# }

# Attach existing ebs volumes to the softnas instance.  if a volume has been initialised previously, it will be detected by softnas.
# we iterate over the volumes and mounts to attach them to the softnas instance 

# resource "aws_volume_attachment" "softnas1_ebs_att" {
#   count       = "${length(var.softnas1_volumes)}"
#   device_name = "${element(var.softnas1_mounts, count.index)}"
#   volume_id   = "${element(var.softnas1_volumes, count.index)}"
#   instance_id = "${aws_cloudformation_stack.SoftNAS1Stack.outputs["InstanceID"]}"
# }

# resource "aws_cloudformation_stack" "SoftNAS2Stack" {
#   depends_on = ["aws_cloudformation_stack.SoftNASRole"]

#   name               = "SoftNAS2-${random_uuid.test.result}"
#   capabilities       = ["CAPABILITY_IAM"]
#   timeout_in_minutes = "60"

#   parameters = {
#     SoftnasRoleName     = "SoftNAS_HA_IAM"
#     KeyName             = "${var.key_name}"
#     SoftnasUserPassword = "${var.softnas_user_password}"
#     InstanceName        = "SoftNAS2_PlatinumConsumptionLowerCompute"
#     AMI                 = "${var.ami_platinum_consumption_lower_compute["ap-southeast-2"]}"
#     NasType             = "${var.instance_type_platinum_consumption_lower_compute["m4.xlarge"]}"
#     PrivateIPEth0NAS1   = "${var.softnas2_private_ip1}"
#     PrivateIPEth1NAS1   = "${var.softnas2_private_ip2}"

#     #security groups will open access to some public facing instances via their private ips. 
#     #1st is the vpn
#     ADBastion1PrivateIP = "${var.vpn_private_ip}"

#     #2nd is likely some other bastion / gateway that you will use to access the softnas instance.  This provides an alternative if there are issues with the vpn.
#     ADBastion2PrivateIP = "${var.bastion_private_ip}"
#     PrivateSubnet1CIDR  = "${var.private_subnets_cidr_blocks[0]}"
#     VPCID               = "${var.vpc_id}"
#     VPNCIDR             = "${var.vpn_cidr}"
#     PrivateSubnet1ID    = "${var.private_subnets[0]}"
#     PrivateSubnet2CIDR  = "${var.private_subnets_cidr_blocks[1]}"
#     PrivateSubnet2ID    = "${var.private_subnets[1]}"
#     PublicSubnet1CIDR   = "${var.public_subnets_cidr_blocks[0]}"
#     PublicSubnet2CIDR   = "${var.public_subnets_cidr_blocks[1]}"

#     SoftnasExportPath = "${var.softnas2_export_path}"
#   }

#   template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-1az.json"
# }

# output "softnas2_instanceid" {
#   value = "${aws_cloudformation_stack.SoftNAS2Stack.outputs["InstanceID"]}"
# }

# output "softnas2_private_ip" {
#   value = "${aws_cloudformation_stack.SoftNAS2Stack.outputs["InstanceIP"]}"
# }

# resource "aws_volume_attachment" "softnas2_ebs_att" {
#   count       = "${length(var.softnas2_volumes)}"
#   device_name = "${element(var.softnas2_mounts, count.index)}"
#   volume_id   = "${element(var.softnas2_volumes, count.index)}"
#   instance_id = "${aws_cloudformation_stack.SoftNAS2Stack.outputs["InstanceID"]}"
# }

# todo : need to report success at correct time after it has started.  see email from steven melnikov at softnas to check how to do this.

# we need to append data to the end of /etc/export.  since the instance is inside a private subnet, a vpn connection must be active prior to configuration
# this wont work until a vpn can be started by terraform.  currently, this code exists in the cloudformation template.
# ansible may be a better way to do this.

#wakeup a node after sleep
# resource "null_resource" "start-node" {
#   count = "${var.sleep ? 0 : 1}"

#   provisioner "local-exec" {
#     command = "aws ec2 start-instances --instance-ids ${aws_instance.softnas1.id}"
#   }
# }

# resource "null_resource" shutdownsoftnas {
#   count = "${var.sleep ? 1 : 0}"

#   provisioner "local-exec" {
#     command = "aws ec2 stop-instances --instance-ids ${aws_instance.softnas1.id}"

#     command = <<EOT
#       aws ec2 stop-instances --instance-ids ${aws_instance.softnas1.id}
#   EOT
#   }
# }
