# REBOOT required for network interface modes to update.  Then launch terraform
# exit
# vagrant reload

# take a snapshot here as a recovery point.
# vagrant snapshot push
# vagrant ssh

cd /vagrant
source ./update_vars.sh --dev
export TF_VAR_site_mounts=False
terraform apply --auto-approve
# after first terraform apply, vagrant reload to apply the promisc settings to the NIC.  THIS NEEDS TO BE FIXED OR MOUNTS WONT WORK. you will get an error on the render node/remote workstation
# in the meantime, after a first install, roll up to softnas first, then reload, and then launch nodes.