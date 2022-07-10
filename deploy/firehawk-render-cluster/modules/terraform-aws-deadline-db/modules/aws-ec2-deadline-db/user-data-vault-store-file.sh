#!/bin/bash

set -e
exec > >(tee -a /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# User Vars: Set by terraform template
resourcetier="${resourcetier}"
example_role_name="${example_role_name}"

# Script vars (implicit)
export VAULT_ADDR="https://vault.service.consul:8200"
client_cert_file_path="${client_cert_file_path}"
client_cert_vault_path="${client_cert_vault_path}"

# Functions
function log {
 local -r message="$1"
 local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
 >&2 echo -e "$timestamp $message"
}
function has_yum {
  [[ -n "$(command -v yum)" ]]
}
function has_apt_get {
  [[ -n "$(command -v apt-get)" ]]
}
# A retry function that attempts to run a command a number of times and returns the output
function retry {
  local -r cmd="$1"
  local -r description="$2"
  attempts=5

  for i in $(seq 1 $attempts); do
    log "$description"

    # The boolean operations with the exit status are there to temporarily circumvent the "set -e" at the
    # beginning of this script which exits the script immediatelly for error status while not losing the exit status code
    output=$(eval "$cmd") && exit_status=0 || exit_status=$?
    errors=$(echo "$output") | grep '^{' | jq -r .errors

    log "$output"

    if [[ $exit_status -eq 0 && -z "$errors" ]]; then
      echo "$output"
      return
    fi
    log "$description failed. Will sleep for 10 seconds and try again."
    sleep 10
  done;

  log "$description failed after $attempts attempts."
  exit $exit_status
}

### Vault Auth IAM Method CLI
retry \
  "vault login --no-print -method=aws header_value=vault.service.consul role=${example_role_name}" \
  "Waiting for Vault login"

# set -x
# if debugging the install script, it is possible to test without rebuilding image.
# rm -fr /var/tmp/firehawk-main
# cd /var/tmp; git clone --branch v0.0.47 https://github.com/firehawkvfx/firehawk-main.git
echo "...Store certificate with script." "$client_cert_file_path" "$client_cert_vault_path" "$resourcetier" "$VAULT_ADDR"
/var/tmp/firehawk-main/scripts/store_file.sh "$client_cert_file_path" "$client_cert_vault_path" "$resourcetier" "$VAULT_ADDR"

echo "Revoking vault token..."
vault token revoke -self
