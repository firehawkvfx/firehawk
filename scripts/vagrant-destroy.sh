#!/usr/bin/env bash

$TF_VAR_firehawk_path/scripts/ci-set-vm-init.sh
vagrant destroy -f
rm -fr $TF_VAR_firehawk_path/firehawk/.terraform # terraform plugins should be initialised next terraform init

config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier) # ...Config Override path $config_override.

echo "config_override path- $config_override"

python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override "TF_VAR_vm_initialised=" "false"
python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override "TF_VAR_openfirehawkserver=" "auto"