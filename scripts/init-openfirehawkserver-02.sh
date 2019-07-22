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

# ssh will be killed from the previous script because users were added to a new group and this will not update unless your ssh session is restarted.
# login again and continue...

ansible-playbook -i ansible/inventory/hosts ansible/openfirehawkserver_houdini.yaml
ansible-playbook -i ansible/inventory/hosts ansible/aws-new-key.yaml

# these are optional if you have an onsite RHEL / CENTOS workstation
# add local host ssh keys to list of accepted keys on ansible control, example for another onsite workstation-
ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=192.168.92.12 local=True"

# create and copy an ssh rsa key from ansible control to the workstation for provisioning.  1st time will error, run it twice
ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"
ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"

# configure routes to opposite environment for licence server to communicate if in dev environment
ansible-playbook -i ansible/inventory ansible/ansible-control-update-routes.yaml

echo "if above was succesful, exit the vm and use 'vagrant reload' before continuing with the next script"