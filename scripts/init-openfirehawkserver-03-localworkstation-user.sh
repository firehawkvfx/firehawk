#!/bin/bash
argument="$1"

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

echo 'Use vagrant reload and vagrant ssh after eexecuting each .sh script'
echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"


# these are optional if you have an onsite RHEL / CENTOS workstation
# add local host ssh keys to list of accepted keys on ansible control, example for another onsite workstation-
ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=192.168.92.12 local=True"

# create and copy an ssh rsa key from ansible control to the workstation for provisioning.  1st time will error, run it twice
ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"
# ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"

# This stage configures deadline on the local workstation

# REBOOT required for network interface modes to update.  Then launch terraform

# configure deadline on the local workstation with the keys from this install to run deadline slave and monitor
ansible-playbook -i secrets/dev/inventory/hosts ansible/localworkstation-deadlineuser.yaml --tags "onsite-install" --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_key"

#need to fix houdini executable for deadline install and houdini install stages - both.

echo 'Use vagrant reload and vagrant ssh after eexecuting each .sh script'