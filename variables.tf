variable "sleep" {
  default = false
}

# the time zone info path for the intended node
variable "time_zone_info_path_linux" {
  type = "map"

  default = {
    Australia_Sydney = "/usr/share/zoneinfo/Australia/Sydney"
  }
}
