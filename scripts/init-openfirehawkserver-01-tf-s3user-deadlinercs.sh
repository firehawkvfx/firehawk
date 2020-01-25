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

cd /vagrant

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

# install keybase, used for aquiring keys for deadline spot plugin.
echo "...Downloading/installing keybase for PGP encryption"
(
cd /vagrant/tmp
file='/vagrant/tmp/keybase_amd64.deb'
uri='https://prerelease.keybase.io/keybase_amd64.deb'
if test -e "$file"
then zflag=(-z "$file")
else zflag=()
fi
curl -o "$file" "${zflag[@]}" "$uri"
)
sudo apt install -y /vagrant/tmp/keybase_amd64.deb
run_keybase
echo $(keybase --version)

# you should login with 'keybase login'.  if you haven't created a user account you can do so at keybase.io

ansible-playbook -i ansible/inventory/hosts ansible/init.yaml --extra-vars "variable_user=vagrant"; exit_test
printf "\n\nHave you installed keybase and initialised pgp?\n\nIf not it is highly recommended that you create a profile on your phone and desktop for 2fa.\nIf this process fails for any reason use 'keybase login' manually and test pgp decryption in the shell.\n\n"

# add local host ssh keys to list of accepted keys on ansible control. Example for another onsite workstation-
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=$TF_VAR_openfirehawkserver local=True"; exit_test
# now add this host and address to ansible inventory
ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=gateway host_ip=$TF_VAR_openfirehawkserver group_name=role_gateway insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_general_use_ssh_key"; exit_test

ansible -m ping gateway -i "$TF_VAR_inventory" --private-key=/vagrant/.vagrant/machines/gateway/virtualbox/private_key -u vagrant --become
# Now this will init the deployuser on the workstation.  the deployuser will become the primary user with ssh access.  After this point the vagrant user could be destroyed for further hardening.
ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_sshuser.yaml -v --extra-vars "variable_host=gateway user_inituser_name=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/gateway/virtualbox/private_key"; exit_test
ansible -m ping gateway -i "$TF_VAR_inventory" --private-key=$TF_VAR_general_use_ssh_key -u deployuser --become; exit_test

# # install keybase and test decryption
# $TF_VAR_firehawk_path/scripts/keybase-test.sh; exit_test

# # legacy manual keybase activation steps
# # echo "Press ENTER if you have initialised a keybase pgp passphrase for this shell. Otherwise exit (ctrl+c) and run:"
# # echo "keybase login"
# # echo "keybase pgp gen"
# # printf 'keybase pgp encrypt -m "test_secret" | keybase pgp decrypt\n'
# # read userInput

# # configure the overides to have no vpc.  no vpc is required in the first stage to create a user with s3 access credentials.
# config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier)
# echo "...Config Override path $config_override"
# echo 'on first apply, dont configure with no VPC until it is required.'
# sudo sed -i 's/^TF_VAR_enable_vpc=.*$/TF_VAR_enable_vpc=false/' $config_override
# echo 'on first apply, dont create softnas instance until vpn is working'
# sudo sed -i 's/^TF_VAR_softnas_storage=.*$/TF_VAR_softnas_storage=false/' $config_override
# echo '...Site mounts will not be mounted in cloud.  currently this will disable provisioning any render node or remote workstation until vpn is confirmed to function after this step'
# sudo sed -i 's/^TF_VAR_site_mounts=.*$/TF_VAR_site_mounts=false/' $config_override
# echo '...Softnas nfs exports will not be mounted on local site'
# sudo sed -i 's/^TF_VAR_remote_mounts_on_local=.*$/TF_VAR_remote_mounts_on_local=false/' $config_override
# echo "...Sourcing config override"
# source $TF_VAR_firehawk_path/update_vars.sh --$TF_VAR_envtier --var-file config-override; exit_test

# cd /vagrant
# terraform init
# if [[ "$tf_action" == "plan" ]]; then
#   printf "\nrunning terraform plan.\n"
#   terraform plan; exit_test
# elif [[ "$tf_action" == "apply" ]]; then
#   printf "\nrunning terraform apply without any VPC to create a user with s3 cloud storage read write access.\n"
#   terraform apply --auto-approve; exit_test
#   # get keys for s3 install
#   export storage_user_access_key_id=$(terraform output storage_user_access_key_id)
#   echo "storage_user_access_key_id= $storage_user_access_key_id"
#   export storage_user_secret=$(terraform output storage_user_secret)
#   echo "storage_user_secret= $storage_user_secret"

#   ### end get access keys from terraform

#   echo 'Use vagrant reload and vagrant ssh after executing each .sh script'
#   echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

#   # install aws cli for user with s3 credentials.  root user only needs s3 access.  in future consider provisining a replacement access key for vagrant with less permissions, and remove the root account keys?
#   ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=ansible_control variable_user=root"; exit_test

#   ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadlineuser.yaml -v --tags 'newuser,onsite-install'; exit_test
#   # add vagrant user to group syscontrol
#   ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadlineuser.yaml -v --extra-vars 'variable_user=vagrant' --tags 'onsite-install'; exit_test
#   ansible-playbook -i ansible/inventory/hosts ansible/deadline-db-install.yaml -v; exit_test

#   # first db check
#   ansible-playbook -i ansible/inventory/hosts ansible/deadline-db-check.yaml -v; exit_test
#   # couldn't do this before previous playbook since the user doesn't exist yet.  split out the creation of the user into a seperate role to run first, then we can download deadline via s3.
  
#   ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=ansible_control variable_user=deadlineuser"; exit_test
  
#   # 2nd db check
#   ansible-playbook -i ansible/inventory/hosts ansible/deadline-db-check.yaml -v; exit_test

#   echo "Soft shutdown scheduled (To protect DB).  After shutdown, 'vagrant reload', and use 'vagrant ssh' to return to the VM."
#   sudo shutdown
#   # shell will exit at this point, no commands possible here on.
# fi