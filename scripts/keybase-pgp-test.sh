#!/bin/bash
if [[ "$TF_VAR_pgp_public_key"=="keybase:*" ]]; then
    keybase login
fi
ansible-playbook -i "$TF_VAR_inventory" ansible/pgp-decrypt-test.yaml