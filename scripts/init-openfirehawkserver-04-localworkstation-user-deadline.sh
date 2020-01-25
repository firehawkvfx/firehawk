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

ansible-playbook -i ansible/inventory/hosts ansible/deadline-db-check.yaml -v; exit_test

# This stage configures deadline on the local workstation
# REBOOT required for network interface modes to update.

# configure deadline on the local workstation with the keys from this install to run deadline slave and monitor
ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-worker-install.yaml --tags "onsite-install" --extra-vars "variable_host=workstation1 variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test

ansible-playbook -i ansible/inventory/hosts ansible/deadline-db-check.yaml -v; exit_test

#need to fix houdini executable for deadline install and houdini install stages - both.

echo 'exit and use vagrant reload, then vagrant ssh back in after executing each .sh script'
# kill the current session to ensure any new groups can be used in next script
printf "\n...Finished $SCRIPTNAME\n\n"
sleep 1; pkill -u vagrant sshd