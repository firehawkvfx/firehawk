#!/bin/bash

# This scripts encrypts an input hidden from the shell and base 64 encodes it so it can be stored as an environment variable
# Optionally can also decrypt an environment variable

vault_id_func () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing vault_id_func option: '--${opt}', value: '${val}'" >&2;
    fi
    vault_key="${val}"
}
secret_name=secret
secret_name_func () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing secret_name option: '--${opt}', value: '${val}'" >&2;
    fi
    secret_name="${val}"
}
decrypt=false
decrypt_func () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing secret_name option: '--${opt}', value: '${val}'" >&2;
    fi
    decrypt=true
    encrypted_secret="${val}"
}

IFS='
'
optspec=":hv-:t:"

encrypt=false

parse_opts () {
    local OPTIND
    OPTIND=0
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    vault-id)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        vault_id_func
                        ;;
                    vault-id=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        vault_id_func
                        ;;
                    secret-name)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        secret_name_func
                        ;;
                    secret-name=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        secret_name_func
                        ;;
                    decrypt)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        decrypt_func
                        ;;
                    decrypt=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        decrypt_func
                        ;;
                    encrypt)
                        encrypt=true
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

if [[ "$encrypt" = true ]]; then
    read -s -p "Enter the string to encrypt: `echo $'\n> '`";
    secret=$(echo -n "$REPLY" | ansible-vault encrypt_string --vault-id $vault_key --stdin-name $secret_name | base64 -w 0)
    unset REPLY
    echo $secret
elif [[ "$decrypt" = true ]]; then
    result=$(echo $encrypted_secret | base64 -d | /snap/bin/yq r - "$secret_name" | ansible-vault decrypt --vault-id $vault_key)
    echo $result
else
    # if no arg is passed to encrypt or decrypt, then we a ssume the function will decrypt the firehawksecret env var
    encrypted_secret="${firehawksecret}"
    result=$(echo $encrypted_secret | base64 -d | /snap/bin/yq r - "$secret_name" | ansible-vault decrypt --vault-id $vault_key)
    echo $result
fi