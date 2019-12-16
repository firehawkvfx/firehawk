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

echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

# This stage configures softnas, but optionally doesn't not setup any mounts reliant on a vpn. it wont commence installing render nodes until the next stage.

# vagrant reload
# vagrant ssh

# test the vpn buy logging into softnas and ping another system on your local network.

# when sooftnas storage is set to true, it will create and mount devices, and add the exports if volume paths are available.  otherwise you will need to continue to setup the volumes manually before proceeding to the next step
# loging into the softnas instance and setting up your volumes is necesary if this is your first time creating the volumes.
# export TF_VAR_softnas_storage=true
# when site mounts are true, then cloud nodes will start and use NFS site mounts.
# export TF_VAR_site_mounts=false
# export TF_VAR_remote_mounts_on_local=false

config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier)
echo "...Config Override path $config_override"
echo '...Site mounts will not be mounted in cloud.  currently this will disable provisioning any render node or remote workstation until vpn is confirmed to function after this step'
sudo sed -i 's/^TF_VAR_softnas_storage=.*$/TF_VAR_softnas_storage=true/' $config_override
echo '...Softnas nfs exports will not be mounted on local site'
sudo sed -i 's/^TF_VAR_site_mounts=.*$/TF_VAR_site_mounts=false/' $config_override
echo 'on first apply, dont create softnas instance until vpn is working'
sudo sed -i 's/^TF_VAR_remote_mounts_on_local=.*$/TF_VAR_remote_mounts_on_local=false/' $config_override
echo "...Sourcing config override"
source $TF_VAR_firehawk_path/update_vars.sh --$TF_VAR_envtier --var-file config-override


terraform apply --auto-approve

# kill the current session to ensure any new groups can be used in next script
# sleep 1; pkill -u vagrant sshd
printf "\n...Finished $SCRIPTNAME\n\n"