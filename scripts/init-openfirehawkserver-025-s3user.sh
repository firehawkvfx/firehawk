#!/bin/bash
argument="$1"

SCRIPTNAME=`basename "$0"`
echo "Argument $1"
echo ""
ARGS=''

# This is the directory of the current script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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
SCRIPTDIR=$(to_abs_path $SCRIPTDIR)
printf "\n...checking scripts directory at $SCRIPTDIR\n\n"

cd /vagrant

tf_action="apply"

if [[ -z $argument ]] ; then
  echo "Error! you must specify an environment --dev or --prod" 1>&2
  exit 64
else
  case $argument in
    -d|--dev)
      ARGS='--dev'
      echo "using dev environment"
      source ./update_vars.sh --dev
      ;;
    -p|--prod)
      ARGS='--prod'
      echo "using prod environment"
      source ./update_vars.sh --prod
      ;;
    -p|--plan)
      tf_action="plan"
      echo "using prod environment"
      source ./update_vars.sh --prod
      ;;
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

echo 'Use vagrant reload and vagrant ssh after executing each .sh script'
echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

printf "\n\nHave you installed keybase and initialised pgp?\n\nIf not it is highly recommended that you create a profile on your phone and desktop for 2fa.\nIf this process fails for any reason use 'keybase login' manually and test pgp decryption in the shell.\n\n"

# install keybase and test decryption
$TF_VAR_firehawk_path/scripts/keybase-test.sh

# legacy manual keybase activation steps
# echo "Press ENTER if you have initialised a keybase pgp passphrase for this shell. Otherwise exit (ctrl+c) and run:"
# echo "keybase login"
# echo "keybase pgp gen"
# printf 'keybase pgp encrypt -m "test_secret" | keybase pgp decrypt\n'
# read userInput


# This stage configures the vpc and vpn.  after this stage, vagrant reload and test ping the private ip of the bastion host to ensure the vpn is working.

# REBOOT required for network interface modes to update.  Then launch terraform
# exit
# vagrant reload

# take a snapshot here as a recovery point.
# vagrant snapshot push
# vagrant ssh

# In this stage, we hold off creation of resources that require the vpn as a dependency.
# Config overide allows temporary configuration to set a state for your infrastructure.  This is to prevent you from editting the base configuration file in day to day operation once it is configured correctly.
config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier)
echo "...Config Override path $config_override"

echo 'on first apply, dont configure the vpc until it is required.'
sudo sed -i 's/^TF_VAR_enable_vpc=.*$/TF_VAR_enable_vpc=false/' $config_override
echo 'on first apply, dont create softnas instance until vpn is working'
sudo sed -i 's/^TF_VAR_softnas_storage=.*$/TF_VAR_softnas_storage=false/' $config_override
echo '...Site mounts will not be mounted in cloud.  currently this will disable provisioning any render node or remote workstation until vpn is confirmed to function after this step'
sudo sed -i 's/^TF_VAR_site_mounts=.*$/TF_VAR_site_mounts=false/' $config_override
echo '...Softnas nfs exports will not be mounted on local site'
sudo sed -i 's/^TF_VAR_remote_mounts_on_local=.*$/TF_VAR_remote_mounts_on_local=false/' $config_override

echo "...Sourcing config override"
source $TF_VAR_firehawk_path/update_vars.sh --$TF_VAR_envtier --var-file config-override

terraform init
if [[ "$tf_action" == "plan" ]]; then
  echo "running terraform plan"
  terraform plan
elif [[ "$tf_action" == "apply" ]]; then
  echo "running terraform apply without any VPC to create an user with s3 cloud storage read write priveledges."
  terraform apply --auto-approve
fi

# these are optional if you have an onsite RHEL / CENTOS workstation
# add local host ssh keys to list of accepted keys on ansible control, example for another onsite workstation-
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=192.168.92.12 local=True"

ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=workstation.firehawkvfx.com host_ip=192.168.92.12 group_name=role_local_workstation"


# create and copy an ssh rsa key from ansible control to the workstation for provisioning.  1st time will error, run it twice
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"
# ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"

# install the aws cli for the user to enable s3 access.
# ssh-agent bash
# ssh-add /home/vagrant/.ssh/id_rsa

export storage_user_access_key_id=$(terraform output storage_user_access_key_id)
echo "storage_user_access_key_id= $storage_user_access_key_id"
export storage_user_secret=$(terraform output storage_user_secret)
echo "storage_user_secret= $storage_user_secret"

ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"

printf "\n...Finished $SCRIPTNAME\n\n"