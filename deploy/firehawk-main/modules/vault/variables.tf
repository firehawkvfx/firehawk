# ENV VARS
# These secrets are defined as environment variables, or if running on an aws instance they do not need to be provided (they are provided by the instance role automatically instead)

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_DEFAULT_REGION # this cen be set with:
# export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/'); echo $AWS_DEFAULT_REGION

variable "sleep" {
  description = "Sleep will disable the nat gateway and shutdown instances to save cost during idle time."
  type        = bool
  default     = false
}

variable "bucket_extension" {
  description = "# The extension for cloud storage used to label your S3 storage buckets. This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html"
  type = string
  default = null
}
variable "bucket_extension_vault" {
    description = "The bucket extension where the terraform remote state resides for vault related resources"
    type = string
}

variable "aws_private_key_path" {
  description = "The private key path for the key used to ssh into the bastion for provisioning"
  type = string
  default = ""
}

variable "vault_public_key" {
  description = "The public key of the host used to ssh into the vault cluster"
  type = string
  default = ""
}

variable "vault_consul_ami_id" {
  description = "The ID of the AMI to run in the vault cluster. This should be an AMI built from the Packer template under examples/vault-consul-ami/vault-consul.json. If no AMI is specified, the template will 'just work' by using the example public AMIs. WARNING! Do not use the example AMIs in a production setting!"
  type        = string
  # default     = null
}

variable "vpc_id_main_provisioner" {
  description = "The VPC ID containing the cloud9 seed instance in your main account.  This will be used to establish VPC peering with vault."
  type = string
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

variable "conflictkey" {
    description = "The conflictkey is a unique name for each deployement usuallly consisting of the resourcetier and the pipeid."
    type = string
}

variable "consul_cluster_name" {
  description = "What to name the Consul server cluster and all of its associated resources"
  type        = string
  # default     = "consul-example"
}

variable "consul_cluster_tag_key" {
  description = "The tag the Consul EC2 Instances will look for to automatically discover each other and form a cluster."
  type        = string
  # default     = "consul-servers"
}

variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}

variable "aws_key_name" {
  description = "The name of the AWS PEM key for access to the instance"
  type        = string
}