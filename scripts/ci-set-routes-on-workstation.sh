#!/bin/bash

to_abs_path() {
  python -c "import os; print os.path.abspath('$1')"
}

config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier) # ...Config Override path $config_override.
echo "config_override path- $config_override"
python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_set_routes_on_workstation=' 'true' # destroy before deploy