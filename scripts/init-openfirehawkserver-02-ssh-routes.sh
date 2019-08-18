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

# configure onsite NAS mounts to ansible control
ansible-playbook -i ansible/inventory/hosts ansible/node-centos-mounts.yaml -vvvv --extra-vars "variable_host=localhost variable_user=vagrant softnas_hosts=none" --tags 'local_install_onsite_mounts'

# ssh will be killed from the previous script because users were added to a new group and this will not update unless your ssh session is restarted.
# login again and continue...

ansible-playbook -i ansible/inventory/hosts ansible/openfirehawkserver_houdini.yaml
ansible-playbook -i ansible/inventory/hosts ansible/aws-new-key.yaml
# configure routes to opposite environment for licence server to communicate if in dev environment
ansible-playbook -i ansible/inventory ansible/ansible-control-update-routes.yaml

echo -e "\nIf above was succesful, exit the vm and use 'vagrant reload' before continuing with the next script.  New user group added wont have user added until reload."
echo -e "\nFor deadline to work, ensure you have follow these steps:"
echo "1. in deadline monitor create groups under super user mode: tools/create groups and ensure the groups exist for all groups slave appear under"
echo "eg cloud, local, local_workstation, cloud_workstation"
echo "2. ensure you have entered your ubl information for the repository"
echo "3. ensure you have enabled the commandline plugin in tools configure plugins"
echo "4. ensure slaveautoconf is enabled up configure event plugins"