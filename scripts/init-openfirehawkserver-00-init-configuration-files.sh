#!/bin/bash

# this wizard will reuse existing encrypted settings if they exist as environment vars.
# it will regenerate an encrypted settings file based on the secrets.template file.
# if values dont exist, the user will be prompted to initialise a value.
# if values are already defined in the encrypted settings they will be skipped.

clear

RED='\033[0;31m' # Red Text
GREEN='\033[0;32m' # Green Text
BLUE='\033[0;34m' # Blue Text
NC='\033[0m' # No Color


if [ ! -z $HISTFILE ]; then
    echo "HISTFILE = $HISTFILE"
    print 'HISTFILE is still set, this var should not normally be passed through to the shell please create a ticket alerting us to this issue.  If you wish to continue you can unset HISTFILE and continue.  Exiting.'
    exit
fi

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

# This is the directory of the current script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
printf "\n...checking scripts directory at $SCRIPTDIR\n\n"

configure=

PS3='Do you wish to configure the Openfirehawk server (deployuser VM) or Configure Secrets (To be done from within the Openfirehawk Server Vagrant VM only)? '
options=("Configure Vagrant" "Configure Secrets" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Configure Vagrant")
            printf "\nThe OpenFirehawk Server is launched with Vagrant.  Some environment variables must be configured uniquely to your environment.\n\n"
            configure='vagrant'
            input=$(to_abs_path $SCRIPTDIR/../deployuser.template)
            output_tmp=$(to_abs_path $SCRIPTDIR/../../secrets/deployuser-tmp)
            output_complete=$(to_abs_path $SCRIPTDIR/../../secrets/deployuser)
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

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
        printf "\n** CTRL-C ** EXITING...\n"
        if [[ "$configure" != 'vagrant' ]]; then
            printf "\nWARNING: PARTIALLY COMPLETED INSTALLATIONS MAY LEAVE UNENCRYPTED SECRETS.\n"
            PS3='Do you want to Encrypt, Remove, or Leave the resulting temp file on disk? '
            options=("Encrypt And Quit" "Remove And Quit" "Leave And Quit (NOT RECOMMENDED)")
            select opt in "${options[@]}"
            do
                case $opt in
                    "Encrypt And Quit")
                        printf "\nEncrypting temp configuration file.\n\n"
                        ansible-vault encrypt $output_tmp
                        exit
                        ;;
                    "Remove And Quit")
                        printf "\nRemoving temp configuration file\n\n"
                        rm -v $output_tmp || echo "ERROR / WARNING: couldn't remove the temp file, probably due to permissions.  Do this immediately."
                        exit
                        ;;
                    "Leave And Quit (NOT RECOMMENDED)")
                        echo "You selected $REPLY to $opt"
                        exit
                        ;;
                    *) echo "invalid option $REPLY";;
                esac
            done
        fi
        exit
}

PS3='Do you wish configure all settings or only update and set new settings that need to be initialised? '
options=("Configure All Settings" "Update" "Initilise And Use External Editor To Configure" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Configure All Settings")
            printf "\nInitialise / Reinitialise: Existing secrets will be archived and you will be prompted for new values to replace old ones\n\n"
            replace_all=true
            break
            ;;
        "Update")
            printf "\nUpdate: Only new keys in the template that you have not set values for will prompt you for a value.\n\n"
            replace_all=false
            break
            ;;
        "Initilise And Use External Editor To Configure")
            printf "\nTemplate files will overwrite any existing configuration.\nTo use an external editor set-\nexport EDITOR='/usr/local/bin/code -w'\n\n"
            read -p 'Press ENTER to continue'
            cp -f $input $output_complete
            exit
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

if [[ -f "$output_complete" ]]; then
    printf "\n\n...Attempting to source environment variables from existing config file $configure\n"
    printf "\nThis configuration script always sources from and writes to the dev configuration file.  Once evaluated and tested the configuration can be replicated across to your production file. \n"
    source $SCRIPTDIR/../update_vars.sh --var-file $configure --tier dev --save-template false
fi

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

# iterate over lines in template and filter results
for i in `(cat $input | sed 's/^$/###/')`
do
    if [[ "$i" =~ ^.*default:.* ]]; then
        default_value=$(echo ${i#*=} | awk '{$1=$1};1')
    fi

    if [[ "$i" =~ ^.*=insertvalue$ ]]; then
        # if insertvalue is in line from template, then prompt user for value. 
        # compare with current env var. if initialised, use env var and dont ask user.
        command="echo \$${i%%=*}"
        current_value=`eval $command`
        
        printf "%*s\n" $columns "Progess $progress / $entries "

        if [[ "$replace_all" = true ]]; then
            repeat_question=true
            while [ $repeat_question = true ]; do
                use_preset_value=false
                if [[ ! -z $current_value ]]; then
                    # if a value already exists, it to be used as a default
                    use_preset_value='current'
                    printf "Press return to use ${GREEN}current${NC} value: "
                    echo "$current_value"
                elif [[ ! -z $default_value ]]; then
                    # else if no current value exists, try to use default value if it exists
                    use_preset_value='default'
                    printf "Press return to use ${BLUE}default${NC} value: "
                    echo "$default_value"
                else
                    printf "Press return to enter a value: \n"
                fi
                read -p "Set ${i%%=*}: "  result
                if [[ -z $result ]]; then
                    # if blank value was entered
                    if [[ "$use_preset_value" = 'current' ]]; then
                        # User pressed ENTER to use current env var
                        printf "\n${GREEN}Using current value \n"
                        result=$current_value
                        repeat_question=false
                    elif [[ "$use_preset_value" = 'default' ]]; then
                        # User pressed ENTER to use default env var
                        printf "\n${BLUE}Using default value \n"
                        result=$default_value
                        repeat_question=false
                    else
                        # if no env var, then repeate the question
                        repeat_question=true
                        printf "\nNo Value Entered: \n"
                    fi
                else
                    repeat_question=false
                fi
            done
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
        printf "${NC}"
        #march progress forward
        progress=$((progress + 1))
        #reset default value
        default_value=
    else
        if [[ "$i" =~ ^\#\ BEGIN\ CONFIGURATION\ \#$ ]]
        then
            display=true
            #clear
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

clear

if [[ -f "$output_complete" ]]; then
    # if an existing config exists, then prompt to overwrite
    printf "\nYour configuration has been stored at temp path-\n$output_tmp\nTo use this configuration do you wish to overwrite any existing configuration at-\n$output_complete?\n\n"
    PS3="Save and overwrite configuration settings?"
    options=("Yes, overwrite my old configuration" "No / Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes, overwrite my old configuration")
                printf "\nMoving temp config to overwrite previous config... \n\n"
                mv -fv $output_tmp $output_complete || echo "Failed to move temp file.  Check permissions."
                break
                ;;
            "No / Quit")
                printf "\nIf you wish to later you can manually move \n$output_tmp \nto \n$output_complete\nto apply the configuration\n\nExiting... \n\n"
                exit
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
else
    printf '\n...Saving configuration\n'
    mv -fv $output_tmp $output_complete || echo "Failed to move temp file.  Check permissions."
fi