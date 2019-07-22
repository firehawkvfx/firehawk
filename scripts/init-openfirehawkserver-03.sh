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


# This stage configures deadline on the local workstation

# REBOOT required for network interface modes to update.  Then launch terraform

# configure deadline on the local workstation with the keys from this install to run deadline slave and monitor
ansible-playbook -i secrets/dev/inventory/hosts ansible/localworkstation-deadlineuser.yaml --tags "onsite-install" --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_key"
