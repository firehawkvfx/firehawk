#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

ansible-playbook -i ansible/inventory/hosts ansible/init.yaml -v --extra-vars "variable_user=deployuser set_hostname=ansiblecontrol"
ansible-playbook -i "$TF_VAR_inventory" ansible/init.yaml -v --extra-vars "variable_host=firehawkgateway variable_user=deployuser configure_gateway=true set_hostname=firehawkgateway"