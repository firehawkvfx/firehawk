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
      source ./update_vars.sh --dev --init; exit_test
      ;;
    -p|--prod)
      ARGS='--prod'
      echo "using prod environment"
      source ./update_vars.sh --prod --init; exit_test
      ;;
    -p|--plan)
      tf_action="plan"
      echo "using prod environment"
      source ./update_vars.sh --prod --init; exit_test
      ;;
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

# enable promisc mode
ansible-playbook -i "$TF_VAR_inventory" ansible/init.yaml --extra-vars "variable_host=localhost variable_user=deployuser configure_gateway=true set_hostname=firehawkgateway" --tags "init-host,init"; exit_test
# enable ipforwarding
ansible-playbook -i "$TF_VAR_inventory" ansible/openvpn-init.yaml -v --extra-vars "variable_host=localhost" --tags "init"; exit_test