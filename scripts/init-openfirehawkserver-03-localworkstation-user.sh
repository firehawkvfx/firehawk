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


# these are optional if you have an onsite RHEL / CENTOS workstation
# add local host ssh keys to list of accepted keys on ansible control, example for another onsite workstation-
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=192.168.92.12 local=True"

ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=workstation.firehawkvfx.com host_ip=192.168.92.12 group_name=role_local_workstation"

# create and copy an ssh rsa key from ansible control to the workstation for provisioning.  1st time will error, run it twice
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"
# ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"

# install the aws cli for the user to enable s3 access.
ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"

# This stage configures deadline on the local workstation
# REBOOT required for network interface modes to update.  Then launch terraform

# configure deadline on the local workstation with the keys from this install to run deadline slave and monitor
ansible-playbook -i "$TF_VAR_inventory" ansible/localworkstation-deadlineuser.yaml --tags "onsite-install" --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_key"

#need to fix houdini executable for deadline install and houdini install stages - both.

echo 'exit and use vagrant reload, then vagrant ssh back in after executing each .sh script'
# kill the current session to ensure any new groups can be used in next script
printf "\n...Finished $SCRIPTNAME\n\n"
sleep 1; pkill -u vagrant sshd