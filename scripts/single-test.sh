#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/linux_volume_mounts.yaml -vvv --extra-vars "variable_host=workstation1 variable_user=deployuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'