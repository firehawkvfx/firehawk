#!/bin/bash
argument="$1"

SCRIPTNAME=`basename "$0"`
echo "Argument $1"
echo ""
ARGS=''

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c() {
        printf "\n** CTRL-C ** EXITING...\n"
        exit
}
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
# This is the directory of the current script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPTDIR=$(to_abs_path $SCRIPTDIR)
printf "\n...checking scripts directory at $SCRIPTDIR\n\n"
# source an exit test to bail if non zero exit code is produced.
. $SCRIPTDIR/exit_test.sh

cd /deployuser

### Get s3 access keys from terraform ###

tf_action="apply"

if [[ -z $argument ]] ; then
  echo "Error! you must specify an environment --dev or --prod" 1>&2
  exit 64
else
  case $argument in
    -d|--dev)
      ARGS='--dev'
      echo "using dev environment"
      source ./update_vars.sh --dev; exit_test
      ;;
    -p|--prod)
      ARGS='--prod'
      echo "using prod environment"
      source ./update_vars.sh --prod; exit_test
      ;;
    -p|--plan)
      tf_action="plan"
      echo "using prod environment"
      source ./update_vars.sh --prod; exit_test
      ;;
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

echo 'Use vagrant reload and vagrant ssh after executing each .sh script'
echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

printf "\n\nHave you installed keybase and initialised pgp?\n\nIf not it is highly recommended that you create a profile on your phone and desktop for 2fa first.\nIf this process fails for any reason use 'keybase login' manually and test pgp decryption in the shell.\n\n"

#check db
ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test


# install keybase and test decryption
$TF_VAR_firehawk_path/scripts/keybase-pgp-test.sh; exit_test

# legacy manual keybase activation steps
# echo "Press ENTER if you have initialised a keybase pgp passphrase for this shell. Otherwise exit (ctrl+c) and run:"
# echo "keybase login"
# echo "keybase pgp gen"
# printf 'keybase pgp encrypt -m "test_secret" | keybase pgp decrypt\n'
# read userInput

if [[ "$tf_action" == "plan" ]]; then
  echo "running terraform plan"
  cd /deployuser
  terraform plan; exit_test
elif [[ "$tf_action" == "apply" ]]; then
  echo "running terraform apply."
  cd /deployuser
  terraform apply --auto-approve; exit_test
  # get keys for s3 install
  export storage_user_access_key_id=$(terraform output storage_user_access_key_id)
  echo "storage_user_access_key_id= $storage_user_access_key_id"
  export storage_user_secret=$(terraform output storage_user_secret)
  echo "storage_user_secret= $storage_user_secret"
fi

### end get access keys from terraform

# these are optional if you have an onsite RHEL / CENTOS workstation

# add local host ssh keys to list of accepted keys on ansible control. Example for another onsite workstation-
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=$TF_VAR_workstation_address local=True"; exit_test
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "variable_host=$TF_VAR_workstation_address variable_user=deployuser local=True"; exit_test


# now add this host and address to ansible inventory
ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=workstation1 host_ip=$TF_VAR_workstation_address group_name=role_local_workstation insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test

# Now this will init the deployuser on the workstation.  the deployuser wil become the primary user with ssh access.  once this process completes the first time.
ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_sshuser.yaml -v --extra-vars "variable_host=workstation1 user_inituser_name=$TF_VAR_user_inituser_name ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test
# test connection as new deployuser
ansible -m ping workstation1 -i "$TF_VAR_inventory" --private-key=$TF_VAR_general_use_ssh_key -u deployuser --become; exit_test

# we can use the deploy user to create more users as well, like the deadlineuser for artist use.
ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_connect_as_user=deployuser variable_user=deadlineuser variable_host=workstation1 ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key" --tags 'newuser,onsite-install'; exit_test

# create and copy an ssh rsa key from ansible control to the workstation for provisioning.  1st time will error, run it twice
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation1 variable_user=$TF_VAR_user_inituser_name ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test

# configure aws for all users
ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=workstation1 variable_user=deployuser aws_cli_root=true ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test
ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser aws_cli_root=true ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test

#check db
ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test


printf "\n...Finished $SCRIPTNAME\n\n"