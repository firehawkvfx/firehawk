#!/bin/bash

# this wizard will reuse existing encrypted settings if they exist as environment vars.
# it will regenerate an encrypted settings file based on the secrets.template file.
# if values dont exist, the user will be prompted to initialise a value.
# if values are already defined in the encrypted settings they will be skipped.

clear

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
printf "\n...checking scripts directory at $SCRIPTDIR\n\n"

PS3='Please enter your choice: '
options=("Initialise" "Update" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Initialise")
            printf "\nInitialise / Reinitialise: Existing secrets will be archived and you will be prompted for new values to replace old ones\n\n"
            replace_all=true
            break
            ;;
        "Update")
            printf "\nUpdate: Only new keys in the template that you have not set values for will prompt you for a value.\n\n"
            replace_all=false
            break
            ;;
        "Quit")
            echo "You selected $REPLY to $opt"
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

read -p 'Press enter to continue'

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



if [[ ! $TF_VAR_envtier ]]; then
    echo "No Environment has been initialised.  Assuming first time installation.  if this is incorrect, initialise variables first with:"
    echo "source ./update_vars.sh"
    printf "\n...propogating the configuration in to secrets file\n\n"
fi

for i in `(cat $input | sed 's/^$/###/')`
do
    if [[ "$i" =~ ^.*=insertvalue$ ]]
    then
        # if insertvalue is in line from template, then prompt user for value. 
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