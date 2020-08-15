#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

ansible-playbook -i ../secrets/dev/inventory ansible/openvpn.yaml -vvvv --extra-vars 'vpn_address=52.63.218.41 private_ip=10.1.101.136 private_subnet1=10.1.1.0/24 public_subnet1=10.1.101.0/24 remote_subnet_cidr=192.168.92.0/24 client_network=172.17.232.0 client_netmask_bits=24'