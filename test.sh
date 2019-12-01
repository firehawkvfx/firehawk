#!/usr/bin/env bash

clear

failed=false
verbose=false
optspec=":hv-:t:"
export var_file="../secrets/secrets"
encrypt_mode="encrypt"

verbose () {
    local OPTIND
    OPTIND=0
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    tier)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    tier=*)
                        ;;
                    var_file)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    var_file=*)
                        ;;
                    vault)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    vault=*)
                        ;;
                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            echo "Unknown option --${OPTARG}" >&2
                        fi
                        ;;
                esac;;
            t)
                ;;
            v)
                echo "Parsing option: '-${optchar}'" >&2
                echo "verbose mode"
                verbose=true
                ;;
        esac
    done
}
verbose "$@"

tier () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing tier option: '--${opt}', value: '${val}'" >&2;
    fi
    export TF_VAR_envtier=$val
}

var_file () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing var_file option: '--${opt}', value: '${val}'" >&2;
    fi
    export var_file="../secrets/${val}"
}

vault () {
    echo "verbose=$verbose"
    if [[ "$verbose" == true ]]; then
        echo "Parsing tier option: '--${opt}', value: '${val}'" >&2;
    fi
    if [[ $val = 'encrypt' || $val = 'decrypt' || $val = 'none' ]]; then
        export encrypt_mode=$val
    else
        printf "\nERROR: valid modes for encrypt are:\nencrypt, decrypt or none\n"
        failed=true
    fi
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

# We allow equivalent args such as:
# -t dev
# --tier dev
# --tier=dev
# which each results in the same function tier() running.

#OPTIND=0
parse_opts () {
    local OPTIND
    OPTIND=0
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    tier)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        tier
                        ;;
                    tier=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        tier
                        ;;
                    var_file)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        var_file
                        ;;
                    var_file=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        var_file
                        ;;
                    vault)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        vault
                        ;;
                    vault=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        vault
                        ;;
                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            echo "Unknown option --${OPTARG}" >&2
                        fi
                        ;;
                esac;;
            t)
                val="${OPTARG}"
                opt="${optchar}"
                tier
                ;;
            v) # verbosity is handled prior since its a dependency for this block
                ;;
            h)
                echo "usage: $0 [-v] [--tier[=]<value>]" >&2
                exit 2
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

# if any parsing failed this is the correct method to parse an exit code of 1 whether executed or sourced

[ "$BASH_SOURCE" == "$0" ] &&
    echo "This file is meant to be sourced, not executed" && 
        exit 30

if [[ $failed = true ]]; then    
    return 88
fi

var_file="$(to_abs_path $var_file-$TF_VAR_envtier)"
vault_key="$(to_abs_path ../secrets/keys/.vault-key-$TF_VAR_envtier)"
vault_command="ansible-vault view --vault-id $vault_key $var_file"

#check if a vault key exists.  if it does, then install can continue automatically.
if [ -e ../secrets/keys/.vault-key-$TF_VAR_envtier ]; then
    if [[ $verbose ]]; then
        path=$(to_abs_path $vault_key)
        printf "\n$vault_key exists. vagrant up will automatically provision.\n\n"
    fi
    export TF_VAR_vaultkeypresent='true'
else
    printf "\n$vault_key doesn't exist. vagrant up will not automatically provision.\n\n"
    export TF_VAR_vaultkeypresent='false'
fi

# vault arg will set encryption mode
if [[ $encrypt_mode = "encrypt" ]]; then
    echo "Encrypting Vault..."
    line=$(head -n 1 $var_file)
    if [[ "$line" == "\$ANSIBLE_VAULT"* ]]; then 
        echo "Vault is already encrypted"
    else
        echo "Encrypting secrets. Vars will be set from encrypted vault."
        ansible-vault encrypt --vault-id $vault_key $var_file
    fi
elif [[ $encrypt_mode = "decrypt" ]]; then
    echo "Decrypting Vault..."
    line=$(head -n 1 $var_file)
    if [[ "$line" == "\$ANSIBLE_VAULT"* ]]; then 
        echo "Found encrypted vault"
        echo "Decrypting secrets."
        ansible-vault decrypt --vault-id $vault_key $var_file
    else
        echo "Vault already unencrypted.  No need to decrypt. Vars will be set from unencrypted vault."
    fi
    printf "\nWARNING: Never commit unencrypted secrets to a repo. run this command again without --decrypt before commiting any secrets to version control"
    printf "\nIf you accidentally do commit unencrypted secrets, ensure there is no trace of the data in the repo, and invalidate the secrets / replace them.\n"
        
    export vault_command="cat $var_file"
elif [[ $encrypt_mode = "none" ]]; then
    echo "Assuming secrets are not encrypted to set environment vars"
    export vault_command="cat $var_file"
fi

if [[ $verbose = true ]]; then
    printf "\n"
    echo "TF_VAR_envtier=$TF_VAR_envtier"
    echo "var_file=$var_file"
    echo "vault_key=$vault_key"
    echo "encrypt_mode=$encrypt_mode"
    echo "vault_command=$vault_command"
fi