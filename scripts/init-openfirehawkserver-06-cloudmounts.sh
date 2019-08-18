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

# This stage configures softnas, but optionally doesn't not setup any mounts reliant on a vpn.

# vagrant reload
# vagrant ssh

# test the vpn buy logging into softnas and ping another system on your local network.

# when sooftnas storage is set to true, it will create and mount devices, and add the exports if volume paths are available.  otherwise you will need to continue to setup the volumes manually before proceeding to the next step
# loging into the softnas instance and setting up your volumes is necesary if this is your first time creating the volumes.
export TF_VAR_softnas_storage=True
# it is possible the next variables are causing issues when set to false.  verification needed.
export TF_VAR_site_mounts=False
export TF_VAR_remote_mounts_on_local=False
terraform apply --auto-approve

echo 'Use vagrant reload and vagrant ssh after eexecuting each .sh script'