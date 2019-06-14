# This stage configures softnas, but optionally doesn't not setup any mounts reliant on a vpn.

# vagrant reload
# vagrant ssh

# test the vpn buy logging into softnas and ping another system on your local network.

cd /vagrant
source ./update_vars.sh --dev
export TF_VAR_softnas_storage=True
# it is possible the next variables are causing issues when set to false.  verification needed.
export TF_VAR_site_mounts=True
export TF_VAR_remote_mounts_on_local=True
terraform apply --auto-approve