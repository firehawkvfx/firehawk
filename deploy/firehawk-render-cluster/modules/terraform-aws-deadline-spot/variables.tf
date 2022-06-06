variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}
variable "common_tags_vaultvpc" {
  description = "Common tags for resources in the vault vpc / firehawk-main project."
  type        = map(string)
}
variable "common_tags_rendervpc" {
  description = "Common tags for resources in the render vpc / firehawk-render-cluster project."
  type        = map(string)
}
variable "node_centos_volume_size" {
  default = 20
}
variable "node_centos_volume_type" {
  default = "gp2"
}
variable "ami_commit_hash" {
  description = "The commit hash tagged for the ami"
  type        = string
}
variable "aws_key_name" {
  description = "The name of the AWS PEM key for access to the instance"
  type        = string
  default     = null
}
variable "bucket_extension_vault" {
  description = "The bucket extension where the terraform remote state resides"
  type        = string
}
variable "bucket_extension" {
  description = "The bucket extension where the software installers reside"
  type        = string
}
variable "deadlineuser_name" {
  description = "The deadline user name for render nodes and deadline DB"
  type        = string
  default     = "deadlineuser"
}
variable "deadline_db_instance_id" {
  description = "The instance ID running deadline DB.  When this changes it must be provisioned again."
  type        = string
}
variable "user_data" {
  description = "The user data for the render node"
  type        = string
  sensitive   = true
}
variable "rendervpc_id" {
  description = "The ID of the render VPC to deploy into."
  type        = string
  default     = null
}
