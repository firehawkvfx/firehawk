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

ansible-playbook -i ansible/inventory/hosts ansible/init.yaml --extra-vars "variable_user=vagrant"
ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadline.yaml
# custom events auto assign groups to slaves on startup
ansible-playbook -i ansible/inventory/hosts ansible/deadline-repository-custom-events.yaml

echo "if above was succesful, exit the vm and use 'vagrant reload' before continuing with the next script.  New user group added wont have user added until reload."
echo "For deadline to work, ensure you have follow these steps:"
echo "1. in deadline monitor create groups under (super user mode): tools/create groups and ensure the groups exist for all groups slave appear under"
echo "eg cloud, local, local_workstation, cloud_workstation"
echo "2. ensure you have entered your ubl information for the repository"
echo "3. ensure you have enabled the commandline plugin in tools configure plugins"
echo "4. ensure slaveautoconf is enabled up configure event plugins"