locals {
  var_map = {
    "dev" : local.dev,
    "blue" : local.blue,
    "green" : local.green,
    "main" : local.main
  }
  active_values = local.var_map[var.resourcetier]
}

module "update-values-from-defaults" { # Init defaults
  source           = "./modules/update-values-from-defaults"

  resourcetier     = var.resourcetier # dev, green, blue, or main
  mount_path       = var.resourcetier
  for_each         = local.active_values
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}

# Some values are pulled directly from parameters
data "aws_ssm_parameter" "onsite_private_vpn_ip" {
  name = "/firehawk/resourcetier/${var.resourcetier}/onsite_private_vpn_ip"
}

locals {
  onsite_private_vpn_ip = data.aws_ssm_parameter.onsite_private_vpn_ip.value
  set_values = tomap( 
  { 
    "vpn/onsite_private_vpn_ip": {
      "name": "onsite_private_vpn_ip",
      "description": "The onsite VPN Static IP",
      "value": local.onsite_private_vpn_ip,
      "default": local.onsite_private_vpn_ip,
      "example_1": "192.168.29.10"
    }
  }
  )
}

module "set-values-from-parameters" { # Init defaults
  source           = "./modules/set-values"

  mount_path       = var.resourcetier # dev, green, blue, or main
  for_each         = local.set_values
  secret_name      = each.key
  system_default   = each.value
}