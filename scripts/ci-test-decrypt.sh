#!/bin/bash
# This script should be executed from the firehawk folder
. ./scripts/exit_test.sh
echo "testsecret $testsecret"; exit_test
echo "vault_id $vault_key"; exit_test

testsecret=$(echo 'this is a test secret' | ./scripts/ansible-encrypt.sh --vault-id $vault_key --encrypt)
result=$(./scripts/ansible-encrypt.sh --vault-id $vault_key --decrypt $testsecret); exit_test
echo $result; exit_test
if [[ "$result" != "this is a test secret" ]]; then exit 1; fi; exit_test
if [[ -z "$firehawksecret" ]]; then echo "Warning: no defined firehawksecret"; exit 1; fi; exit_test