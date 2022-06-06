variable "consul_cluster_name" {
  description = "What to name the Consul server cluster and all of its associated resources"
  type        = string
}
variable "consul_cluster_tag_key" {
  description = "The tag the Consul EC2 Instances will look for to automatically discover each other and form a cluster."
  type        = string
}
variable "aws_internal_domain" {
  description = "The domain used to resolve internal FQDN hostnames."
  type        = string
}
variable "deadline_version" {
  description = "The deadline version to install"
  type        = string
}
variable "common_tags" {
  description = "A map of common tags to assign to the resources created by this module"
  type        = map(string)
  default     = {}
}
variable "bucket_extension" {
  description = "The bucket extension where the software installers reside"
  type        = string
}
variable "fsx_enabled" {
  description = "Whether FSX is enabled or not."
  type = bool
  default = false
}
variable "fsx_private_ip" {
  description = "The IP address of the FSX primary interface to mount to render nodes"
  type        = string
  default     = ""
}
variable "fsx_dns_name" {
  description = "The DNS name required to mount the FSX volume"
  type        = string
  default     = ""
}
variable "fsx_mount_name" {
  description = "The mount name required to mount the FSX volume"
  type        = string
  default     = ""
}
variable "nfs_cloud_file_gateway_enabled" {
  description = "Whether the NFS share from the S3 File gateway is enabled or not"
  type = bool
  default = false
}
variable "nfs_cloud_file_gateway_private_ip" {
  description = "The private IP address of the NFS share."
  type = string
  default = null
}
variable "nfs_cloud_file_gateway_share_path" {
  description = "The NFS export path from the file gateway"
  type = string
  default = null
}