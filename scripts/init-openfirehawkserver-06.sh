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

# this stage will configure mounts from onsite onto the cloud site, and vice versa.

# vagrant reload
# vagrant ssh

# test the vpn buy logging into softnas and ping another system on your local network.

export TF_VAR_softnas_storage=True
export TF_VAR_site_mounts=True
export TF_VAR_remote_mounts_on_local=True
terraform apply --auto-approve
#should add a test script at this point to validate vpn connection is established, or licence servers may not work.