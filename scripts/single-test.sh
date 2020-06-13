#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

ansible-playbook -i "$TF_VAR_inventory" ansible/init.yaml --extra-vars "variable_host=firehawkgateway variable_user=deployuser configure_gateway=true set_hostname=firehawkgateway"