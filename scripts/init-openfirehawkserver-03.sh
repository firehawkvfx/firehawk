# This stage configures the vpc and vpn.  after this stage, vagrant reload and test ping the private ip of the bastion host to ensure the vpn is working.

# REBOOT required for network interface modes to update.  Then launch terraform
# exit
# vagrant reload

# take a snapshot here as a recovery point.
# vagrant snapshot push
# vagrant ssh

cd /vagrant
source ./update_vars.sh --dev
# site mounts will be mounted in cloud
export TF_VAR_site_mounts=False
export TF_VAR_softnas_config_mounts_on_local_workstation=False
export TF_VAR_softnas_storage=False
terraform apply --auto-approve

# after first terraform apply, vagrant reload to apply the promisc settings to the NIC.  THIS NEEDS TO BE FIXED OR MOUNTS from other systems onsite WONT WORK. you will get an error on the render node/remote workstation