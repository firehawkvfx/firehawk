#!/bin/bash
# This script is a first stage install that takes a password and uses it to handle encryption in future stages
# echo "Enter Secrets Decryption Password..."
unset HISTFILE

printf "\nRunning ansiblecontrol with $1...\n"

# # This block allows you to echo a line number for a failure.
set -eE -o functrace
err_report() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'err_report ${LINENO} "$BASH_COMMAND"' ERR

# Abort script with correct exit code instead of continuing if non zero exit code occurs.
set -e

tier () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing tier option: '--${opt}', value: '${val}'" >&2;
    fi
    export TF_VAR_envtier=$val
}

box_file_in=
box_file_in () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing box_file_in option: '--${opt}', value: '${val}'" >&2;
    fi
    export box_file_in="${val}"
}

box_file_out=
box_file_out () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing box_file_out option: '--${opt}', value: '${val}'" >&2;
    fi
    export box_file_out="${val}"
    export ansiblecontrol_box_out="ansiblecontrol-${val}.box"
    export firehawkgateway_box_out="firehawkgateway-${val}.box"
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

function help {
    echo "usage: ./firehawk.sh [--dev/prod] [--box-file-in[=]010] [--box-file-out[=]010] [--test-vm]" >&2
    printf "\nUse this to start all infrastructure, optionally creating VM's for testing stages.\n" &&
    failed=true
}

# IFS must allow us to iterate over lines instead of words seperated by ' '
IFS='
'
optspec=":hv-:t:"

test_vm=false
tf_action="apply"

parse_opts () {
    local OPTIND
    OPTIND=0
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    box-file-in)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        box_file_in
                        ;;
                    box-file-in=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        box_file_in
                        ;;
                    box-file-out)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        box_file_out
                        ;;
                    box-file-out=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        box_file_out
                        ;;
                    dev)
                        val="dev";
                        opt="${OPTARG}"
                        tier
                        ;;
                    prod)
                        val="prod";
                        opt="${OPTARG}"
                        tier
                        ;;
                    test-vm)
                        test_vm=true
                        ;;
                    sleep)
                        tf_action='sleep'
                        ;;
                    destroy)
                        tf_action='destroy'
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

# This is the directory of the current script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPTDIR=$(to_abs_path $SCRIPTDIR)
printf "\n...checking scripts directory at $SCRIPTDIR\n\n"
# source an exit test to bail if non zero exit code is produced.
. $SCRIPTDIR/scripts/exit_test.sh

# If not buildinging a package (.box file) and we specify a box file, then it must be the basis to start from
# else if we are building a package, it will be a post process .

# If box file in is defined, then vagrant will use this file in place of the standard image.
if [[ ! -z "$box_file_in" ]] ; then
    source ./update_vars.sh --$TF_VAR_envtier --box-file-in "$box_file_in" --vagrant
else
    source ./update_vars.sh --$TF_VAR_envtier --vagrant
fi
echo "...Finished sourcing"

if [[ "$test_vm" = false ]] ; then # If an encrypted var is provided for the vault key, test decrypt that var before proceeding
    if [[ ! -z "$firehawksecret" ]]; then
        # To manually enter an ecnrypted variable in you configuration use:
        # firehawksecret=$(echo -n "test some input that will be encrypted and stored as an env var" | ansible-vault encrypt_string --vault-id $vault_key --stdin-name firehawksecret | base64 -w 0)
        # That encrypted variable can be extracted here if specified in your environment prior to running this script.
        echo "Aquire firehawksecret..."
        password=$(./scripts/ansible-encrypt.sh --vault-id $vault_key --decrypt $firehawksecret)
        if [[ -z "$password" ]]; then
            echo "ERROR: unable to extract password from defined firehawksecret.  Either remove the firehawksecret variable, or debugging will be required for automation to continue."
            exit 1
        fi
    fi
fi

echo "Vagrant box ansiblecontrol$TF_VAR_envtier in $ansiblecontrol_box"
echo "Vagrant box firehawkgateway$TF_VAR_envtier in $firehawkgateway_box"


vagrant up #; exit_test # ssh reset may cause a non zero exit code, but it must be ignored

if [ "$test_vm" = false ] ; then
    # vagrant reload
    echo "Vagrant SSH config:"
    n=0; retries=100
    until [ $n -ge $retries ]
    do
    vagrant ssh-config && break  # substitute your command here
    n=$[$n+1]
    sleep 15
    done
    if [ $n -ge $retries ]; then
        echo "Error: timed out waiting for vagrant ssh config command - failed."
        exit 1
    fi

    # AFter Vagrant Hosts are up, take the SSH keys and store them in the keys folder for general use.
    ansiblecontrol_key=$(vagrant ssh-config "ansiblecontrol$TF_VAR_envtier" | grep -oP "^  IdentityFile \K.*")
    cp -f $ansiblecontrol_key $TF_VAR_secrets_path/keys/ansible_control_private_key
    firehawkgateway_key=$(vagrant ssh-config firehawkgateway$TF_VAR_envtier | grep -oP "^  IdentityFile \K.*")
    cp -f $firehawkgateway_key $TF_VAR_secrets_path/keys/firehawkgateway_private_key

    hostname=$(vagrant ssh-config "ansiblecontrol$TF_VAR_envtier" | grep -Po '.*HostName\ \K(\d*.\d*.\d*.\d*)')
    port=$(vagrant ssh-config "ansiblecontrol$TF_VAR_envtier" | grep -Po '.*Port\ \K(\d*)')
    
    echo "SSH to vagrant host with..."
    echo "Hostname: $hostname"
    echo "Port: $port"
    echo "tier --$TF_VAR_envtier"

    if [[ ! -z "$hostname" && ! -z "$port" && ! -z "$TF_VAR_envtier" ]]; then
        # use expect to pipe through the password aquired initially.
        if [[ "$tf_action"=="sleep" ]]; then
            echo "...Logging in to Vagrant host to set sleep on tf deployment"
            ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier --sleep" #; exit_test
            echo "...End Deployment"
        elif [[ "$tf_action"=="destroy" ]]; then
            echo "...Logging in to Vagrant host to destroy tf deployment"
            ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier --destroy" #; exit_test
            echo "...End Deployment"
        else
            echo "...Logging in to Vagrant host"
            ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier" #; exit_test
            echo "...End Deployment"
        fi
    fi
fi

if [[ ! -z "$box_file_out" ]]; then
    # If a box_file_out is defined, then we package the images for each box out to files.  The vm will be stopped to eprform this step.
    echo "Set Vagrant box out $ansiblecontrol_box_out"
    echo "Set Vagrant box out $firehawkgateway_box_out"
    [ ! -e $ansiblecontrol_box_out ] || rm $ansiblecontrol_box_out
    [ ! -e $firehawkgateway_box_out ] || rm $firehawkgateway_box_out
    vagrant package "ansiblecontrol$TF_VAR_envtier" --output $ansiblecontrol_box_out &
    vagrant package "firehawkgateway$TF_VAR_envtier" --output $firehawkgateway_box_out
fi