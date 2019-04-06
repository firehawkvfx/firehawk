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

variable "instance_type" {
  type = "map"

  default = {
    low = "m4.xlarge",
    high = "m5.12xlarge"
  }
}

variable "softnas_mode" {
  default="low"
}

variable "aws_region" {}

locals {
  softnas_mode_ami = "${var.softnas_mode}_${var.aws_region}"
}

variable "selected_ami" {
  type = "map"

  default = {
    low_ap-southeast-2 = "ami-a24a98c0",
    high_ap-southeast-2 = "ami-5e7ea03c"
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
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.remote_subnet_cidr}", "10.0.0.0/16", "${var.public_subnets_cidr_blocks[0]}", "${var.vpn_cidr}"]
    description = "all incoming traffic"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.public_subnets_cidr_blocks[0]}", "${var.vpn_cidr}"]
    description = "DNS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.public_subnets_cidr_blocks[0]}", "${var.vpn_cidr}"]
    description = "DNS"
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.public_subnets_cidr_blocks[0]}", "${var.vpn_cidr}"]
    description = "icmp"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.public_subnets_cidr_blocks[0]}", "${var.vpn_cidr}"]
    description = "ssh"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.public_subnets_cidr_blocks[0]}", "${var.vpn_cidr}"]
    description = "https"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "all incoming traffic from remote vpn"
  }

  ingress {
    protocol    = "udp"
    from_port   = 49152
    to_port     = 65535
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = ""
  }

  ingress {
    protocol    = "tcp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "NFS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "NFS"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.vpn_cidr}"]
    description = "rquotad, nlockmgr, mountd, status"
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
  subnet_id       = "${var.private_subnets[0]}"
  private_ips     = ["${var.softnas1_private_ip1}"]
  security_groups = ["${aws_security_group.softnas.id}"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface" "nas1eth1" {
  subnet_id       = "${var.private_subnets[0]}"
  private_ips     = ["${var.softnas1_private_ip2}"]
  security_groups = ["${aws_security_group.softnas.id}"]

  tags = {
    Name = "secondary_network_interface"
  }
}

resource "aws_instance" "softnas1" {
  ami           = "${lookup(var.selected_ami, local.softnas_mode_ami)}"
 
  instance_type = "${lookup(var.instance_type, var.softnas_mode)}"

  ebs_optimized = true

  iam_instance_profile = "${aws_iam_instance_profile.softnas_profile.name}"

  network_interface = {
    device_index         = 0
    network_interface_id = "${aws_network_interface.nas1eth0.id}"

    #delete_on_termination = true
  }

  network_interface = {
    device_index         = 1
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

  key_name = "${var.key_name}"

  #subnet_id              = "${var.private_subnets[0]}"
  #vpc_security_group_ids = ["${aws_security_group.node_centos.id}"]

  #user_data = "${file("${path.module}/user_data.yml")}"
  user_data = <<USERDATA
#cloud-config
hostname: nas1.${var.public_domain}
fqdn: nas1.${var.public_domain}
manage_etc_hosts: false
USERDATA

  tags {
    Name  = "SoftNAS1_PlatinumConsumption${var.softnas_mode}Compute"
    Route = "private"
    Role  = "softnas"
  }
}

resource "null_resource" "provision_softnas" {
  depends_on = ["aws_instance.softnas1"]

  triggers {
    instanceid = "${ aws_instance.softnas1.id }"
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = "${aws_instance.softnas1.private_ip}"
      bastion_host        = "${var.bastion_ip}"
      private_key         = "${var.private_key}"
      bastion_private_key = "${var.private_key}"
      type                = "ssh"
      timeout             = "10m"
    }

    inline = ["sleep 10 && set -x && sudo yum install -y python"]
  }
  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      ansible-playbook -i ansible/inventory ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.softnas1.private_ip} bastion_ip=${var.bastion_ip}"
      ansible-playbook -i ansible/inventory ansible/softnas-init.yaml -v
      ansible-playbook -i ansible/inventory ansible/softnas-update.yaml -v
      #ansible-playbook -i ansible/inventory ansible/aws-cli.yaml -v --extra-vars "variable_user=centos variable_host=role_softnas"
      #ansible-playbook -i ansible/inventory ansible/aws-cli-ec2.yaml -v --extra-vars "variable_user=centos variable_host=role_softnas"
  EOT
  }
}

resource "random_id" "ami_unique_name" {
  keepers = {
    # Generate a new id each time we switch to a new instance id
    ami_id = "${aws_instance.softnas1.id}"
  }

  byte_length = 8
}

resource "aws_ami_from_instance" "softnas1" {
  depends_on         = ["null_resource.provision_softnas"]
  name               = "softnas1_${aws_instance.softnas1.id}_${random_id.ami_unique_name.hex}"
  source_instance_id = "${aws_instance.softnas1.id}"

  tags {
    Name = "softnas1_${aws_instance.softnas1.id}_${random_id.ami_unique_name.hex}"
  }
}

# Once an AMI is built above, then we test the connection to the instance via a bastion below.
# When connection to softnas is established, we know the instance has booted.  We continue to provision an s3 extender disk below.
# this creates an s3 bucket if it doesn't already exist.  if there is a bucket with the same disk_device number, same nas name, and same domain,
# then the existing bucket will be mounted instead and existing data wil be available.  you may need to login to the softnas web ui to import the existing pool and volume,
# but the disk should be mounted correctly.
# Domains can be used to differentiate dev environments from production.
# for example, dev.example.com vs prod.example.com are different namespaces for two different buckets with otherwise identical properties to coexist in the same aws account.
# if an existing bucket is detected, s3_disk_size_max_value and encrypt_s3 are overidden by the settings on the bucket, and commandline variables ignored.
# the s3 encryption password is stored in your encrypted vault in ansible/host_vars/all/vault

# IMPORTANT: if creating a new disk, the disk_device should be the next number available to the instance.
# eg if these are already moujnted, /dev/s3-0, /dev/s3-1, /dev/s3-2, then the disk_device for the next bucket should be "3".

output "softnas1_instanceid" {
  value = "${aws_instance.softnas1.id}"
}

output "softnas1_private_ip" {
  value = "${aws_instance.softnas1.private_ip}"
}
resource "null_resource" "provision_softnas_volumes" {
  depends_on = ["aws_ami_from_instance.softnas1"]

  triggers {
    instanceid = "${ aws_instance.softnas1.id }"
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = "${aws_instance.softnas1.private_ip}"
      bastion_host        = "${var.bastion_ip}"
      private_key         = "${var.private_key}"
      bastion_private_key = "${var.private_key}"
      type                = "ssh"
      timeout             = "10m"
    }

    inline = ["set -x && echo 'booted'"]
  }

  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      ansible-playbook -i ansible/inventory ansible/softnas-s3-disk.yaml -v --extra-vars "pool_name=pool0 volume_name=volume0 disk_device=0 s3_disk_size_max_value=${var.s3_disk_size} encrypt_s3=true"
  EOT
  }
}
output "provision_softnas_volumes" {
  value = "${null_resource.provision_softnas_volumes.id}"
}

# todo : need to report success at correct time after it has started.  see email from steven melnikov at softnas to check how to do this.

# wakeup a node after sleep
resource "null_resource" "start-softnas" {
  count = "${var.sleep ? 0 : 1}"

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_instance.softnas1.id}"
  }
}

resource "null_resource" "shutdown-softnas" {
  count = "${var.sleep ? 1 : 0}"

  provisioner "local-exec" {
    #command = "aws ec2 stop-instances --instance-ids ${aws_instance.softnas1.id}"

    command = <<EOT
      aws ec2 stop-instances --instance-ids ${aws_instance.softnas1.id}
  EOT
  }
}
