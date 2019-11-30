#!/bin/bash

# this wizard will reuse existing encrypted settings if they exist as environment vars.
# it will regenerate an encrypted settings file based on the secrets.template file.
# if values dont exist, the user will be prompted to initialise a value.
# if values are already defined in the encrypted settings they will be skipped.

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo $SCRIPTDIR

# IFS will allow for lop to iterate over lines instead of words seperated by new line char
IFS='
'

input=$SCRIPTDIR/../secrets.template
output=$SCRIPTDIR/../../secrets/output.txt

#clear output
touch $output
rm $output

#consider erase output?
#rm $output

replace_all=false

if [[ ! $TF_VAR_envtier ]]; then
    echo "No Environment has been initialised.  Assuming first time installation.  if this is incorrect, initialise variables with"
    echo "source ./update_vars.sh"
fi

for i in `(cat $input | sed 's/^$/###/')`
do
    if [[ "$i" =~ ^.*=insertvalue$ ]]
    then
        # if insertvalue in line, then prompt user for value. 
        # compare with current env var. if initialised, use env var and dont ask user.
        command="echo \$${i%%=*}"
        current_value=`eval $command`
        if [[ "$replace_all" = true ]]; then
            printf "\nPress return to use current value= $current_value\n"
            read -p "Set ${i%%=*}: "  result
        else
            if [[ ! $current_value ]]; then
                # if no value is set, then prompt the user.
                read -p "Set ${i%%=*}: "  result
            else
                # if an env var has been set, don't prompt, use existing value.
                result=$current_value
            fi
        fi
        echo "${i%%=*}=$result"
        echo "${i%%=*}=$result" >> $output
    else
        # strip comment char # and replace_all ### blank line placeholder for user readable output.
        printf "${i#"# "}\n" | sed 's/^###$/ /'
        # output original line to file
        printf "${i#"###"}\n" >> $output
    fi
done