#!/bin/bash

# Determine if a VPN mac adress has been set for the environment and if not, initialise it.  The value can be manually set instead if required.

set -e

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script

echo "Ensure a mac adress exists for the vpn in env: ${TF_VAR_resourcetier}"

parm_name="/firehawk/resourcetier/${TF_VAR_resourcetier}/onsite_private_vpn_mac"
get_parms=$(aws ssm get-parameters --names ${parm_name})
invalid=$(echo ${get_parms} | jq -r .'InvalidParameters | length')

if [[ $invalid -eq 1 ]]; then
    echo "...Initialising a value for: ${parm_name}"

    random_mac="$(${SCRIPTDIR}/random_mac_unicast.sh)"

    aws ssm put-parameter \
        --name "${parm_name}" \
        --type "String" \
        --value "${random_mac}" \
        --overwrite
else
    echo "Result: ${get_parms}"
fi