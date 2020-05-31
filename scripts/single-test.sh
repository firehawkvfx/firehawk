#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

ansible-playbook -i ../secrets/dev/inventory ansible/ansible_collections/firehawkvfx/houdini/houdini_module.yaml -v --extra-vars 'variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser' --tags install_deadline_db --skip-tags sync_scripts