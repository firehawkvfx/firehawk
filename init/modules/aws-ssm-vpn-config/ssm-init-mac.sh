#!/bin/bash

# Determine if a VPN mac adress has been set for the environment and if not, initialise it.  The value can be manually set instead if required.

set -e

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script

echo "Ensure a mac adress exists for the vpn in env: ${TF_VAR_resourcetier}"

parm_name="/firehawk/resourcetier/${TF_VAR_resourcetier}/onsite_private_vpn_mac"
get_parms=$(aws ssm get-parameters --names ${parm_name})
invalid=$(echo ${get_parms} | jq -r .'InvalidParameters | length')

function set_mac_value {
random_mac="$(${SCRIPTDIR}/random_mac_unicast.sh)"

aws ssm put-parameter \
    --name "${parm_name}" \
    --type "String" \
    --value "${random_mac}" \
    --overwrite
}

if [[ $invalid -eq 1 ]]; then
    echo "...Initialising a value for: ${parm_name}"
    set_mac_value
else
    echo "Result: ${get_parms}"
    value=$(echo ${get_parms} | jq -r '.Parameters[0].Value')

    [[ "$value" =~ ^([a-fA-F0-9]{2}){5}[a-fA-F0-9]{2}$ ]] && valid="true" || valid="false"
    if [[ "$valid" == "false" ]]; then
        echo "ERROR: MAC Address was invalid: ${value}"
        echo "If you set a custom value for the parm you should correctly format it (no :), or delete it so this script can correctly init the value."
        exit 1
    fi

    echo "Success! MAC Address Value: ${value}"
fi