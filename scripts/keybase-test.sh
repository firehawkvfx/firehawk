#!/bin/bash
keybase login
ansible-playbook -i "$TF_VAR_inventory" ansible/pgp-decrypt-test.yaml