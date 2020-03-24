# EBS volumes may be attached to softnas on launch.  these are their id's.
# These should be propogated into user's secrets as environment var's, but haven't been able to define lists as env vars yet with success.
variable "softnas1_volumes_dev" {
  default = []
  #["vol-0f4c6e1ef0d090d92", "vol-051869f6d24c2a57f", "vol-01f33494fa08ff802", "vol-033db088f1b4f35f3"]
}

variable "softnas1_volumes_prod" {
  default = []
}

variable "softnas1_mounts_dev" {
  default = ["/dev/sdf", "/dev/sdg", "/dev/sdh", "/dev/sdi"]
}

variable "softnas1_mounts_prod" {
  default = []
}

variable "envtier" {
}

locals {
  softnas1_volumes = [split(
    ",",
    var.envtier == "dev" ? join(",", var.softnas1_volumes_dev) : join(",", var.softnas1_volumes_prod),
  )]
  softnas1_mounts = [split(
    ",",
    var.envtier == "dev" ? join(",", var.softnas1_mounts_dev) : join(",", var.softnas1_mounts_prod),
  )]
}

