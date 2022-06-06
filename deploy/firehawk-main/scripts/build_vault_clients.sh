#!/bin/bash

# Build all required amis.  see this for variations on parallelism https://stackoverflow.com/questions/3004811/how-do-you-run-multiple-programs-in-parallel-from-a-bash-script
set -e # Exit on error

# Raise error if var isn't defined.
if [[ -z "$TF_VAR_firehawk_path" ]]; then
    exit_if_error 1 "TF_VAR_firehawk_path not defined. You need to source ./update_vars.sh"
fi

$TF_VAR_firehawk_path/modules/terraform-aws-bastion/modules/bastion-ami/base-ami/build.sh &
P1=$!
$TF_VAR_firehawk_path/modules/terraform-aws-vault-client/modules/vault-client-ami/base-ami/build.sh &
P2=$!
$TF_VAR_firehawk_path/modules/terraform-aws-vpn/modules/openvpn-server-ami/base-ami/build.sh &
P3=$!

wait $P1 $P2 $P3
echo "...Build base AMI's complete."

$TF_VAR_firehawk_path/modules/terraform-aws-bastion/modules/bastion-ami/build.sh &
P1=$!
$TF_VAR_firehawk_path/modules/terraform-aws-vault-client/modules/vault-client-ami/build.sh &
P2=$!
$TF_VAR_firehawk_path/modules/terraform-aws-vpn/modules/openvpn-server-ami/build.sh &
P3=$!

wait $P1 $P2 $P3

echo "...Build complete.  When your Consul TLS certificates expire ($HOME/.ssh/tls/ca.crt.pem), these images will need to be rebuilt with new certificates."