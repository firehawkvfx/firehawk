#!/bin/bash

### GENERAL FUNCTIONS FOR ALL INSTALLS

# Don't store command history.
unset HISTFILE

if [[ ! -z "$firehawksecret" ]]; then
  echo "Vagrant: firehawksecret:$firehawksecret"
else
  echo "Vagrant: No firehawk secret env var provided, will prompt user for input."
fi

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
init_vm=true

optspec=":h-:"

parse_opts () {
    local OPTIND
    OPTIND=0
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    dev)
                        ARGS='--dev'
                        echo "using dev environment"
                        source ./update_vars.sh --dev; exit_test
                        ;;
                    prod)
                        ARGS='--prod'
                        echo "using prod environment"
                        source ./update_vars.sh --prod; exit_test
                        ;;
                    sleep)
                        tf_action='sleep'
                        ;;
                    destroy)
                        tf_action='destroy'
                        ;;
                    init-vm)
                        init_vm="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    init-vm=*)
                        init_vm=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        ;;
                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            echo "Unknown option --${OPTARG}" >&2
                        fi
                        ;;
                esac;;
            h)
                help
                ;;
            *)
                if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                    echo "Non-option argument: '-${OPTARG}'" >&2
                fi
                ;;
        esac
    done
}
parse_opts "$@"



if [[ -z $TF_VAR_envtier ]] ; then
  echo "Error! you must specify an environment --dev or --prod" 1>&2
  exit 64
else
  if [[ "$init_vm" == true ]]; then
    echo "...Provision PGP / Keybase"
    $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-010-keybase.sh $ARGS; exit_test
    echo "...Provision Local VM's"
    $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-020-init.sh $ARGS; exit_test
  fi

  if [[ "$tf_action" == "apply" ]]; then
    echo "...Start Terraform"
    terraform init -lock=false; exit_test # Required to initialise any new modules
  
    if [[ "$TF_VAR_tf_destroy_before_deploy" == true ]]; then
      echo "...Destroy before deploy"
      terraform destroy --auto-approve -lock=false; exit_test
    fi
    echo "...Terraform apply"
    terraform apply --auto-approve -lock=false; exit_test
    
    # # the following commands will only occur if there is a succesful deployment.  handling a failed deployment will require reexecution
    # if [[ "$TF_VAR_destroy_after_deploy" == true ]]; then
    #   terraform destroy --auto-approve -lock=false; exit_test
    # else
    #   terraform apply --auto-approve -var sleep=true # turn of all nodes to save cloud costs after provisioning
    # fi
  elif [[ "$tf_action" == "sleep" ]]; then
    echo "...Terraform sleep"
    terraform apply --auto-approve -var sleep=true
  elif [[ "$tf_action" == "destroy" ]]; then
    echo "...Terraform destroy"
    terraform destroy --auto-approve
  fi


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

echo "$(date) Finished a run" | tee -a tmp/log.txt
cat tmp/log.txt