#!/bin/bash

# This script only defines the function to test if the last bash line had a non zero exit code.  it is used to interrupt terraform if local-exec ansible scripts fail.

exit_test () {
    RED='\033[0;31m' # Red Text
    GREEN='\033[0;32m' # Green Text
    BLUE='\033[0;34m' # Blue Text
    NC='\033[0m' # No Color
    if [ $? -eq 0 ]; then
        printf "\n${GREEN}Playbook Succeeded${NC}\n"
    else
        printf "\n${RED}Failed Playbook${NC}\n" >&2
        exit 1
    fi
}