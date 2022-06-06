#!/bin/bash
# This script aquires needed vpn client files from vault to an intermediary bastion

set -e

if [[ -z "$1" ]]; then
  echo "Error: Arg dev/green/blue/main must be provided."
  exit 1
fi

source_file_path="$1"
source_vault_path="$2"
attempts=1

# Log the given message. All logs are written to stderr with a timestamp.
function log {
 local -r message="$1"
 local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
 >&2 echo -e "$timestamp $message"
}

# A retry function that attempts to run a command a number of times and returns the output
function retry {
  local -r cmd="$1"
  local -r description="$2"

  for i in $(seq 1 $attempts); do
    log "$description"

    # The boolean operations with the exit status are there to temporarily circumvent the "set -e" at the
    # beginning of this script which exits the script immediatelly for error status while not losing the exit status code
    output=$(eval "$cmd") && exit_status=0 || exit_status=$?
    errors=$(echo "$output") | grep '^{' | jq -r .errors

    # log "$output" # uncomment this to make the response visible.  Not recommended for sensitive values.

    if [[ $exit_status -eq 0 && -z "$errors" ]]; then
      echo "$output"
      return
    fi
    log "$description failed. Will sleep for 10 seconds and try again."
    sleep 10
  done;

  log "$description failed after 30 attempts."
  exit $exit_status
}
# export VAULT_TOKEN=${vault_token}
export VAULT_ADDR=https://vault.service.consul:8200


echo "Aquiring vault data..."

# # Retrieve previously generated secrets from Vault.  Would be better if we can use vault as an intermediary to generate certs.
# retrieve_json_blob "/usr/local/openvpn_as/scripts/seperate/client.ovpn" "$HOME/tmp/usr/local/openvpn_as/scripts/seperate/client.ovpn"

function retrieve_file {
  local -r source_path="$1"
  if [[ -z "$2" ]]; then
    local -r target_path="$source_path"
  else
    local -r target_path="$2"
  fi
  echo "Aquiring vault data... $source_path to $target_path"
  echo "Get secret from vault to file"
  response=$(retry \
  "curl --header 'X-Vault-Token: $VAULT_TOKEN' https://vault.service.consul:8200/v1/$source_path/file" \
  "Trying to read secret from vault")
  
  errors=$(echo "$response" | jq -r '.errors | length')
  if [[ ! $errors -eq 0 ]]; then
    echo "Vault request failed: $response"
    exit 1
  fi
  
  echo "retrieve_file mkdir: $(dirname $target_path)"
  mkdir -p "$(dirname $target_path)" # ensure the directory exists
  echo "Check file path is writable: $target_path"
  if test -f "$target_path"; then
    echo "File exists: ensuring it is writeable"
    chmod u+w "$target_path"
    touch "$target_path"
  else
    echo "Ensuring path is writeable"
    touch "$target_path"
    chmod u+w "$target_path"
  fi
  if [[ -f "$target_path" ]]; then
    chmod u+w "$target_path"
  else
    echo "Error: path does not exist, var may not be a file: $target_path "
  fi
  echo "Write file content: single operation"
  echo "$response" | jq -r '.data.data.value' | base64 --decode > $target_path
  if [[ ! -f "$target_path" ]] || [[ -z "$(cat $target_path)" ]]; then
    echo "Error: no file or empty result at $target_path"
    exit 1
  fi
  echo "Request Complete."
}

retrieve_file "$source_vault_path" "$HOME/tmp$source_file_path"