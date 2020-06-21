#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

ansible-playbook ansible/inventory-add.yaml -v --extra-vars "variable_host=localhost" --tags 'init'