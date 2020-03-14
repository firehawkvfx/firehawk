#!/bin/bash

### GENERAL FUNCTIONS FOR ALL INSTALLS

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

argument="$1"

echo "Argument $1"
echo ""
ARGS=''

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


ansible-playbook -i ansible/inventory/hosts ansible/init.yaml --extra-vars "variable_user=deployuser set_hostname=ansiblecontrol"; exit_test
printf "\n\nHave you installed keybase and initialised pgp?\n\nIf not it is highly recommended that you create a profile on your phone and desktop for 2fa.\nIf this process fails for any reason use 'keybase login' manually and test pgp decryption in the shell.\n\n"
echo "Ansible will create a PEM key at this path if it doesn't already exist: $TF_VAR_local_key_path"
ansible-playbook -i "$TF_VAR_inventory" ansible/aws-new-key.yaml; exit_test
echo "add local host ssh keys to list of accepted keys on ansible control. Example for another onsite workstation"
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=$TF_VAR_openfirehawkserver local=True"; exit_test
echo "Add this host and address to ansible inventory"
ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=firehawkgateway host_ip=$TF_VAR_openfirehawkserver group_name=role_gateway insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_general_use_ssh_key"; exit_test

sudo chmod 0400 /secrets/keys/firehawkgateway_private_key
sudo chown deployuser:deployuser /secrets/keys/firehawkgateway_private_key

# Now this will init the deployuser on the workstation.  the deployuser will become the primary user with ssh access.
ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_sshuser.yaml -vvvv --extra-vars "variable_host=firehawkgateway user_inituser_name=deployuser user_inituser_pw='' ansible_ssh_private_key_file=/secrets/keys/firehawkgateway_private_key"; exit_test
echo "Ping the host as deployuser..."
ansible -m ping firehawkgateway -i "$TF_VAR_inventory" --private-key=$TF_VAR_general_use_ssh_key -u deployuser --become; exit_test
echo "Init the Gateway VM..."
ansible-playbook -i "$TF_VAR_inventory" ansible/init.yaml --extra-vars "variable_host=firehawkgateway variable_user=deployuser configure_gateway=true set_hostname=firehawkgateway"; exit_test

echo '...Show key permissions'
ls -ltriah /secrets/keys/