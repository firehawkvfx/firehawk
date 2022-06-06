variable "aws_key_name" {
  type = string
}

variable "vault_client_ami_id" {
  description = "The prebuilt AMI for the vault client host. This should be a private ami you have built with packer."
  type        = string
}

variable "sleep" {
  description = "Sleep will disable the nat gateway and shutdown instances to save cost during idle time."
  type        = bool
  default     = false
}

variable "environment" {
  description = "The environment.  eg: dev/prod"
  type        = string
}

variable "resourcetier" {
  description = "The resource tier uniquely defining the deployment area.  eg: dev/green/blue/main"
  type        = string
}
variable "pipelineid" {
  description = "The pipelineid uniquely defining the deployment instance if using CI.  eg: dev/green/blue/main"
  type        = string
}

# variable "route_public_domain_name" {
#   description = "Defines if a public DNS name is to be used"
#   type        = bool
#   default     = false
# }

variable "remote_cloud_public_ip_cidr" {
  description = "The remote cloud IP public address that will access the vault client (cloud 9)"
  type        = string
}

variable "remote_cloud_private_ip_cidr" {
  description = "The remote cloud private IP address that will access the vault client (cloud 9)"
  type        = string
}

variable "aws_internal_domain" {
  description = "The domain used to resolve FQDN hostnames."
  type        = string
}

variable "consul_cluster_tag_key" {
  description = "The tag the Consul EC2 Instances will look for to automatically discover each other and form a cluster."
  type        = string
}

variable "consul_cluster_name" {
  description = "What to name the Consul server cluster and all of its associated resources"
  type        = string
}

# variable "bastion_public_dns" {
#   description = "The bastion must exist in order to provide complete instructions to establish connection with this host, and also aquire the security group enabling ssh between both hosts."
#   type        = string
# }

variable "onsite_public_ip" {
  description = "The public ip address of your onsite location to enable access to security groups and openVPN."
  type = string
}

variable "vpn_cidr" {
  description = "The CIDR range that the vpn will assign using DHCP.  These are virtual addresses for routing traffic."
  type        = string
}

variable "onsite_private_subnet_cidr" {
  description = "The subnet CIDR Range of your onsite private subnet. This is also the subnet where your VPN client resides in. eg: 192.168.1.0/24"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}

variable "bucket_extension_vault" {
    description = "The bucket extension where the terraform remote state resides"
    type = string
}
variable "resourcetier_vault" {
    description = "The resourcetier the desired vault vpc resides in"
    type = string
}
variable "vpcname_vaultvpc" {
    description = "A namespace component defining the location of the terraform remote state"
    type = string
}