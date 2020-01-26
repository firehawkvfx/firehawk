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

cd /vagrant

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
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

echo 'Use vagrant reload and vagrant ssh after executing each .sh script'
echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

#check db
ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test

# custom events auto assign groups to slaves on startup, eg slaveautoconf
ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-repository-custom-events.yaml; exit_test

# configure onsite NAS mounts to firehawkgateway
ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml --extra-vars "variable_host=firehawkgateway variable_user=deployuser softnas_hosts=none" --tags 'local_install_onsite_mounts'; exit_test

# ssh will be killed from the previous script because users were added to a new group and this will not update unless your ssh session is restarted.
# login again and continue...

# install houdini with the same procedure as on render nodes and workstations, and initialise the licence server on this system.
ansible-playbook -i "$TF_VAR_inventory" ansible/modules/houdini-module/houdini-module.yaml -vvv --extra-vars "sesi_username=$TF_VAR_sesi_username sesi_password=$TF_VAR_sesi_password variable_host=localhost variable_user=vagrant houdini_install_type=server" --skip-tags "sync_scripts"; exit_test
# ensure an aws pem key exists for ssh into cloud nodes
ansible-playbook -i "$TF_VAR_inventory" ansible/aws-new-key.yaml; exit_test
# configure routes to opposite environment for licence server to communicate if in dev environment
ansible-playbook -i "$TF_VAR_inventory" ansible/firehawkgateway-update-routes.yaml; exit_test

#check db
ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-restart.yaml -v; exit_test
ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test

echo -e "\nIf above was succesful, exit the vm and use 'vagrant reload' before continuing with the next script.  New user group added wont have user added until reload."
echo -e "\nFor houdini to work, ensure you have configured your licences on the production server."
echo -e "\nDo not install houdini licensing in a dev vm since it should be as stable as possible, and re provisioning the vm will use licence key install tokens (limited yearly)"
echo -e "\nFor deadline to work, ensure you have follow these steps:"
echo "1. in deadline monitor create groups in super user mode: tools/create groups and ensure the groups exist for all groups appear under"
echo "eg cloud, local, local_workstation, cloud_workstation"
echo "2. ensure you have entered your ubl information for the repository"
echo "3. ensure you have enabled the commandline plugin in tools configure plugins"
printf "\n...Finished $SCRIPTNAME\n\n"