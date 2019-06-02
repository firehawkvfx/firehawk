
# vagrant reload
# vagrant ssh

# test the vpn buy logging into softnas and ping another system on your local network.

cd /vagrant
source ./update_vars.sh --dev
export TF_VAR_site_mounts=True
terraform apply --auto-approve
#should add a test script at this point to validate vpn connection is established, or licence servers may not work.