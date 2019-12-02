#!/bin/bash

# this wizard will reuse existing encrypted settings if they exist as environment vars.
# it will regenerate an encrypted settings file based on the secrets.template file.
# if values dont exist, the user will be prompted to initialise a value.
# if values are already defined in the encrypted settings they will be skipped.

clear

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

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
printf "\n...checking scripts directory at $SCRIPTDIR\n\n"

configure=

PS3='Do you wish to configure the Openfirehawk server (Vagrant VM) or Configure Secrets (To be done from within the Openfirehawk Server Vagrant VM only)? '
options=("Configure Vagrant" "Configure Secrets" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Configure Vagrant")
            printf "\nThe OpenFirehawk Server is launched with Vagrant.  Some environment variables must be configured uniquely to your environment.\n\n"
            configure='vagrant'
            input=$(to_abs_path $SCRIPTDIR/../vagrant.template)
            output_tmp=$(to_abs_path $SCRIPTDIR/../../secrets/vagrant-tmp)
            output_complete=$(to_abs_path $SCRIPTDIR/../../secrets/vagrant)
            break
            ;;
        "Configure Secrets")
            printf "\nThis should only be done within the OpenFirehawk Serrver Vagrant VM. Provisioning infrastructure requires configuration using secrets based on the secrets.template file.  These will be queried for your own unique values and should always be encrypted before you commit them in your private repository.\n\n"
            configure='secrets'
            input=$(to_abs_path $SCRIPTDIR/../secrets.template)
            output_tmp=$(to_abs_path $SCRIPTDIR/../../secrets/secrets-tmp)
            output_complete=$(to_abs_path $SCRIPTDIR/../../secrets/secrets-dev)
            break
            ;;
        "Quit")
            echo "You selected $REPLY to $opt"
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

PS3='Do you wish configure all settings or only new settings? '
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

read -p 'Press ENTER to continue'

# IFS will allow for lop to iterate over lines instead of words seperated by new line char
IFS='
'

columns=$(tput cols)
display=false



#clear output_tmp
touch $output_tmp
rm $output_tmp

if [[ ! $TF_VAR_envtier ]]; then
    echo "No Environment has been initialised.  Assuming first time installation.  if this is incorrect, initialise variables first with:"
    echo "source ./update_vars.sh"
    printf "\n...propogating the configuration in to secrets file\n\n"
fi

# Get total entries for progress tracking
progress=0
entries=0

for i in `(cat $input | sed 's/^$/###/')`
do
    if [[ "$i" =~ ^.*=insertvalue$ ]]
    then
        entries=$((entries + 1))
    fi
done

for i in `(cat $input | sed 's/^$/###/')`
do
    if [[ "$i" =~ ^.*=insertvalue$ ]]
    then
        # if insertvalue is in line from template, then prompt user for value. 
        # compare with current env var. if initialised, use env var and dont ask user.
        command="echo \$${i%%=*}"
        current_value=`eval $command`
        
        printf "%*s\n" $columns "Progess $progress / $entries "

        if [[ "$replace_all" = true ]]; then
            printf "Press return to use current value: $current_value\n"
            read -p "Set ${i%%=*}: "  result
            if [[ -z $result ]]; then 
                # User pressed ENTER to use current env var / default value
                result=$current_value
            fi
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
        echo "${i%%=*}=$result" >> $output_tmp
        progress=$((progress + 1))
    else
        if [[ "$i" =~ ^\#\ BEGIN\ CONFIGURATION\ \#$ ]]
        then
            display=true
            clear
        fi

        # when begin config line is found, begin deisplay of contents
        if [[ "$display" = true ]]; then
            # strip comment char # and replace_all ### blank line placeholder for user readable output.
            printf "${i#"# "}\n" | sed 's/^###$/ /'
        fi

        # always output original line to file
        printf "${i#"###"}\n" >> $output_tmp
    fi
done

PS3="Your configuration has been stored at temp path $output_tmp.  To use this configuration do you wish to overwrite any existing configuration at $output_complete? "
options=("Yes, overwrite my old configuration" "No / Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Yes, overwrite my old configuration")
            printf "\nMoving temp config to overwrite previous config..\n\n"
            mv -fv $output_tmp $output_complete
            break
            ;;
        "No / Quit")
            printf "\nIf you wish to later you can manually move $output_tmp to $output_complete to apply the configuration\n\nExiting...\n\n"
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done