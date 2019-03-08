variable "name" {}

variable "vpc_id" {}

#example vpc_cidr "10.0.0.0/16"
variable "vpc_cidr" {}

# remote_ip_cidr is the ip address of the remote host / user intending to connect over vpn. eg '197.125.62.53/32'
#example "125.254.24.255/32"
variable "remote_ip_cidr" {}

variable "remote_subnet_cidr" {}

# examples ["subnet-0a7554f56af4d6d0a", "subnet-0257c7f8b1d68b6e4"]
variable "public_subnet_ids" {
  default = []
}

variable "private_subnet_ids" {
  default = []
}

variable "private_subnets_cidr_blocks" {
  default = []
}

variable "key_name" {
  default = "my_key_pair"
}

#contents of the my_key_pair.pem file to connect to the instance.
variable "private_key" {}

#CentOS Linux 7 x86_64 HVM EBS ENA 1805_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-77ec9308.4 (ami-d8c21dba)
variable "ami_map" {
  type = "map"

  default = {
    ap-southeast-2 = "ami-d8c21dba"
  }
}

variable "instance_type" {
  default = "t2.micro"
}

variable "user" {
  default = "centos"
}

variable "sleep" {
  default = false
}

variable "skip_update" {
  default = true
}

variable "vpn_cidr" {}

variable "region" {}

variable "local_key_path" {}

# You may wish to use a custom ami that incorporates your own configuration.  Insert the ami details below if you wish to use this.
variable "use_custom_ami" {
  default = false
}

variable "custom_ami" {
  default = ""
}

# variable "deadline_user" {
#   default = "deadlineuser"
# }

# variable "deadline_prefix" {}
# variable "deadline_user_password" {}

# variable "deadline_user_uid" {}

# variable "deadline_samba_server_hostname" {}

# variable "deadline_certificates_location" {
#   default = "/opt/Thinkbox/certs"
# }

# variable "deadline_installers_filename" {
#   default = "DeadlineClient-10.0.23.4-linux-x64-installer.run"
# }

# variable "houdini_installer_filename" {
#   default = "houdini-17.0.459-linux_x86_64_gcc6.3.tar"
# }

# variable "deadline_client_certificate" {
#   default = "/opt/Thinkbox/DeadlineDatabase10/certs/Deadline10Client.pfx"
# }

# variable "deadline_server_certificate" {
#   default = "/opt/Thinkbox/certs/deadlinedb.firehawkvfx.com.pfx"
# }

# variable "deadline_db_ssl_password" {
#   default = "@WhatTime"
# }

# variable "deadline_proxy_certificate_password" {
#   default = "@WhatTime"
# }

# variable "deadline_ca_certificate" {
#   default = "/opt/Thinkbox/certs/ca.crt"
# }

# variable "deadline_proxy_certificate" {
#   default = "/opt/Thinkbox/certs/Deadline10RemoteClient.pfx"
# }

# variable "deadline_proxy_root_dir" {
#   default = "192.168.92.184:4433"
# }

# variable "deadline_samba_server_address" {
#   default = "192.168.92.10"
# }

variable "houdini_license_server_address" {}

variable "softnas_private_ip1" {
  default = "10.0.1.11"
}

variable "softnas_private_ip2" {
  default = "10.0.1.12"
}

variable "softnas_export_path" {
  default = "/naspool2/nasvol2"
}

variable "softnas_mount_path" {
  default = "/mnt/softnas/nasvol2"
}
