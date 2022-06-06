# This module will initialise vault values to a default if not already present.  If the value already mathes an existing default, and the new default changes, it will also be updated.
# This allows us to know if a user has configured to a non default value, and if so, preserve the users value.

locals {
  path = "${var.mount_path}/${var.secret_name}"
}

resource "null_resource" "init_secret" { # init a secret if empty
  triggers = {
    always_run = timestamp() # Always run this since we dont know if this is a new vault and an old state file.  This could be better.  perhaps track an init var in the vault?
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
echo "Init secret after 1 second"
sleep 1
result="$(vault kv put -cas=0 "${local.path}" value="" 2>&1)" # capture stderr in output as well
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
  echo "Initialised new value"
elif [[ $exit_code -eq 2 ]]; then
  echo "Value is already initialised. exit code: $exit_code"
else
  echo "Error: non-zero exit code: $exit_code"
  echo "$result"
  exit 1
fi
EOT
  }
}