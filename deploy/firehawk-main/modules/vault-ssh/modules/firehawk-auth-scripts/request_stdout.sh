#!/bin/bash
# This script aquires needed vpn client files from vault to an intermediary bastion

set -e

source_vault_path="$1"
token="$2"

# curl --header "X-Vault-Token: $VAULT_TOKEN" https://vault.service.consul:8200/v1/$source_vault_path/file

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

  for i in $(seq 1 30); do
    log "$description"

    # The boolean operations with the exit status are there to temporarily circumvent the "set -e" at the
    # beginning of this script which exits the script immediatelly for error status while not losing the exit status code
    output=$(eval "$cmd") && exit_status=0 || exit_status=$?
    errors=$(echo "$output") | grep '^{' | jq -r .errors

    # log "$output" # uncomment this to make the response visible.  Not recommended for sensitive values.

    if [[ $exit_status -eq 0 && -n "$output" && -z "$errors" ]]; then
      echo "$output"
      return
    fi
    log "$description failed. Will sleep for 10 seconds and try again."
    sleep 10
  done;

  log "$description failed after 30 attempts."
  exit $exit_status
}

# And use the token to perform operations on vault such as reading a secret
# These is being retried because race conditions were causing this to come up null sometimes
log "Get secret from vault for stdout"
response=$(retry \
  "curl --fail -H 'X-Vault-Token: $token' -X GET https://vault.service.consul:8200/v1/$source_vault_path" \
  "Trying to read secret from vault")

echo "$response"