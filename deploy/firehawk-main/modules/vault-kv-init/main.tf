resource "vault_mount" "resourcetier" {
  path        = var.resourcetier
  type        = "kv-v2"
  description = "KV2 Secrets Engine for dev."
}

locals {
  var_map = {
    "dev" : local.dev,
    "blue" : local.blue,
    "green" : local.green,
    "main" : local.main
  }
  active_values = local.var_map[var.resourcetier]
}

module "init-values" { # Init defaults
  source = "./modules/init-values"

  for_each       = local.active_values
  secret_name    = each.key
  system_default = each.value

  resourcetier     = var.resourcetier # dev, green, blue, or main
  mount_path       = var.resourcetier
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}