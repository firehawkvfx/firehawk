#!/bin/bash

function to_abs_path {
    local target="$1"
    if [ "$target" == "." ]; then
        echo "$(pwd)"
    elif [ "$target" == ".." ]; then
        echo "$(dirname "$(pwd)")"
    else
        echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
}

config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier) # ...Config Override path $config_override.
echo "config_override path- $config_override"
sed -i 's/^allow_interrupt=.*$/allow_interrupt=true/' $config_override # destroy before deploy
sed -i 's/^TF_VAR_enable_vpc=.*$/TF_VAR_enable_vpc=true/' $config_override # ...Enable the vpc.
sed -i 's/^TF_VAR_softnas_storage=.*$/TF_VAR_softnas_storage=true/' $config_override # ...On first apply, don't create softnas instance until vpn is working.
sed -i 's/^TF_VAR_aws_nodes_enabled=.*$/TF_VAR_aws_nodes_enabled=true/' $config_override # ...Site mounts will not be mounted in cloud.  currently this will disable provisioning any render node or remote workstation until vpn is confirmed to function after this step.

# Alter the config file directly for these tests.  Disable NAS and Houdini installs.
sed -i 's/^TF_VAR_localnas1_private_ip=.*$/TF_VAR_localnas1_private_ip=none/' $config_path # remove the ip address of the nfs share to test
sed -i 's/^TF_VAR_houdini_license_server_address=.*$/TF_VAR_houdini_license_server_address=none/' $config_path # remove the ip address
sed -i 's/^TF_VAR_localnas1_path_abs=.*$/TF_VAR_localnas1_path_abs=none/' $config_path # remove the ip address

sed -i 's/^TF_VAR_remote_mounts_on_local=.*$/TF_VAR_remote_mounts_on_local=true/' $config_override # ...Softnas nfs exports will not be mounted on local site
sed -i 's/^TF_VAR_provision_deadline_spot_plugin=.*$/TF_VAR_provision_deadline_spot_plugin=true/' $config_override # Don't provision the deadline spot plugin for this stage
sed -i 's/^TF_VAR_install_houdini=.*$/TF_VAR_install_houdini=false/' $config_override # install houdini
sed -i 's/^TF_VAR_install_deadline_db=.*$/TF_VAR_install_deadline_db=true/' $config_override # install deadline
sed -i 's/^TF_VAR_install_deadline_rcs=.*$/TF_VAR_install_deadline_rcs=true/' $config_override # install deadline
sed -i 's/^TF_VAR_install_deadline_worker=.*$/TF_VAR_install_deadline_worker=true/' $config_override # install deadline
sed -i 's/^TF_VAR_workstation_enabled=.*$/TF_VAR_workstation_enabled=false/' $config_override # install deadline
sed -i 's/^TF_VAR_tf_destroy_before_deploy=.*$/TF_VAR_tf_destroy_before_deploy=false/' $config_override # destroy before deploy
sed -i 's/^TF_VAR_taint_single=.*$/TF_VAR_taint_single=""/' $config_override # taint vpn