#!/bin/bash
argument="$1"

echo "Argument $1"
echo ""
ARGS=''

cd /vagrant

if [[ -z $argument ]] ; then
  echo "Assuming prod environment without args --dev."
    source ./update_vars.sh --prod
else
  case $argument in
    -d|--dev)
      ARGS='--dev'
      echo "using dev environment"
      source ./update_vars.sh --dev
      ;;
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

echo 'Use vagrant reload and vagrant ssh after eexecuting each .sh script'
echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"


# This stage configures the vpc and vpn.  after this stage, vagrant reload and test ping the private ip of the bastion host to ensure the vpn is working.

# REBOOT required for network interface modes to update.  Then launch terraform
# exit
# vagrant reload

# take a snapshot here as a recovery point.
# vagrant snapshot push
# vagrant ssh

echo 'site mounts will not be mounted in cloud.  currently this will disable provisioning any render node or remote workstation until vpn is confirmed to function after this step'
export TF_VAR_site_mounts=False
echo 'softnas nfs exports will not be mounted on local site'
export TF_VAR_remote_mounts_on_local=False
echo 'on first apply, dont create softnas instance until vpn is working'
export TF_VAR_softnas_storage=False

terraform init
terraform apply --auto-approve


echo "After this first terraform apply is succesful, you must exit this vm and use 'vagrant reload' to apply the promisc settings to the NIC for routing to work."
#  THIS NEEDS TO BE FIXED OR MOUNTS from other systems onsite WONT WORK without reboot. you will get an error on the render node/remote workstation.  it would be good to have a single execute install.