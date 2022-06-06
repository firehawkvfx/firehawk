variable "resourcetier" {
  description = "The resource tier eg: green, blue, grey"
  type        = string
}

variable "secret_name" {
  description = "The name of the data in the path"
  type        = string
}

variable "system_default" {
  description = "The map defining the system defaults for the secret"
  type        = map(string)
}

variable "mount_path" {
  description = "The mount path in vault"
  type        = string
}

variable "restore_defaults" {
  description = "If true, will reset all values to system defaults"
  type        = bool
  default     = false
}