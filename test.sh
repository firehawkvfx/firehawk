#!/bin/bash

# usage() {
#    cat <<EOF
# Usage: $0 -m|-d [-n]
# where:
#     -m create minimal box
#     -d create desktop box
#     -n perform headless build
# EOF
# }

# buildtype=
# headless=

# while getopts 'mdnh' flag; do
#   case "$flag" in
#     e) echo "You selected" ;;
#     d) [ -n "$buildtype" ] && usage | buildtype='desktop' ;;
#     n) headless=1 ;;
#     h) usage ;;
#     \?) usage ;;
#     *) usage ;;
#   esac
# done

# echo "$buildtype"


# while getopts u:d:p:f: option
# do
# case "${option}"
# in
# u) export USER=${OPTARG};;
# d) DATE=${OPTARG};;
# p) PRODUCT=${OPTARG};;
# f) FORMAT=${OPTARG};;
# esac
# done


# #! bin/bash
# # code for train.sh
# while getopts "f:" flag
#     do
#          case $flag in 
#              f)
#                echo "Hi" 
#                export STARTPOINT=$OPTARG
#                ;;
#          esac
#     done

#     echo Test range: $4
#     echo Train range: $3

#     #path of experiment folder and data folder:
#     export EXP_DIR="$1"
#     export DATA_DIR="$2"
#     echo Experiment: $EXP_DIR
#     echo DataSet: $DATA_DIR
#     echo file: $STARTPOINT


#OPTIND=1


#!/bin/bash

# the purpose of this script is to:
# 1) set envrionment variables as defined in the encrypted secrets/secrets-prod file
# 2) consistently rebuild the secrets.template file based on the variable names found in the secrets-prod file.
#    This generated template will never/should never have any secrets stored in it since it is commited to version control.
#    The purpose of this script is to ensure that the template for all users remains consistent.
# 3) Example values for the secrets.template file are defined in secrets.example. Ensure you have placed an example key=value for any new vars in secrets.example. 
# If any changes have resulted in a new variable name, then example values helps other understand what they should be using for their own infrastructure.
mkdir -p ./tmp/
mkdir -p ../secrets/
# The template will be updated by this script
secrets_template=./secrets.template

touch $secrets_template
#rm $secrets_template

temp_output=./tmp/secrets.temp

touch $temp_output
rm $temp_output

# IFS will allow for loop to iterate over lines instead of words seperated by ' '
IFS='
'

for i in `cat ./secrets.example`
do
    [[ "$i" =~ ^#.*$ ]] && continue
    export $i
done

####

TF_VAR_envtier=''
decrypt=false
varfile=

f () {
    local OPTIND
    while getopts "e:f:d" option; do
        case "${option}" in
        e)
            echo "env was $OPTARG"
            if [[ "$OPTARG" == "dev" ]]; then
            export TF_VAR_envtier='dev' >&2
            echo "using dev"
            fi
            if [[ "$OPTARG" == "prod" ]]; then
            export TF_VAR_envtier='prod' >&2
            fi
            ;;
        f)
            # echo "-f was triggered, Parameter: $OPTARG"
            # echo "$option varfile was $OPTARG $opt $option"
            export varfile="$OPTARG"
            ;;
        d) decrypt=true;;
        esac
    done
    # shift $((OPTIND -1))
}

f "$@"

export demo="blah"

echo "using TF_VAR_envtier=$TF_VAR_envtier"
echo "using decrypt=$decrypt"
echo "varfile=$varfile"
####