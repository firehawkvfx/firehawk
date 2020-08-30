#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

source ./update_vars.sh --var-file config --force -v
# ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/fsx/fsx_volume_mounts.yaml -v --extra-vars "fsx_ip=fsx.grey.openfirehawk.com" --skip-tags "local_install local_install_onsite_mounts" --tags "cloud_install"