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

echo 'create syscontrol group'
getent group syscontrol || sudo groupadd -g ${syscontrol_gid} syscontrol
sudo usermod -aG syscontrol ${initial_user}
id -u deployuser &>/dev/null || sudo useradd -m -s /bin/bash -U deployuser -u ${deployuser_uid}
sudo usermod -aG syscontrol deployuser
sudo usermod -aG sudo deployuser
sudo touch /etc/sudoers.d/98_deployuser
sudo grep -qxF 'deployuser ALL=(ALL) NOPASSWD:ALL' /etc/sudoers.d/98_deployuser || echo 'deployuser ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d/98_deployuser
sudo cp -fr /home/${initial_user}/.ssh /home/deployuser/
sudo chown -R deployuser:deployuser /home/deployuser/.ssh
sudo chown deployuser:deployuser /home/deployuser/.ssh/authorized_keys

# define environment on boot
sudo touch /etc/profile.d/sa-environment.sh
echo "source ${SCRIPTDIR}/env.sh" | sudo tee /etc/profile.d/sa-environment.sh
ip a
export DEBIAN_FRONTEND=noninteractive

sudo rm /etc/localtime && sudo ln -s ${timezone_localpath} /etc/localtime
sudo apt-get install -y sshpass moreutils python-netaddr software-properties-common

if [[ "$selected_ansible_version" == "latest" ]]; then
    echo 'installing latest version of ansible with apt-get'
    sudo apt-add-repository --yes --update ppa:ansible/ansible-2.9
    sudo apt-get install -y ansible
else
    sudo apt-get install -y python-pip
    pip install --upgrade pip
    sudo -H pip install ansible==${ansible_version}
fi

sudo grep -qxF 'ConnectTimeout 60' /etc/sudoers.d/98_deployuser || echo 'ConnectTimeout 60' | sudo tee -a /etc/ssh/ssh_config

echo "WARNING: PASSWORD AUTHENTICATION IS LEFT ENABLED.  YOU MAY WISH TO USE SSH KEYS ONLY AND DISABLE PASSWORD LOGIN BY CONFIGURING THIS YOURSELF."
# sudo sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# set -x
export openfirehawkserver_name=${openfirehawkserver_name}
export onsite_private_vpn_ip=${onsite_private_vpn_ip}
# ${SCRIPTDIR}/init-gateway.sh --${resourcetier} eth0 # old init-gateway script - init-gateway.sh

cd $SCRIPTDIR/firehawk-auth-scripts

# enable promisc mode
ansible-playbook ansible/init.yaml -v --extra-vars "variable_host=localhost delegate_host=localhost variable_user=deployuser configure_gateway=true set_hostname=$openfirehawkserver_name openfirehawkserver_name=$openfirehawkserver_name onsite_private_vpn_ip=$onsite_private_vpn_ip" --tags "init-host,init,init-packages"
# enable ipforwarding
ansible-playbook ansible/openvpn-init.yaml -v --extra-vars "variable_host=localhost vpn_nic=eth0" --tags "init"
cd $SCRIPTDIR

# sudo reboot

# # after reboot of vm, promisc mode should be available.

# echo "Bootstrapping..."
# sudo -i -u deployuser bash -c "${SCRIPTDIR}/firehawk-auth-scripts/init-aws-auth-ssh --resourcetier ${resourcetier} --no-prompts --aws-region ${aws_region} --aws-access-key ${aws_access_key} --aws-secret-key ${aws_secret_key}"

# sudo -i -u deployuser bash -c "${SCRIPTDIR}/firehawk-auth-scripts/init-aws-auth-vpn --resourcetier ${resourcetier} --install-service"

