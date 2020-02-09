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
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
  $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-010-keybase.sh $ARGS; exit_test
  $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-020-init.sh $ARGS; exit_test
  
  terraform init
  terraform apply --auto-approve; exit_test
  # After this point provisioning will now execute from TF.
  # $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-030-tf-s3user-deadlinercs.sh $ARGS; exit_test
  # $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-040-ssh-routes-nfs-houdini-license-repository.sh $ARGS; exit_test
  # $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-050-localworkstation-s3user.sh $ARGS; exit_test
  # $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-060-localworkstation-user-deadline.sh $ARGS; exit_test
  # $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-070-localworkstation-houdini.sh $ARGS; exit_test
  # $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-080-vpn.sh $ARGS; exit_test
  # $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-090-cloudmounts.sh $ARGS; exit_test
  # $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-100-cloudnodes-localmounts.sh $ARGS; exit_test
  # $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-110-localworkstation-cloudmounts.sh $ARGS; exit_test
fi

