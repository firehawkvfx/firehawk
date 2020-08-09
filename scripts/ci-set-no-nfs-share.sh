#!/bin/bash

to_abs_path() {
  python -c "import os; print os.path.abspath('$1')"
}

# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override "TF_VAR_CI_JOB_ID=" "${CI_JOB_ID}"

config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier) # ...Config Override path $config_override.
echo "config_override path- $config_override"

python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'allow_interrupt=' 'true' # destroy before deploy

# Alter the config file directly for these tests.  Disable NAS and Houdini installs.
python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_localnas1_private_ip=' 'none' # remove the ip address of the nfs share to test
python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_localnas1_path_abs=' 'none' # remove the ip address
python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_localnas1_export_path=' 'none' # remove the ip address
python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_localnas1_volume_name=' 'none' # remove the ip address

python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_taint_single=' '' # taint vpn