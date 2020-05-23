#!/bin/bash

ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-init.yaml -vvv --extra-vars "skip_packages=false"