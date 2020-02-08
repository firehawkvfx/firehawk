#!/bin/bash

### GENERAL FUNCTIONS FOR ALL INSTALLS

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c() {
        printf "\n** CTRL-C ** EXITING...\n"
        exit
}
function to_abs_path {
    local target="$1"
    if [ "$target" == "." ]; then
        echo "$(pwd)"
    elif [ "$target" == ".." ]; then
        echo "$(dirname "$(pwd)")"
    else
        echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
}
# This is the directory of the current script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPTDIR=$(to_abs_path $SCRIPTDIR)
printf "\n...checking scripts directory at $SCRIPTDIR\n\n"
# source an exit test to bail if non zero exit code is produced.
. $SCRIPTDIR/exit_test.sh

argument="$1"

echo "Argument $1"
echo ""
ARGS=''

cd /deployuser

### Get s3 access keys from terraform ###

tf_action="apply"

if [[ -z $argument ]] ; then
  echo "Error! you must specify an environment --dev or --prod" 1>&2
  exit 64
else
  case $argument in
    -d|--dev)
      ARGS='--dev'
      echo "using dev environment"
      source ./update_vars.sh --dev; exit_test
      ;;
    -p|--prod)
      ARGS='--prod'
      echo "using prod environment"
      source ./update_vars.sh --prod; exit_test
      ;;
    -p|--plan)
      tf_action="plan"
      echo "using prod environment"
      source ./update_vars.sh --prod; exit_test
      ;;
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

# install keybase, used for aquiring keys for deadline spot plugin.
echo "...Downloading/installing keybase for PGP encryption"
(
cd /deployuser/tmp
file='/deployuser/tmp/keybase_amd64.deb'
uri='https://prerelease.keybase.io/keybase_amd64.deb'
if test -e "$file"
then zflag=(-z "$file")
else zflag=()
fi
curl -o "$file" "${zflag[@]}" "$uri"
)

if [[ $keybase_disabled != true ]]; then
  sudo apt install -y /deployuser/tmp/keybase_amd64.deb
  run_keybase
  echo $(keybase --version)

  # install keybase and test decryption
  $TF_VAR_firehawk_path/scripts/keybase-test.sh; exit_test
  # if you encounter issues you should login with 'keybase login'.  if you haven't created a user account you can do so at keybase.io
fi

### This scirpt is used to roll back a deployment without a full destroy

# configure the overides to have no vpc.  no vpc is required in the first stage to create a user with s3 access credentials.
config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier)
echo "...Config Override path $config_override"
echo 'on first apply, dont configure with no VPC until it is required.'
sudo sed -i 's/^TF_VAR_enable_vpc=.*$/TF_VAR_enable_vpc=false/' $config_override
echo 'on first apply, dont create softnas instance until vpn is working'
sudo sed -i 's/^TF_VAR_softnas_storage=.*$/TF_VAR_softnas_storage=false/' $config_override
echo '...Site mounts will not be mounted in cloud.  currently this will disable provisioning any render node or remote workstation until vpn is confirmed to function after this step'
sudo sed -i 's/^TF_VAR_site_mounts=.*$/TF_VAR_site_mounts=false/' $config_override
echo '...Softnas nfs exports will not be mounted on local site'
sudo sed -i 's/^TF_VAR_remote_mounts_on_local=.*$/TF_VAR_remote_mounts_on_local=false/' $config_override
echo "...Sourcing config override"
source $TF_VAR_firehawk_path/update_vars.sh --$TF_VAR_envtier --var-file config-override; exit_test

cd /deployuser
terraform init
if [[ "$tf_action" == "plan" ]]; then
  printf "\nrunning terraform plan.\n"
  terraform plan; exit_test
elif [[ "$tf_action" == "apply" ]]; then
  printf "\nrunning terraform apply without any VPC to create a user with s3 cloud storage read write access.\n"
  terraform apply --auto-approve; exit_test
  # get keys for s3 install
  export storage_user_access_key_id=$(terraform output storage_user_access_key_id)
  echo "storage_user_access_key_id= $storage_user_access_key_id"
  export storage_user_secret=$(terraform output storage_user_secret)
  echo "storage_user_secret= $storage_user_secret"

  ### end get access keys from terraform
fi