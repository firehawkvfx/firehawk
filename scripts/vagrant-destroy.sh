#!/usr/bin/env bash

$TF_VAR_firehawk_path/scripts/ci-set-vm-init.sh
vagrant destroy -f
rm -fr $TF_VAR_firehawk_path/firehawk/.terraform # terraform plugins should be initialised next terraform init