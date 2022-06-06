variable "aws_key_name" {
  type = string
  default = null
}

variable "bastion_ami_id" {
  description = "The prebuilt AMI for the bastion host. This should be a private ami you have built with packer."
  type = string
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
    description = "The resource tier speicifies a unique name for a resource based on the environment.  eg:  dev, green, blue, main."
    type = string
}

variable "pipelineid" {
    description = "The pipelineid variable can be used to uniquely specify and identify resource names for a given deployment.  The pipeline ID could be set to a job ID in CI software for example.  The default of 0 is fine if no more than one concurrent deployment run will occur."
    type = string
    default = "0"
}

variable "route_public_domain_name" {
  description = "Defines if a public DNS name is to be used"
  type        = bool
  default     = false
}

variable "remote_cloud_public_ip_cidr" {
  description = "The remote cloud IP public address that will access the bastion (cloud 9)"
  type = string
}

variable "remote_cloud_private_ip_cidr" {
  description = "The remote cloud private IP address that will access the bastion (cloud 9)"
  type = string
}

variable "aws_internal_domain" {
  description = "The domain used to resolve FQDN hostnames."
  type        = string
}

variable "aws_external_domain" {
  description = "The domain used to resolve external FQDN hostnames.  Since we always provide the CA for externals connections, the default for public ec2 instances is acceptable, but in production it is best configure it with your own domain."
  type        = string
}

variable "consul_cluster_name" {
  description = "What to name the Consul server cluster and all of its associated resources"
  type        = string
}
variable "consul_cluster_tag_key" {
  description = "The tag the Consul EC2 Instances will look for to automatically discover each other and form a cluster."
  type        = string
}
variable "onsite_public_ip" {
  description = "The public ip address of your onsite location to enable access to security groups and openVPN."
  type = string
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