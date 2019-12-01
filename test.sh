#!/usr/bin/env bash 
verbose=false
optspec=":hv-:t:"
varfile=secrets
encryptmode="encrypt"

verbose () {
    local OPTIND
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            v)
                echo "Parsing option: '-${optchar}'" >&2
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

varfile () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing tier option: '--${opt}', value: '${val}'" >&2;
    fi
    export varfile="../secrets/${val}"
}

tier () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing tier option: '--${opt}', value: '${val}'" >&2;
    fi
    export encryptmode=$val
}



# We allow equivalent args such as:
# -t dev
# --tier dev
# --tier=dev
# which each results in the same function tier() running.

parse_opts () {
    local OPTIND
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
                    varfile)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        varfile
                        ;;
                    varfile=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        varfile
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

varfile="$varfile-$TF_VAR_envtier"
vault_command="ansible-vault view --vault-id ../secrets/keys/.vault-key-$TF_VAR_envtier $varfile"

if [[ "$verbose" == true ]]; then
    echo "TF_VAR_envtier=$TF_VAR_envtier"
    echo "varfile=$varfile"
    echo "vault_command=$vault_command"
fi
