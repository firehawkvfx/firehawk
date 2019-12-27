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

echo 'Use vagrant reload and vagrant ssh after executing each .sh script'
echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

# install keybase, used for aquiring keys for deadline spot plugin.
echo "...Downloading/installing keybase for PGP encryption"
(cd /vagrant/tmp; curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb)
sudo apt install -y /vagrant/tmp/keybase_amd64.deb
run_keybase
echo $(keybase --version)

# you should login with 'keybase login'.  if you haven't created a user account you can do so at keybase.io

ansible-playbook -i ansible/inventory/hosts ansible/init.yaml --extra-vars "variable_user=vagrant"

#install aws cli for user with s3 credentials
ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=ansible_control variable_user=vagrant"
ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=ansible_control variable_user=root"

ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadline.yaml -v
# shell will exit at this point, no commands possible here on.
