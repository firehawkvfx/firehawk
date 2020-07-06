#!/usr/bin/env bash

# this wizard will reuse existing encrypted settings if they exist as environment vars.
# it will regenerate an encrypted settings file based on the secrets.template file.
# if values dont exist, the user will be prompted to initialise a value.
# if values are already defined in the encrypted settings they will be skipped.



export RED='\033[0;31m' # Red Text
export GREEN='\033[0;32m' # Green Text
export BLUE='\033[0;34m' # Blue Text
export NC='\033[0m' # No Color


if [ ! -z $HISTFILE ]; then
    echo "HISTFILE = $HISTFILE"
    print 'HISTFILE is still set, this var should not normally be passed through to the shell please create a ticket alerting us to this issue.  If you wish to continue you can unset HISTFILE and continue.  Exiting.'
    exit
fi

to_abs_path() {
  python -c "import os; print os.path.abspath('$1')"
}

# This is the directory of the current script
export SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TEMPDIR="$SCRIPTDIR/../tmp"

mkdir -p "$TEMPDIR"

printf "\n...checking scripts directory at $SCRIPTDIR\n\n"

export configure=

function define_config_settings() {
    clear
    PS3='Configure each of these options without secrets.  If you are running in the VM, configure secrets (To be done from within the Openfirehawk Server Vagrant VM when available): '
    options=("Configure Vagrant" "Configure General Config" "Configure Resources - Grey" "Configure Resources - Green" "Configure Resources - Blue" "Configure Secrets (Only from within Vagrant VM)" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Configure Vagrant")
                printf "\nThe OpenFirehawk Server is launched with Vagrant.  Some environment variables must be configured uniquely to your environment.\n\n"
                export configure='vagrant'
                export input=$(to_abs_path $SCRIPTDIR/../config/templates/vagrant.template)
                export output_tmp=$(to_abs_path $SCRIPTDIR/../tmp/vagrant-tmp)
                export output_complete=$(to_abs_path $SCRIPTDIR/../../secrets/vagrant)
                break
                ;;
            "Configure General Config")
                printf "\nSome general Config like IP addresses of your hosts is needed.  Some environment variables here must be configured uniquely to your environment.\n\n"
                export configure='config'
                export input=$(to_abs_path $SCRIPTDIR/../config/templates/config.template)
                export output_tmp=$(to_abs_path $SCRIPTDIR/../tmp/config-tmp)
                export output_complete=$(to_abs_path $SCRIPTDIR/../../secrets/config)
                break
                ;;
            "Configure Resources - Grey")
                export TF_VAR_resourcetier='grey'
                printf "\nThe $TF_VAR_resourcetier resource file uses resources generally unique to your dev environment.\n\n"
                export configure='resources'
                export input=$(to_abs_path $SCRIPTDIR/../config/templates/resources-$TF_VAR_resourcetier.template)
                export output_tmp=$(to_abs_path $SCRIPTDIR/../tmp/resources-$TF_VAR_resourcetier-tmp)
                export output_complete=$(to_abs_path $SCRIPTDIR/../../secrets/resources-$TF_VAR_resourcetier)
                break
                ;;
            "Configure Resources - Green")
                export TF_VAR_resourcetier='green'
                printf "\nThe $TF_VAR_resourcetier resource file uses resources generally unique to your production $TF_VAR_resourcetier environment.\n\n"
                export configure='resources'
                export input=$(to_abs_path $SCRIPTDIR/../config/templates/resources-$TF_VAR_resourcetier.template)
                export output_tmp=$(to_abs_path $SCRIPTDIR/../tmp/resources-$TF_VAR_resourcetier-tmp)
                export output_complete=$(to_abs_path $SCRIPTDIR/../../secrets/resources-$TF_VAR_resourcetier)
                break
                ;;
            "Configure Resources - Blue")
                export TF_VAR_resourcetier='blue'
                printf "\nThe $TF_VAR_resourcetier resource file uses resources generally unique to your production $TF_VAR_resourcetier environment.\n\n"
                export configure='resources'
                export input=$(to_abs_path $SCRIPTDIR/../config/templates/resources-$TF_VAR_resourcetier.template)
                export output_tmp=$(to_abs_path $SCRIPTDIR/../tmp/resources-$TF_VAR_resourcetier-tmp)
                export output_complete=$(to_abs_path $SCRIPTDIR/../../secrets/resources-$TF_VAR_resourcetier)
                break
                ;;
            "Configure Secrets (Only from within Vagrant VM)")
                printf "\nThis should only be done within the Ansible Control Vagrant VM. Provisioning infrastructure requires configuration using secrets based on the secrets.template file.  These will be queried for your own unique values and should always be encrypted before you commit them in your private repository.\n\n"
                export configure='secrets'
                export input=$(to_abs_path $SCRIPTDIR/../config/templates/secrets-general.template)
                export output_tmp=$(to_abs_path $SCRIPTDIR/../tmp/secrets-general-tmp)
                export output_complete=$(to_abs_path $SCRIPTDIR/../../secrets/secrets-general)
                break
                ;;
            "Quit")
                echo "You selected $REPLY to $opt"
                exit
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
    $SCRIPTDIR/configure.sh
    write_output

    echo "Source vars for dev and ensuring they are encrypted..."
    source ./update_vars.sh --dev --var-file=$configure --force --save-template=false
}

function write_output() {
    if [[ -f "$output_complete" ]]; then
        # if an existing config exists, then prompt to overwrite
        printf "\nYour new initialised configuration has been stored at temp path-\n$output_tmp\nTo use this configuration do you wish to overwrite any existing configuration at-\n$output_complete?\n\n"
        PS3="Save and overwrite configuration settings?"
        options=("Yes, save my configuration and continue or exit from main menu" "No / Quit")
        select opt in "${options[@]}"
        do
            case $opt in
                "Yes, save my configuration and continue or exit from main menu")
                    printf "\nMoving temp config to overwrite previous config... \n\n"
                    mv -fv $output_tmp $output_complete || echo "Failed to move temp file.  Check permissions."
                    define_config_settings
                    break # this shouldn't occur unless above command fails.
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
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
        printf "\n** CTRL-C ** EXITING...\n"
        if [[ "$configure" == 'secrets' ]]; then
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
        write_output
        # exit
}

define_config_settings