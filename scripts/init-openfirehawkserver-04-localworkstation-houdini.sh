#!/bin/bash
eval $(ssh-agent)

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

echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

# install houdini on a local workstation with deadline submitters and environment vars.

#ssh-agent bash
ssh-add /home/vagrant/.ssh/id_rsa
ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-houdini.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser" --skip-tags "sync_scripts"
eval $(ssh-agent -k)