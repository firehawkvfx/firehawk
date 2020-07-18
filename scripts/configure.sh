#!/usr/bin/env bash

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
            printf "\nTemplate files will overwrite any existing configuration.\nTo use an external editor, for example using vscode you can exit (ctrl-c) and set:\nexport EDITOR='code -w'\n\n"
            read -p 'Press ENTER to continue'
            cp -f $input $output_complete
            if [[ -z "$EDITOR" ]]; then EDITOR='vi'; fi
            eval "$EDITOR $output_complete"
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

if [[ -f "$output_complete" ]]; then # if a config file already exists, then source vars and replicate file for tmp settings.
    
    echo "Sourcing vagrant vars for vault key..."
    source ./update_vars.sh --dev --var-file='vagrant' --force --save-template=false # always source vagrant file since it has the vault key

    printf "\n\n...Attempting to source environment variables from existing config file $configure\n"
    printf "\nThis configuration script always sources from and writes to the dev configuration file.  Once evaluated and tested the configuration can be replicated across to your production file. \n"
    cp $output_complete $TF_VAR_firehawk_path/tmp/original.tmp # stash original encrypted version of file if encrypted.
    if [[ ! -z "$TF_VAR_resourcetier" ]] && [[ "$TF_VAR_resourcetier" != "grey" ]]; then
        resource_arg="--prod --$TF_VAR_resourcetier"
    else
        resource_arg="--dev --$TF_VAR_resourcetier"
    fi
    echo "Using resource_arg: $resource_arg"
    source $TF_VAR_firehawk_path/update_vars.sh --var-file=$configure $resource_arg --save-template=false --force --decrypt
    cp $output_complete $output_tmp # copy for editing of temp version
    mv -f $TF_VAR_firehawk_path/tmp/original.tmp $output_complete # overwrite unencrypted original.
fi

if [[ ! -f "$output_tmp" ]]; then
    printf "\n\n....Initialising a new config temp file for settings\n\n"
    cp $input $output_tmp
fi

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
        current_value=`eval $command` # TODO remove eval. 
        
        printf "%*s\n" $columns "Progess $progress / $entries "

        if [[ "$replace_all" = true ]]; then
            repeat_question=true
            while [ $repeat_question = true ]; do
                use_preset_value=false
                if [[ ! -z $current_value ]] && [[ $current_value != "insertvalue" ]]; then
                    # if a value already exists, it to be used as a default
                    use_preset_value='current'
                    printf "Enter a value or press return to use ${GREEN}current${NC} value: "
                    echo "$current_value"
                elif [[ ! -z $default_value ]]; then
                    # else if no current value exists, try to use default value if it exists
                    use_preset_value='default'
                    printf "Enter a value or press return to use ${BLUE}default${NC} value: "
                    echo "$default_value"
                else
                    printf "Enter a value and press return: \n"
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
        # echo "${i%%=*}=$result" >> $output_tmp
        # Set the value in the file matching the line that starts with the key.
        python $TF_VAR_firehawk_path/scripts/replace_value.py -f $output_tmp "${i%%=*}=" "$result"
        printf "${NC}"
        #march progress forward
        progress=$((progress + 1))
        #reset default value
        default_value=
    else
        if [[ "$i" =~ ^\#\ BEGIN\ CONFIGURATION\ \#$ ]]
        then
            display=true
        fi

        # when begin config line is found, begin display of contents
        if [[ "$display" = true ]]; then
            # strip comment char # and replace_all ### blank line placeholder for user readable output.
            printf "${i#"# "}\n" | sed 's/^###$/ /'
        fi
    fi
done

clear

