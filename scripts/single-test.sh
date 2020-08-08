#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

ansible-playbook -i ../secrets/dev/inventory ansible/ansible_collections/firehawkvfx/fsx/fsx_volume_mounts.yaml -vvv --extra-vars fsx_ip=10.1.1.248 --skip-tags 'local_install local_install_onsite_mounts' --tags cloud_install
