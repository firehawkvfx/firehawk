# this stage will configure mounts from onsite onto the cloud site, and vice versa.

# vagrant reload
# vagrant ssh

# test the vpn buy logging into softnas and ping another system on your local network.

cd /vagrant
source ./update_vars.sh --dev
export TF_VAR_softnas_storage=True
export TF_VAR_site_mounts=True
export TF_VAR_remote_mounts_on_local=True
terraform apply --auto-approve
#should add a test script at this point to validate vpn connection is established, or licence servers may not work.