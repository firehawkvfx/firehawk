#!/bin/bash

set -e

EXECDIR="$(pwd)"
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script

# ensure promisc mode is enabled?

syscontrol_gid=9003
deployuser_uid=9004
timezone_localpath="/usr/share/zoneinfo/Australia/Adelaide"
selected_ansible_version="latest"
ansible_version="" # This method isn't yet available.
ip_addresses_file="${SCRIPTDIR}/../ip_addresses.json"

sudo apt-get install jq -y

if test -f "$ip_addresses_file"; then
    echo "Read: $ip_addresses_file"
    output=$(cat "$ip_addresses_file")
    echo "Aquired: $output"
    resourcetier=$(echo ${output} | jq -r ".resourcetier")
    onsite_private_vpn_ip=$(echo ${output} | jq -r ".${resourcetier}.onsite_private_vpn_ip")
else
    onsite_private_vpn_ip='none'
fi

if [[ -z "$resourcetier" ]]; then
    echo "ERROR: env var resourcetier not defined"
    exit 1
fi
if [[ -z "$aws_region" ]]; then
    echo "ERROR: env var aws_region not defined"
    exit 1
fi
if [[ -z "$aws_access_key" ]]; then
    echo "ERROR: env var aws_access_key not defined"
    exit 1
fi
if [[ -z "$aws_secret_key" ]]; then
    echo "ERROR: env var aws_secret_key not defined"
    exit 1
fi

openfirehawkserver_name="firehawkgateway${resourcetier}"

# sudo reboot

# # after reboot of vm, promisc mode should be available.

echo "Bootstrapping..."
sudo -i -u deployuser bash -c "${SCRIPTDIR}/firehawk-auth-scripts/init-aws-auth-ssh --resourcetier ${resourcetier} --no-prompts --aws-region ${aws_region} --aws-access-key ${aws_access_key} --aws-secret-key ${aws_secret_key}"

sudo -i -u deployuser bash -c "${SCRIPTDIR}/firehawk-auth-scripts/init-aws-auth-vpn --resourcetier ${resourcetier} --install-service"

