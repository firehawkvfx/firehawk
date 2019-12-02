#!/usr/bin/env bash

# the purpose of this script is to:
# 1) set envrionment variables as defined in the encrypted secrets/secrets-prod file
# 2) consistently rebuild the secrets.template file based on the variable names found in the secrets-prod file.
#    This generated template will never/should never have any secrets stored in it since it is commited to version control.
#    The purpose of this script is to ensure that the template for all users remains consistent.
# 3) Example values for the secrets.template file are defined in secrets.example. Ensure you have placed an example key=value for any new vars in secrets.example. 
# If any changes have resulted in a new variable name, then example values helps other understand what they should be using for their own infrastructure.

clear

mkdir -p ./tmp/
mkdir -p ../secrets/
# The template will be updated by this script
secrets_template=./secrets.template
touch $secrets_template
rm $secrets_template
temp_output=./tmp/secrets.temp
touch $temp_output
rm $temp_output

failed=false
verbose=false
optspec=":hv-:t:"
export var_file="../secrets/secrets-$TF_VAR_envtier"
encrypt_mode="encrypt"

# IFS will allow for loop to iterate over lines instead of words seperated by ' '
IFS='
'

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
                    var-file)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    var-file=*)
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

var_file=

var_file () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing var_file option: '--${opt}', value: '${val}'" >&2;
    fi
    export var_file="${val}"
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
                    var-file)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        var_file
                        ;;
                    var-file=*)
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


template_path="./secrets.template"
# If initialising vagrant vars, no encryption is required
if [[ -z "$var_file" ]]; then
    var_file="secrets-$TF_VAR_envtier"
    printf "\nUsing vault file $var_file\n"
elif [[ "$var_file" = "vagrant" ]]; then
    printf '\nUsing variable file vagrant. No encryption/decryption will be used\n'
    encrypt_mode="none"
    template_path="./vagrant.template"
else
    printf "\nUnrecognised vault/variable file.  Exiting...\n"
    failed=true
fi

if [[ $failed = true ]]; then
    return 88
fi

var_file="$(to_abs_path ../secrets/$var_file)"
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

export vault_examples_command="cat ./secrets.example"

### Use the vault command to iterate over variables and export them without values to the template

printf "\n...Parsing vault file to template\n"
for i in `(eval $vault_command | sed 's/^$/###/')`
do
    if [[ "$i" =~ ^#.*$ ]]
    then
        # replace ### blank line placeholder for user readable temp_output and respect newlines
        echo "${i#"###"}" >> $temp_output
    else
        # temp_output original line to file without value
        echo "${i%%=*}=insertvalue" >> $temp_output
    fi
done

# substitute example var values into the template.
envsubst < "$temp_output" > "$secrets_template"
rm $temp_output

printf "...Exporting variables to environment\n"
# # Now set environment variables to the actual values defined in the user's secrets-prod file
for i in `eval $vault_command`
do
    [[ "$i" =~ ^#.*$ ]] && continue
    export $i
done

# # Determine your current public ip for security groups.

export TF_VAR_remote_ip_cidr="$(dig +short myip.opendns.com @resolver1.opendns.com)/32"

# # this python script generates mappings based on the current environment.
# # any var ending in _prod or _dev will be stripped and mapped based on the envtier
python ./scripts/envtier_vars.py
envsubst < "./tmp/envtier_mapping.txt" > "./tmp/envtier_exports.txt"

# using the current envtier environment, evaluate the variables
for i in `cat ./tmp/envtier_exports.txt`
do
    [[ "$i" =~ ^#.*$ ]] && continue
    export $i
done

rm ./tmp/envtier_exports.txt

# The template will now be written to the public repository without any private values
printf "\n...Saving template to $template_path\n"
mv -fv $secrets_template $template_path

printf "\nDone.\n\n"