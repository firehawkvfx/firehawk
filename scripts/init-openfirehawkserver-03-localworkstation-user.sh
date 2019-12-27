#!/bin/bash
argument="$1"

SCRIPTNAME=`basename "$0"`
echo "Argument $1"
echo ""
ARGS=''

cd /vagrant

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
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

echo 'Use vagrant reload and vagrant ssh after executing each .sh script'
echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

# This stage configures deadline on the local workstation
# REBOOT required for network interface modes to update.  Then launch terraform

# configure deadline on the local workstation with the keys from this install to run deadline slave and monitor
ansible-playbook -i "$TF_VAR_inventory" ansible/localworkstation-deadlineuser.yaml --tags "onsite-install" --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_key"

#need to fix houdini executable for deadline install and houdini install stages - both.

echo 'exit and use vagrant reload, then vagrant ssh back in after executing each .sh script'
# kill the current session to ensure any new groups can be used in next script
printf "\n...Finished $SCRIPTNAME\n\n"
sleep 1; pkill -u vagrant sshd