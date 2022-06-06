#!/bin/bash

set -e
# set +o history

exec > >(tee -a /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

resourcetier="${resourcetier}"
deadlineuser_name="${deadlineuser_name}"
deadlineuser_pw="$(openssl rand -base64 12)"

usermod --password $(echo $deadlineuser_pw | openssl passwd -1 -stdin) $deadlineuser_name

export VAULT_ADDR=https://vault.service.consul:8200
### Vault Auth IAM Method CLI
retry \
  "vault login --no-print -method=aws header_value=vault.service.consul role=${example_role_name}" \
  "Waiting for Vault login"

vault kv put -address="$VAULT_ADDR" -format=json $resourcetier/users/deadlineuser_pw value="$deadlineuser_pw"

echo "Revoking vault token..."
vault token revoke -self