#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"


ansible-playbook -i ../secrets/dev/inventory ansible/newuser_sshuser.yaml -v --extra-vars "variable_host=firehawkgateway user_inituser_name=deployuser user_inituser_pw='' ansible_ssh_private_key_file=/secrets/keys/firehawkgateway_private_key"
ansible-playbook -i ../secrets/dev/inventory ansible/ssh-add-public-host.yaml -v --extra-vars 'public_ip=54.253.227.162 public_address=54.253.227.162 bastion_address=54.253.227.162 set_bastion=true'

# ansible-playbook -i ../secrets/dev/inventory ansible/newuser_sshuser.yaml -vvvv --extra-vars 'variable_host=workstation1 user_inituser_name=user ansible_ssh_private_key_file=/secrets/keys/id_ssh_rsa_dev'