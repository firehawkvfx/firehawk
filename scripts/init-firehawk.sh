#!/bin/bash

### GENERAL FUNCTIONS FOR ALL INSTALLS

# Don't store command history.
unset HISTFILE


set -eE -o functrace # This block allows you to echo a line number for a failure.

err_report() {
  local lineno=$1
  local msg=$2
  echo "$0 script Failed at $lineno: $msg"
}
trap 'err_report ${LINENO} "$BASH_COMMAND"' ERR

if [[ ! -z "$firehawksecret" ]]; then
  echo "Vagrant: firehawksecret encrypted env var found"
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
tf_init=true
init_vm_config=true
fast=false
set_softnas_volatile=false

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
                        source ./update_vars.sh --dev --silent; exit_test
                        ;;
                    prod)
                        ARGS='--prod'
                        echo "using prod environment"
                        source ./update_vars.sh --prod --silent; exit_test
                        ;;
                    sleep)
                        tf_action='sleep'
                        ;;
                    destroy)
                        tf_action='destroy'
                        ;;
                    no-tf)
                        tf_action='none'
                        ;;
                    tf-action)
                        tf_action="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "tf_action set: $tf_action"
                        ;;
                    tf-action=*)
                        tf_action=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "tf_action set: $tf_action"
                        ;;
                    tf-init)
                        tf_init="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "tf_init set: $tf_init"
                        ;;
                    tf-init=*)
                        tf_init=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "tf_init set: $tf_init"
                        ;;
                    init-vm-config)
                        init_vm_config="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "init_vm_config set: $init_vm_config"
                        ;;
                    init-vm-config=*)
                        init_vm_config=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "init_vm_config set: $init_vm_config"
                        ;;
                    softnas-destroy-volumes)
                        set_softnas_volatile="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "set_softnas_volatile set: $set_softnas_volatile"
                        ;;
                    softnas-destroy-volumes=*)
                        set_softnas_volatile=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "set_softnas_volatile set: $set_softnas_volatile"
                        ;;
                    fast)
                        fast="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "fast set: $fast"
                        ;;
                    fast=*)
                        fast=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "fast: $fast"
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

# set -x; SHOWCOMMANDS=true # show bash input

sed -i "s/^TF_VAR_softnas_volatile=.*$/TF_VAR_softnas_volatile=${set_softnas_volatile}/" $config_override # ...Set if softnas volumes will be destroyed
source $TF_VAR_firehawk_path/update_vars.sh --$TF_VAR_envtier --var-file config-override --force --silent

set_pipe() {
  id=$1
  ### Initialisation for new resources occur after a destroy operation, since the infra is garunteed to be new after his point.
  sed -i "s/^TF_VAR_active_pipeline=.*$/TF_VAR_active_pipeline=${id}/" $config_override # ...Enable the vpc.
  source $TF_VAR_firehawk_path/update_vars.sh --$TF_VAR_envtier --var-file config-override --force --silent
  echo "Get TF_VAR_active_pipeline: $TF_VAR_active_pipeline"
  sed -i "s/^TF_VAR_key_name=.*$/TF_VAR_key_name=my_key_pair_pipeid${TF_VAR_active_pipeline}_${TF_VAR_envtier}/" $config_override
  source $TF_VAR_firehawk_path/update_vars.sh --$TF_VAR_envtier --var-file config-override --force --silent
  echo "Get TF_VAR_key_name: $TF_VAR_key_name"
  key_path="/secrets/keys/${TF_VAR_key_name}.pem"
  echo "Get key_path: $key_path"
  sed -i "s~^TF_VAR_local_key_path=.*$~TF_VAR_local_key_path=${key_path}~" $config_override
  source $TF_VAR_firehawk_path/update_vars.sh --$TF_VAR_envtier --var-file config-override --force --silent
  echo "Get TF_VAR_local_key_path: $TF_VAR_local_key_path"
}

test_destroyed() {
  echo "...Currently running instances: scripts/aws-running-instances.sh"
  $TF_VAR_firehawk_path/scripts/aws-running-instances.sh
  echo ""

  lines=$($TF_VAR_firehawk_path/scripts/aws-running-instances.sh | wc -l)
  if [ "$lines" -gt "0" ]; then
    echo "instances are running"
  else
    echo "instances are not running"
  fi

  # test if the destroy command worked
  if [ "$lines" -gt "0" ] && [[ "$tf_action" == "destroy" ]]; then 
    echo "failed to destroy all running instances for the account"
    exit 1
  fi

  printf "\n...Currently existing users in the aws account"
  aws iam list-users
  echo ""

  user_present=$(aws iam list-users | grep -c "deadline_spot_deployment_user") || echo "Suppress Exit Code"
  if [ "$user_present" -gt "0" ]; then
    echo "deadline_spot_deployment_user is present"
  else
    echo "deadline_spot_deployment_user not present"
  fi

  if [ "$user_present" -gt "0" ] && [[ "$tf_action" == "destroy" ]]; then 
    echo "failed to destroy existing deadline_spot_deployment_user for the account"
    exit 1
  fi
}

if [[ -z $TF_VAR_envtier ]] ; then
  echo "Error! you must specify an environment --dev or --prod" 1>&2
  exit 64
else
  echo "init_vm_config: $init_vm_config"
  if [[ "$TF_VAR_vm_initialised" == false ]] && [[ "$init_vm_config" == true ]]; then
    echo "...Init VM's"
    echo "...Provision PGP / Keybase"
    $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-010-keybase.sh $ARGS; exit_test
    echo "...Provision Local VM's"
    $TF_VAR_firehawk_path/scripts/init-openfirehawkserver-020-init.sh $ARGS; exit_test
    set +x
    sed -i "s/^TF_VAR_vm_initialised=.*$/TF_VAR_vm_initialised=true/" $config_override # ...set the vm as having been initalised in config vars.
    source $TF_VAR_firehawk_path/update_vars.sh --$TF_VAR_envtier --var-file config-override --force --silent
  else
    echo "...Bypassing Init VM's"
  fi

  if [[ "$tf_action" == "destroy" ]]; then
    echo "...Currently running instances: scripts/aws-running-instances.sh"
    $TF_VAR_firehawk_path/scripts/aws-running-instances.sh
    printf "\n...Currently existing users in the aws account"
    aws iam list-users
    echo ""

    touch $TF_VAR_local_key_path # ensure a file is present or tf will not be able to destroy anything.

    success=false
    echo "...Terraform destroy" # first try to destroy without refresh, which may hang on missing vars.
    if terraform destroy -lock=false --auto-approve; then success=true; fi
    
    if [[ "$success" == false ]]; then
      echo "...Last destroy attempt failed."
      echo "...Terraform refresh"
      if terraform refresh -lock=false; then
        echo "...Terraform destroy"
        if terraform destroy -lock=false --auto-approve; then success=true; fi
      fi
    fi

    if [[ "$success" == false ]]; then
      echo "...Last destroy attempts failed.  terraform.tfstate is likely corrupted, we will restore from backup and attempt destroy again."
      cp -fv terraform.tfstate.backup terraform.tfstate
      if terraform refresh -lock=false; then
        echo "...Terraform destroy from terraform.tfstate.backup"
        if terraform destroy -lock=false --auto-approve; then success=true; fi
      fi
    fi
    
    if [[ "$success" == false ]]; then
      echo "ERROR: verify there are no orphaned resources after this run...Couldn't recover backup."
      echo "...Removing terraform.tfstate for clean start."
      rm -fv terraform.tfstate; exit_test
    fi

    if [ -f terraform.tfstate ]; then
      echo "...Removing terraform.tfstate for clean start."
      rm -fv terraform.tfstate; exit_test
    fi
    echo "...Ensuring aws key is destroyed for current pipe."
    ansible-playbook -vv -i "$TF_VAR_inventory" ansible/aws-new-key.yaml --extra-vars "destroy=true"; exit_test # destroy the key from the aws account and on disk
    test_destroyed; exit_test # check no resources exist anymore, then set pipe to 0 to allow init on next run
    set_pipe 0 # if resources are accidentally created, they would now have an id of 0, which should never happen, but this provides a safeguard.  if the active pipeline var is 0, this is used to initialise.

    # terraform init; exit_test # Required to initialise any new modules
  fi

  if [[ "$tf_init" == true ]]; then
    # echo "...Currently running instances: scripts/aws-running-instances.sh" # wont work if vm isn't initialised
    # $TF_VAR_firehawk_path/scripts/aws-running-instances.sh
    # echo ""
    
    echo "...Terraform Init"
    terraform init; exit_test # Required to initialise any new modules
  fi

  echo "TF_VAR_taint_single: ${TF_VAR_taint_single[*]}"
  cat $TF_VAR_secrets_path/config-override-$TF_VAR_envtier
  echo ""

  IFS=' ' # need to define whitespace seperator

  # eval TF_VAR_taint_single=${TF_VAR_taint_single}
  # export TF_VAR_taint_single=${TF_VAR_taint_single}
  # if [[ "$TF_VAR_taint_single"=='""' ]]; then echo 'unset TF_VAR_taint_single'; unset TF_VAR_taint_single; fi
  # if [[ "$TF_VAR_taint_single"=="" ]]; then echo 'unset TF_VAR_taint_single'; unset TF_VAR_taint_single; fi

  if [[ "$tf_action" == "apply" ]]; then
    
    $TF_VAR_firehawk_path/scripts/detect-interrupt.sh &
    
    if [ "$TF_VAR_active_pipeline" -eq 0 ]; then
      echo "...Init new pipe based on the current JOB ID: Found active pipeline is init: $TF_VAR_active_pipeline"
      set_pipe $TF_VAR_CI_JOB_ID # initalise all new resources with this pipe id
      echo "...Ensuring aws key exists for current pipe."
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-new-key.yaml; exit_test # ensure an aws pem key exists for ssh into cloud nodes
      rm -fr $TF_VAR_firehawk_path/.initpipe # remove old init file.
      ### End init new infra id and prerequisites
    fi

    if [[ "$fast" == true ]]; then
      echo "Fast start.  Skip refresh"
    else
      echo "TF_VAR_fast: $TF_VAR_fast"
      echo "...Terraform refresh"
      terraform refresh -lock=false; exit_test
    fi

    echo "...Terraform state"
    terraform state list

    if [ ! -z "$TF_VAR_taint_single" ]; then
      echo "iterate through array: ${TF_VAR_taint_single[*]}"
      # Iterate the string variable using for loop
      for item in "${TF_VAR_taint_single[@]}"; do echo "terraform taint $item"; done

      echo "...Finding Resources to taint: ${TF_VAR_taint_single[*]}"
      found=false
      for item in "${TF_VAR_taint_single[@]}"; do
        echo "Check item: $item"
        test_string="${item%[*}" # ignore the brackets on resources
        if terraform state list | grep -q $test_string; then 
          echo "Resource exists, will taint."
          found=true
          terraform taint -lock=false $item || echo "Suppress Exit Code"
        fi
      done
      if [ "$found" == false ]; then echo "No Resources were Tainted"; fi
    fi
    set +x
    echo "...Currently running instances: scripts/aws-running-instances.sh"
    $TF_VAR_firehawk_path/scripts/aws-running-instances.sh
    echo ""
    
    set -o pipefail # Allow exit status of last command to fail to catch errors after pipe for ts function.

    echo "TF_VAR_active_pipeline: $TF_VAR_active_pipeline"
    
    echo "...Start Terraform"
    echo "...Terraform apply"
    terraform apply -lock=false --auto-approve; exit_test
    
  elif [[ "$tf_action" == "sleep" ]]; then
    echo "...Currently running instances: scripts/aws-running-instances.sh"
    $TF_VAR_firehawk_path/scripts/aws-running-instances.sh
    echo ""
    echo "...Terraform refresh"
    terraform refresh -lock=false; exit_test

    echo "...Terraform sleep"
    terraform apply -lock=false --auto-approve -var sleep=true
  elif [[ "$tf_action" == "single_test" ]]; then
    echo "...Test a singular one off command"; set -x
    $TF_VAR_firehawk_path/scripts/single-test.sh
    set +x
  fi



  if [[ "$deadline_action" == "stop" ]]; then
    echo "...Stopping Deadline DB with playbook"
    ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-stop.yaml -v; exit_test
  elif [[ "$deadline_action" == "start" ]]; then
    echo "...Starting Deadline DB with playbook"
    ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-start.yaml -v; exit_test
  fi

fi

echo "$(date) Finished a run" | tee -a tmp/log/run_log.txt
printf '\n...Show previous 5 runs\n'
tail -n 5 tmp/log/run_log.txt

# only if there are tf actions do we check running instances, otherwise we can't asume the aws cli is installed yet when none
echo "tf_action: $tf_action"
if [ "$tf_action" != "none" ]; then 
  test_destroyed; exit_test
fi