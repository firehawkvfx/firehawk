#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

ansible-playbook -i ../secrets/dev/inventory ansible/aws_cli_ec2_install.yaml -vv --extra-vars 'variable_host=workstation1 variable_user=deployuser aws_cli_root=true ansible_ssh_private_key_file=/secrets/keys/id_ssh_rsa_dev'