#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Extract arguments from the input into
# shell variables.
# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "id=\(.id)"')"

primary_interface=$(aws fsx describe-file-systems | jq ".FileSystems[] | select(.FileSystemId == \"$id\") | .NetworkInterfaceIds[0]")

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.

jq -n --arg primary_interface "$primary_interface" "{\"primary_interface\":$primary_interface}"