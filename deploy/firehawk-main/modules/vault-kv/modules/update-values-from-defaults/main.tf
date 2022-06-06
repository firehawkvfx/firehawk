# This module will initialise vault values to a default if not already present.  If the value already mathes an existing default, and the new default changes, it will also be updated.
# This allows us to know if a user has configured to a non default value, and if so, preserve the users value.

locals {
  path = "${var.mount_path}/${var.secret_name}"
}

data "vault_generic_secret" "vault_map" { # Get the map of data at the path
  count = 1
  path  = local.path
}

locals {
  system_default = var.system_default # The system default map will define the value if value is not present, or value matches a preexisting default.
  # If a present value is different to a present default, retain the vault value.  Else use the system default.
  # We could use the kv put -patch option with a write, but this could increment versions unnecersarily.
  vault_map    = length(data.vault_generic_secret.vault_map) > 0 ? data.vault_generic_secret.vault_map[0].data : null

  secret_value = contains(keys(local.vault_map), "value") && contains(keys(local.vault_map), "default") && lookup(local.vault_map, "value", "") != lookup(local.vault_map, "default", "") ? lookup(local.vault_map, "value", "") : local.system_default["default"]
  secret_map   = var.restore_defaults ? tomap({ "value" = local.system_default["default"] }) : tomap({ "value" = local.secret_value })
  result_map   = merge(local.system_default, local.secret_map)
}

resource "vault_generic_secret" "vault_map_output" {
  depends_on = [
    data.vault_generic_secret.vault_map
  ]
  count     = 1
  path      = local.path
  data_json = jsonencode(local.result_map)
}