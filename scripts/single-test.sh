#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

ansible-playbook -i ../secrets/dev/inventory ansible/newuser_sshuser.yaml -vvvv --extra-vars 'variable_host=workstation1 user_inituser_name=user ansible_ssh_private_key_file=/secrets/keys/id_ssh_rsa_dev'