#!/bin/bash

# This script only defines the function to test if the last bash line had a non zero exit code.  it is used to interrupt terraform if local-exec ansible scripts fail.

RED='\033[0;31m' # Red Text
GREEN='\033[0;32m' # Green Text
BLUE='\033[0;34m' # Blue Text
NC='\033[0m' # No Color

echo_if_not_silent() {
    if [[ -z "$silent" ]] || [[ "$silent" == false ]]; then echo $1; fi
}

printf_if_not_silent() {
    if [[ -z "$silent" ]] || [[ "$silent" == false ]]; then printf $1; fi
}

export SECONDS=0

exit_test () {
    exit_code=$?
    interrupt=false
    failed=false
    if [ "$exit_code" -eq 0 ]; then
        printf_if_not_silent "\n${GREEN}Command Succeeded${NC} : "
        duration_block=$SECONDS
        printf_if_not_silent "$(($duration_block / 60))m:$(($duration_block % 60))s elapsed for block.\n"
        failed=false
    else
        failed=true
        if [ "$LIVE_TERMINAL" == true ]; then
            printf_if_not_silent "\n${RED}Failed command in live terminal. ${NC}\n" >&2
            
        else
            printf "\n${RED}Failed command ...exiting${NC}\n" >&2
            # exit will exit the shell if sourced
        fi
            # return will exit the bash script with a return code
            # return 1
    fi
    if [[ "$failed" == true ]]; then
        exit 1
    fi
    if [[ -d "/deployuser" ]] && [[ -f "/deployuser/interrupt" ]]; then
        printf "\n${RED}Interrrupt file found.  Exiting... ${NC}\n" >&2
        interrupt=true
    fi
    if [[ "$interrupt" == true ]]; then
        exit 1
    fi
}