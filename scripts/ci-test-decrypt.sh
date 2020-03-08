#!/bin/bash
# This script should be executed from the firehawk folder
. ./scripts/exit_test.sh
echo "testsecret $testsecret"
echo "vault_id $vault_key"
result=$(./scripts/ansible-encrypt.sh --vault-id $vault_key --decrypt $testsecret)
echo $result
if [[ "$result" != "this is a test secret" ]]; then exit 1; fi
if [[ -z "$firehawksecret" ]]; then echo "Warning: no defined firehawksecret"; exit 1; fi