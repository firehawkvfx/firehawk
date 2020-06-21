#!/usr/bin/env bash
set +x
# the purpose of this script is to:
# 1) set envrionment variables as defined in the encrypted secrets/secrets-prod file
# 2) consistently rebuild the secrets-general.template file based on the variable names found in the secrets-prod file.
#    This generated template will never/should never have any secrets stored in it since it is commited to version control.
#    The purpose of this script is to ensure that the template for all users remains consistent.
# 3) Example values for the secrets-general.template file are defined in secrets.example. Ensure you have placed an example key=value for any new vars in secrets.example. 
# If any changes have resulted in a new variable name, then example values helps other understand what they should be using for their own infrastructure.

RED='\033[0;31m' # Red Text
GREEN='\033[0;32m' # Green Text
BLUE='\033[0;34m' # Blue Text
NC='\033[0m' # No Color        
# the directory of the current script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


printf "\n${RED}Warning: Currently virtual box requires a version lock after installing:${NC}\n"
echo "6.1.10 had problems with centos 7 and gnome 2020/07/07. Ensure you use the version below, or update with caution:"
echo "yum install VirtualBox-6.1-6.1.8_137981_el7-1.x86_64 versionlock; yum versionlock add VirtualBox-6.1-6.1.8_137981_el7-1.x86_64"

# This block allows you to echo a line number for a failure.
# err_report() {
#     echo "${BASH_SOURCE[0]}: $1 script err_report: Error on line $2"
# }
# trap 'err_report $0 $LINENO' ERR

echo_if_not_silent() {
    if [[ -z "$silent" ]] || [[ "$silent" == false ]]; then echo $1; fi
}

echo_if_not_silent "Running ansiblecontrol with $1..."

# These paths and vars are necesary to locating other scripts.
export TF_VAR_firehawk_path=$SCRIPTDIR
# source an exit test to bail if non zero exit code is produced.
. $TF_VAR_firehawk_path/scripts/exit_test.sh
function to_abs_path {
    local target="$1"
    if [ "$target" == "." ]; then
        echo "$(readlink -m $(pwd))"
    elif [ "$target" == ".." ]; then
        echo "$(readlink -m $(dirname "$(pwd)"))"
    else
        echo "$(readlink -m $(cd "$(dirname "$1")"; pwd)/$(basename "$1"))"
    fi
}
export TF_VAR_secrets_path="$(to_abs_path $TF_VAR_firehawk_path/../secrets)"; exit_test

mkdir -p $TF_VAR_firehawk_path/tmp/
mkdir -p $TF_VAR_firehawk_path/tmp/log
mkdir -p $TF_VAR_secrets_path/keys

# The template will be updated by this script
save_template=true
export tmp_template_path=$TF_VAR_firehawk_path/tmp/secrets.template
touch $tmp_template_path
rm $tmp_template_path
temp_output=$TF_VAR_firehawk_path/tmp/secrets.temp
touch $temp_output
rm $temp_output

failed=false
verbose=false

encrypt_mode="encrypt"

# IFS must allow us to iterate over lines instead of words seperated by ' '
IFS='
'
optspec=":hv-:t:"

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
                    box-file-in)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    box-file-in=*)
                        ;;
                    vault)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    vault=*)
                        ;;
                    vagrant)
                        ;;
                    live-terminal)
                        export LIVE_TERMINAL=true
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

if [ -z "$CI_COMMIT_REF_SLUG" ]; then # Detect the environment if using CI/CD
    echo "Launching in a non Gitlab CI environment"; export env_ci=false
else
    echo "Gitlab CI Environment with branch: $CI_COMMIT_REF_SLUG"; export env_ci=true
    if [[ "$CI_COMMIT_REF_SLUG" == "stage" || "$CI_COMMIT_REF_SLUG" == "master" ]]; then
        export TF_VAR_envtier='prod'
    else
        export TF_VAR_envtier='dev'
    fi
    keys_path=~/firehawk-rollout-$TF_VAR_envtier/secrets/keys/.
    echo "...Copying $TF_VAR_envtier keys from: $keys_path to: $TF_VAR_secrets_path"
    cp -r $keys_path $TF_VAR_secrets_path/keys/.
fi

tier () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing tier option: '--${opt}', value: '${val}'" >&2;
    fi
    export TF_VAR_envtier=$val
}

export var_file=

var_file () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing var_file option: '--${opt}', value: '${val}'" >&2;
    fi
    export var_file="${val}"
}

export box_file_in=""
export ansiblecontrol_box="bento/ubuntu-16.04"
export firehawkgateway_box="bento/ubuntu-16.04"

echo_if_not_silent "box - ansiblecontrol_box $ansiblecontrol_box"

box_file_in () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing box_file_in option: '--${opt}', value: '${val}'" >&2;
    fi
    export box_file_in="${val}"
    export ansiblecontrol_box="ansiblecontrol-${val}.box"
    export firehawkgateway_box="firehawkgateway-${val}.box"
}

save_template_fn () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing var_file option: '--${opt}', value: '${val}'" >&2;
    fi 
    save_template=${val}
    
    if [[ $save_template = false ]]; then
        echo "...Will skip saving of template"
    fi
}

vault () {
    echo "verbose=$verbose"
    if [[ "$verbose" == true ]]; then
        echo "Parsing tier option: '--${opt}', value: '${val}'" >&2;
    fi
    if [[ $val = 'encrypt' || $val = 'decrypt' || $val = 'none' ]]; then
        export encrypt_mode=$val
    else
        printf "\n${RED}ERROR: valid modes for encrypt are:\nencrypt, decrypt or none. Enforcing encrypt mode as default.${NC}\n"
        export encrypt_mode='encrypt'
        failed=true
    fi
}

function help {
    echo "usage: source ./update_vars.sh [-v] [--tier[=]dev/prod] [--var-file[=]deployuser/secrets] [--vault[=]encrypt/decrypt]" >&2
    printf "\nUse this to source either the vagrant or encrypted secrets config in your dev or prod tier.\n" &&
    failed=true
}

# We allow equivalent args such as:
# -t dev
# --tier dev
# --tier=dev
# which each results in the same function tier() running.

force=false
silent=false

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
                    help)
                        help
                        ;;
                    save-template)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        save_template_fn
                        ;;
                    save-template=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        save_template_fn
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
                    force)
                        force=true
                        ;;
                    silent)
                        silent=true
                        ;;
                    vagrant)
                        val="vagrant"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        var_file
                        ;;
                    secrets)
                        val="secrets"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        var_file
                        ;;
                    init)
                        val="init"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        var_file
                        ;;
                    decrypt)
                        val="decrypt"; OPTIND=$(( $OPTIND + 1 ))
                        opt="vault"
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

# if any parsing failed this is the correct method to parse an exit code of 1 whether executed or sourced

[ "$BASH_SOURCE" == "$0" ] &&
    echo "This file is meant to be sourced, not executed" && 
        exit 30

if [[ $failed = true ]]; then    
    return 88
fi

mkdir -p "$TF_VAR_firehawk_path/config/defaults"
template_path="$TF_VAR_firehawk_path/config/templates/secrets-general.template"

echo_if_not_silent '...Get secrets from env'
# # map environment secret for current env
# if [[ "$TF_VAR_envtier" = 'dev' ]]; then
#     if [[ ! -z "$firehawksecret_dev" ]]; then
#         echo "...Aquiring firehawksecret from dev"
#         export firehawksecret="$firehawksecret_dev"
#         export testsecret="$testsecret_dev"
#         echo "...Aquired firehawksecret from dev"
#     fi
# elif [[ "$TF_VAR_envtier" = 'prod' ]]; then
#     if [[ ! -z "$firehawksecret_prod" ]]; then
#         echo "...Aquiring firehawksecret from prod"
#         export firehawksecret="$firehawksecret_prod"
#         export testsecret="$testsecret_prod"
#         echo "...Aquired firehawksecret from prod"
#     fi
# fi
if [[ ! -z "$firehawksecret" ]]; then
    echo "...Aquiring firehawksecret"
    export firehawksecret="$firehawksecret"
    export testsecret="$testsecret"
    echo "...Aquired firehawksecret"
fi

# init config override
export config_override=$(to_abs_path $TF_VAR_secrets_path/config-override-$TF_VAR_envtier) # ...Config Override path $config_override.
export config_path=$(to_abs_path $TF_VAR_secrets_path/config)

echo_if_not_silent '...Check for configuration, init if not present.'
if [ ! -f $config_override ]; then
    echo_if_not_silent "...Initialising $config_override"
    cp "$TF_VAR_firehawk_path/config/defaults/defaults-config-override-$TF_VAR_envtier" "$config_override"
fi

current_version=$(cat $config_override | sed -e '/.*defaults_config_overide_version=.*/!d')
target_version=$(cat $TF_VAR_firehawk_path/config/defaults/defaults-config-override-$TF_VAR_envtier | sed -e '/.*defaults_config_overide_version=.*/!d')

if [[ "$target_version" != "$current_version" ]]; then
    echo "...Version doesn't match config.  Initialising $config_override"
    cp "$TF_VAR_firehawk_path/config/defaults/defaults-config-override-$TF_VAR_envtier" "$config_override"
fi

# init defaults
defaults_file=$(to_abs_path $TF_VAR_secrets_path/defaults) # ...Config Override path $defaults_file.

echo_if_not_silent '...Check for configuration, init if not present.'
if [ ! -f $defaults_file ]; then
    echo_if_not_silent "...Initialising $defaults_file"
    cp "$TF_VAR_firehawk_path/config/defaults/defaults" "$defaults_file"
fi

current_version=$(cat $defaults_file | sed -e '/.*defaults_=.*/!d')
target_version=$(cat $TF_VAR_firehawk_path/config/defaults/defaults | sed -e '/.*defaults=.*/!d')

if [[ "$target_version" != "$current_version" ]]; then
    echo "...Version doesn't match config.  Initialising $defaults_file"
    cp "$TF_VAR_firehawk_path/config/defaults/defaults" "$defaults_file"
fi



### The dynamic vars here are set by the environment during dpeloyment, and commit messages for gitlab ci.
# x='1' 

# if [ -z ${CI_JOB_ID+x} ]; then
#     echo "CI_JOB_ID is not set.  defaulting to $x or it will be aquired by the config override file"

if [ -z ${CI_JOB_ID+x} ]; then # if pipeline id is provided, set it in the file.  note this is not always the pipeline id that should be used for tags, since we preserve the id used during an init step.  That pipeline id becomes the tag until the next destroy/init step.
    echo "CI_JOB_ID is not set, will not alter config."
else
    echo "CI_JOB_ID is set to '$CI_JOB_ID'"
    echo "...Set CI_JOB_ID at config_override path- $config_override"
    sed -i "s/^TF_VAR_CI_JOB_ID=.*$/TF_VAR_CI_JOB_ID=${CI_JOB_ID}/" $config_override # ...Enable the vpc.
fi

export TF_VAR_CI_JOB_ID=$(cat $config_override | sed -e '/.*TF_VAR_CI_JOB_ID=.*/!d')

x=false
if [ -z ${TF_VAR_fast+x} ]; then
    echo_if_not_silent "TF_VAR_fast is unset.  defaulting to $x or it will be aquired by the config override file"
else
    echo_if_not_silent "TF_VAR_fast is set to '$TF_VAR_fast'"
    echo_if_not_silent "...Set TF_VAR_fast at config_override path- $TF_VAR_fast"
    sed -i "s/^TF_VAR_fast=.*$/TF_VAR_fast=${TF_VAR_fast}/" $config_override # ...Enable the vpc.
    export TF_VAR_fast=$(cat $config_override | sed -e '/.*TF_VAR_fast=.*/!d')
fi

source_vars () {
    local var_file=$1
    local encrypt_mode=$2

    echo_if_not_silent "...Sourcing var_file $var_file"
    # If initialising vagrant vars, no encryption is required
    if [[ -z "$var_file" ]] || [[ "$var_file" = "secrets" ]]; then
        var_file="secrets-general"
        echo_if_not_silent "...Using vault file $var_file"
        template_path="$TF_VAR_firehawk_path/config/templates/secrets-general.template"
    elif [[ "$var_file" = "vagrant" ]]; then
        echo_if_not_silent '...Using variable file vagrant. No encryption/decryption needed for these contents.'
        encrypt_mode="none"
        template_path="$TF_VAR_firehawk_path/config/templates/vagrant.template"
    elif [[ "$var_file" = "config" ]]; then
        echo_if_not_silent '...Using variable file config. No encryption/decryption needed for these contents.'
        encrypt_mode="none"
        template_path="$TF_VAR_firehawk_path/config/templates/config.template"
    elif [[ "$var_file" = "defaults" ]]; then
        echo_if_not_silent '...Using variable file defaults. No encryption/decryption needed for these contents.'
        encrypt_mode="none"
        template_path="$TF_VAR_firehawk_path/config/templates/defaults.template" # These should be removed but need alter the system to do it properly.
    elif [[ "$var_file" = "config-override" ]]; then
        var_file="config-override-$TF_VAR_envtier"
        echo_if_not_silent "...Using variable file $var_file. No encryption/decryption needed for these contents."
        encrypt_mode="none"
        template_path="$TF_VAR_firehawk_path/config/templates/config-override.template" # These should be removed but need alter the system to do it properly.
    elif [[ "$var_file" = "resources" ]]; then
        var_file="resources-$TF_VAR_resourcetier"
        echo_if_not_silent "...Using variable file $var_file. No encryption/decryption needed for these contents."
        encrypt_mode="none"
        template_path="$TF_VAR_firehawk_path/config/templates/resources.template" # These should be removed but need alter the system to do it properly.
    else
        printf "\nUnrecognised vault/variable file. \n$var_file\nExiting...\n"
        failed=true
    fi

    if [[ $failed = true ]]; then
        return 88
    fi

    # After a var file is source we also store the modified date of that file as a dynamic variable name.  if the modified date of the file on the next run is identical to the environment variable, then it doesn't need to be sourced again.  This allows detection of the contents being changed and sourcing the file if true.

    var_file_basename="$(echo $var_file | tr '-' '_')"
    var_file="$(to_abs_path $TF_VAR_secrets_path/$var_file)"; exit_test

    # echo "...Test modified date"
    file_modified_date=$(date -r $var_file)
    var_modified_date_name="modified_date_${var_file_basename}"
    var_modified_date="${!var_modified_date_name}"
    # echo "existing modified date variable= ${var_modified_date}"
    # echo "compare with file modified date= ${file_modified_date}"

    encrypt_required=false
    if [[ $encrypt_mode = "encrypt" ]]; then
        line=$(head -n 1 $var_file)
        if [[ "$line" == "\$ANSIBLE_VAULT"* ]]; then 
            #echo "Vault is already encrypted"
            encrypt_required=false
        else
            #echo "Encrypting secrets with a key on disk and with a password. Vars will be set from an encrypted vault."
            encrypt_required=true
        fi
    fi

    if [ "$var_modified_date" == "$file_modified_date" ] && [ ! -z "$var_modified_date" ] && [[ "$encrypt_mode" != "decrypt" ]] && [[ $encrypt_required == false ]] && [[ $force == false ]]; then
        printf "\n${BLUE}Skipping source ${var_file_basename}: last time this var file was sourced the modified date matches the current file.  No need to source the file again.${NC}\n"
    else
        printf "\n${GREEN}Will source ${var_file_basename}. encrypt_mode = $encrypt_mode ${NC}\n"
        # set vault key location based on envtier dev/prod
        if [[ "$TF_VAR_envtier" = 'dev' ]]; then
            export vault_key="$(to_abs_path $TF_VAR_secrets_path/keys/$TF_VAR_vault_key_name_general)"
            echo_if_not_silent "set vault_key $vault_key"
        elif [[ "$TF_VAR_envtier" = 'prod' ]]; then
            export vault_key="$(to_abs_path $TF_VAR_secrets_path/keys/$TF_VAR_vault_key_name_general)"
            echo_if_not_silent "set vault_key $vault_key"
        else 
            printf "\n...${RED}WARNING: envtier evaluated to no match for dev or prod.  Inspect update_vars.sh to handle this case correctly.${NC}\n"
            return 88
        fi
        # We use a local key and a password to encrypt and decrypt data.  no operation can occur without both.  in this case we decrypt first without password and then with the password.
        
        # If the encrypted secret is passed as an environment variable, then secrets can be passed after the secret itself is decrypted by the key.
        if [[ ! -z "$firehawksecret" ]]; then
            echo_if_not_silent "...Using firehawksecret encrypted env var to decrypt instead of user input."
            if [ ! -f scripts/ansible-encrypt.sh ]; then
                echo "FILE NOT FOUND: scripts/ansible-encrypt.sh"
                echo "Check existance of $TF_VAR_firehawk_path/scripts/ansible-encrypt.sh"
            fi
            vault_command="ansible-vault view --vault-id $vault_key --vault-id $vault_key@scripts/ansible-encrypt.sh $var_file"
        else
            echo "Prompt user for password:"
            vault_command="ansible-vault view --vault-id $vault_key --vault-id $vault_key@prompt $var_file"
        fi
        

        if [[ $encrypt_mode != "none" ]]; then
            #check if a vault key exists.  if it does, then install can continue automatically.
            if [ -e $vault_key ]; then
                if [[ $verbose ]]; then
                    path=$(to_abs_path $vault_key)
                    printf "\n$vault_key exists. vagrant up will automatically provision.\n\n"
                fi
            else
                printf "\n$vault_key doesn't exist.\n\n"
                printf "\nNo vault key has been initialised at this location.\n\n"
                PS3='Do you wish to initialise a new vault key?'
                options=("Initialise A New Key" "Quit")
                select opt in "${options[@]}"
                do
                    case $opt in
                        "Initialise A New Key")
                            printf "\n${RED}WARNING: DO NOT COMMIT THESE KEYS TO VERSION CONTROL.${NC}\n"
                            openssl rand -base64 64 > $vault_key || failed=true
                            break
                            ;;
                        "Quit")
                            echo "You selected $REPLY to $opt"
                            quit=true
                            break
                            ;;
                        *) echo "invalid option $REPLY";;
                    esac
                done
                
            fi
        fi

        if [[ $failed = true ]]; then    
            echo "${RED}WARNING: Failed to create key.${NC}"
            return 88
        fi

        if [[ $quit = true ]]; then    
            return 88
        fi

        # vault arg will set encryption mode
        if [[ $encrypt_mode = "encrypt" ]]; then
            echo "Encrypting Vault..."
            line=$(head -n 1 $var_file)
            if [[ "$line" == "\$ANSIBLE_VAULT"* ]]; then 
                echo "Vault is already encrypted"
            else
                echo "Encrypting secrets with a key on disk and with a password. Vars will be set from an encrypted vault."
                ansible-vault encrypt --vault-id $vault_key@prompt $var_file; exit_test
            fi
        elif [[ $encrypt_mode = "decrypt" ]]; then
            echo "Decrypting Vault... $var_file"
            line=$(head -n 1 $var_file)
            if [[ "$line" == "\$ANSIBLE_VAULT"* ]]; then 
                echo "Found encrypted vault"
                echo "Decrypting secrets."
                ansible-vault decrypt --vault-id $vault_key --vault-id $vault_key@prompt $var_file; exit_test
            else
                echo "Vault already unencrypted.  No need to decrypt. Vars will be set from unencrypted vault."
            fi
            printf "\n${RED}WARNING: Never commit unencrypted secrets to a repository/version control. run this command again without --decrypt before commiting any secrets to version control.${NC}"
            printf "\nIf you accidentally do commit unencrypted secrets, ensure there is no trace of the data in the repo, and invalidate the secrets / replace them.\n"
                
            export vault_command="cat $var_file"
        elif [[ $encrypt_mode = "none" ]]; then
            echo_if_not_silent "Assuming variables are not encrypted to set environment vars"
            export vault_command="cat $var_file"
        fi

        if [[ $verbose = true ]]; then
            printf "\n"
            echo "TF_VAR_envtier=$TF_VAR_envtier"
            echo "var_file=$var_file"
            echo "vault_key=$vault_key"
            echo "encrypt_mode=$encrypt_mode"
        fi

        export vault_examples_command="cat $TF_VAR_firehawk_path/secrets.example"

        ### Use the vault command to iterate over variables and export them without values to the template

        if [[ $encrypt_mode = "none" ]]; then
            echo_if_not_silent "...Parsing unencrypted file to template.  No decryption necesary."
        else
            echo_if_not_silent "...Parsing vault file to template.  Decrypting."
            echo "vault_command=$vault_command"
        fi

        local multiline; multiline=$(eval $vault_command); exit_test
        for i in $(echo "$multiline" | sed 's/^$/###/')
        do
            if [[ "$i" =~ ^#.*$ ]]
            then
                # replace ### blank line placeholder for user readable temp_output and respect newlines
                if [[ $verbose = true ]]; then
                    echo "line= $i"
                fi
                echo "${i#"###"}" >> $temp_output
            else
                # temp_output original line to file without value
                if [[ $verbose = true ]]; then
                    echo "var= ${i%%=*}"
                fi
                echo "${i%%=*}=insertvalue" >> $temp_output
            fi
        done

        # substitute example var values into the template.
        envsubst < "$temp_output" > "$tmp_template_path"
        rm $temp_output # remove temp so as to not accumulate results

        echo_if_not_silent "...Exporting variables to environment"
        # # Now set environment variables to the actual values defined in the user's secrets-prod file
        for i in $(echo "$multiline")
        do
            [[ "$i" =~ ^#.*$ ]] && continue
            key=${i%=*}
            value=${i#*=}
            eval value=$value # This method should eval strings withhout quotes remaining in the var
            # echo "$key : $value"
            export "$key=$value" # Export the environment var
        done

        # # Determine your current public ip for security groups.

        export TF_VAR_remote_ip_cidr="$(dig +short myip.opendns.com @resolver1.opendns.com)/32"

        # # this python script generates mappings based on the current environment.
        # # any var ending in _prod or _dev will be stripped and mapped based on the envtier
        python $TF_VAR_firehawk_path/scripts/envtier_vars.py; exit_test
        envsubst < "$TF_VAR_firehawk_path/tmp/envtier_mapping.txt" > "$TF_VAR_firehawk_path/tmp/envtier_exports.txt"

        # Next- using the current envtier environment, evaluate the variables for the that envrionment.  
        # variables ending in _dev or _prod will take precedence based on the envtier, and be set to keys stripped of the appended _dev or _prod namespace
        for i in `cat $TF_VAR_firehawk_path/tmp/envtier_exports.txt`
        do
            [[ "$i" =~ ^#.*$ ]] && continue
            export $i
        done

        rm $TF_VAR_firehawk_path/tmp/envtier_exports.txt

        # lastly update the vault key path
        # set vault key location based on envtier dev/prod
        if [[ "$TF_VAR_envtier" = 'dev' ]]; then
            export vault_key="$(to_abs_path $TF_VAR_secrets_path/keys/$TF_VAR_vault_key_name_general)"
            echo_if_not_silent "set vault_key $vault_key"
        elif [[ "$TF_VAR_envtier" = 'prod' ]]; then
            export vault_key="$(to_abs_path $TF_VAR_secrets_path/keys/$TF_VAR_vault_key_name_general)"
            echo_if_not_silent "set vault_key $vault_key"
        else 
            printf "\n...${RED}WARNING: envtier evaluated to no match for dev or prod.  Inspect update_vars.sh to handle this case correctly.${NC}\n"
            return 88
        fi

        # update the template if in dev environment and save template is enabled.  save template may be disabled during setup script
        if [[ "$TF_VAR_envtier" = 'dev' && $save_template = true ]]; then
            echo_if_not_silent "save_template: $save_template"
            # The template will now be written to the public repository without any private values
            echo_if_not_silent "...Saving template to $template_path"
            mv -fv $tmp_template_path $template_path
        elif [[ "$TF_VAR_envtier" = 'prod' ]]; then
            echo_if_not_silent "...Bypassing saving of template to public repository since we are in a prod environment.  Writes to the Firehawk repository path are only done in the dev environment."
            rm -fv $tmp_template_path
        elif [[ $save_template = false ]]; then
            echo_if_not_silent "...Skipping saving of template"
        else 
            printf "\n...${RED}WARNING: envtier evaluated to no match for dev or prod.  Inspect update_vars.sh to handle this case correctly.${NC}\n"
            return 88
        fi

        # after completion, we store the modified date of the var file after encryption to compare in future if we must source again.
        echo_if_not_silent "Set date for $var_file modified_date_${var_file_basename}"
        export modified_date_${var_file_basename}=$(date -r $var_file)
    fi
}

if [[ "$TF_VAR_envtier" = 'dev' ]] || [[ "$TF_VAR_envtier" = 'prod' ]]; then
    # check for valid environment
    echo_if_not_silent "...Using environment $TF_VAR_envtier"
else 
    printf "\n...${RED}WARNING: envtier evaluated to no match for dev or prod.  Inspect update_vars.sh to handle this case correctly.${NC}\n"
    return 88
fi

# if sourcing secrets, we also source the vagrant file, unencrypted config file and config ovverrides
if [[ "$var_file" = "secrets" ]] || [[ -z "$var_file" ]]; then
    # assume secrets is the var file for default behaviour
    source_vars 'vagrant' 'none'; exit_test
    source_vars 'defaults' 'none'; exit_test
    source_vars 'config' 'none'; exit_test
    # override the var_file at this point.
    var_file = 'secrets'; exit_test
    source_vars 'secrets' "$encrypt_mode"; exit_test
    var_file = 'config-override'; exit_test
    source_vars 'config-override' 'none'; exit_test
    var_file = 'resources'; exit_test
    source_vars 'resources' 'none'; exit_test
elif [[ "$var_file" = "init" ]]; then
    # assume secrets is the var file for default behaviour
    source_vars 'vagrant' 'none'; exit_test
    source_vars 'defaults' 'none'; exit_test
    source_vars 'config' 'none'; exit_test
    # override the var_file at this point.
    var_file = 'config-override'; exit_test
    source_vars 'config-override' 'none'; exit_test
    var_file = 'resources'; exit_test
    source_vars 'resources' 'none'; exit_test
else
    source_vars "$var_file" "$encrypt_mode"; exit_test
fi

echo_if_not_silent "...Current pipeline vars:"
echo_if_not_silent "TF_VAR_active_pipeline: $TF_VAR_active_pipeline"

# echo "Ensure inventory directory exists: $TF_VAR_inventory"
# mkdir -p $TF_VAR_inventory
# echo "TF_VAR_aws_key_name: $TF_VAR_aws_key_name"
# echo "TF_VAR_aws_private_key_path: $TF_VAR_aws_private_key_path"
echo_if_not_silent "...Done."

if [[ "$SHOWCOMMANDS" == true ]]; then set -x; fi # After finishing the script, we enable set -x to show input again.