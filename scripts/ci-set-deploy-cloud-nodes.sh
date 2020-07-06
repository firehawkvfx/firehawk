#!/bin/bash

to_abs_path() {
  python -c "import os; print os.path.abspath('$1')"
}

config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier) # ...Config Override path $config_override.
echo "config_override path- $config_override"
sed -i 's/^allow_interrupt=.*$/allow_interrupt=true/' $config_override # destroy before deploy
sed -i 's/^TF_VAR_enable_vpc=.*$/TF_VAR_enable_vpc=true/' $config_override # ...Enable the vpc.
sed -i 's/^TF_VAR_softnas_storage=.*$/TF_VAR_softnas_storage=true/' $config_override # ...On first apply, don't create softnas instance until vpn is working.
sed -i 's/^TF_VAR_aws_nodes_enabled=.*$/TF_VAR_aws_nodes_enabled=true/' $config_override # ...Site mounts will not be mounted in cloud.  currently this will disable provisioning any render node or remote workstation until vpn is confirmed to function after this step.

# Alter the config file directly for these tests.  Revert to defaults in config.  config override will not disable if the var is set to itself
sed -i 's/^TF_VAR_houdini_license_server_address=.*$/TF_VAR_houdini_license_server_address=$TF_VAR_houdini_license_server_address/' $config_override # inherit default
sed -i 's/^TF_VAR_localnas1_private_ip=.*$/TF_VAR_localnas1_private_ip=$TF_VAR_localnas1_private_ip/' $config_override # inherit default
sed -i 's/^TF_VAR_localnas1_path_abs=.*$/TF_VAR_localnas1_path_abs=$TF_VAR_localnas1_path_abs/' $config_override # inherit default
sed -i 's/^TF_VAR_localnas1_export_path=.*$/TF_VAR_localnas1_export_path=$TF_VAR_localnas1_export_path/' $config_override # inherit default
sed -i 's/^TF_VAR_localnas1_volume_name=.*$/TF_VAR_localnas1_volume_name=$TF_VAR_localnas1_volume_name/' $config_override # inherit default

sed -i 's/^TF_VAR_remote_mounts_on_local=.*$/TF_VAR_remote_mounts_on_local=true/' $config_override # ...Softnas nfs exports will not be mounted on local site
sed -i 's/^TF_VAR_provision_deadline_spot_plugin=.*$/TF_VAR_provision_deadline_spot_plugin=true/' $config_override # Don't provision the deadline spot plugin for this stage
sed -i 's/^TF_VAR_install_houdini=.*$/TF_VAR_install_houdini=true/' $config_override # install houdini
sed -i 's/^TF_VAR_install_deadline_db=.*$/TF_VAR_install_deadline_db=true/' $config_override # install deadline
sed -i 's/^TF_VAR_install_deadline_rcs=.*$/TF_VAR_install_deadline_rcs=true/' $config_override # install deadline
sed -i 's/^TF_VAR_install_deadline_worker=.*$/TF_VAR_install_deadline_worker=true/' $config_override # install deadline
sed -i 's/^TF_VAR_workstation_enabled=.*$/TF_VAR_workstation_enabled=false/' $config_override # install deadline
sed -i 's/^TF_VAR_tf_destroy_before_deploy=.*$/TF_VAR_tf_destroy_before_deploy=false/' $config_override # destroy before deploy
# sed -i 's/^TF_VAR_taint_single=.*$/TF_VAR_taint_single=(module.node.null_resource.install_deadline_db[0])/' $config_override # taint
sed -i 's/^TF_VAR_taint_single=.*$/TF_VAR_taint_single=()/' $config_override # taint
