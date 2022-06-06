#!/bin/bash
# This script is meant to be run in the User Data of each EC2 Instance while it's booting. The script uses the
# run-consul script to configure and start Consul in client mode, and vault to sign the host key. Note that this script assumes it's running in an AMI
# built from the Packer template in firehawk-main/modules/terraform-aws-vault-client/modules/vault-client-ami

set -e
# Send the log output from this script to user-data.log, syslog, and the console. From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee -a /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Log the given message. All logs are written to stderr with a timestamp.
function log {
 local -r message="$1"
 local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
 >&2 echo -e "$timestamp $message"
}

function has_yum {
  [[ -n "$(command -v yum)" ]]
}

# These variables are passed in via Terraform template interpolation
/opt/consul/bin/run-consul --client --cluster-tag-key "${consul_cluster_tag_key}" --cluster-tag-value "${consul_cluster_tag_value}"

# clone helper scripts
git clone --branch v0.0.1 https://github.com/firehawkvfx/aws-ec2-user-data-scripts.git /var/tmp/aws-ec2-user-data-scripts
sudo chmod +x /var/tmp/aws-ec2-user-data-scripts/scripts/*
mv /var/tmp/aws-ec2-user-data-scripts/scripts/* /usr/local/bin/.
rm -fr /var/tmp/aws-ec2-user-data-scripts

# If vault cli is installed we can also perform these operations with vault cli
# The necessary environment variables have to be set

export VAULT_ADDR=https://vault.service.consul:8200
### Vault Auth IAM Method CLI
/usr/local/bin/retry \
  "vault login --no-print -method=aws header_value=vault.service.consul role=${example_role_name}" \
  "Waiting for Vault login"

log "Request Vault sign's the SSH host key and becomes a known host for other machines."

# Allow access from clients signed by the CA.
trusted_ca="/etc/ssh/trusted-user-ca-keys.pem"
# Aquire the public CA cert to approve an authority
vault read -field=public_key ssh-client-signer/config/ca | tee $trusted_ca
if test ! -f "$trusted_ca"; then
    log "Missing $trusted_ca"
    exit 1
fi

### Sign SSH host key
if test ! -f "/etc/ssh/ssh_host_rsa_key.pub"; then
    log "Missing public host key /etc/ssh/ssh_host_rsa_key.pub"
    exit 1
fi
# Sign this host's public key
vault write -format=json ssh-host-signer/sign/hostrole \
    cert_type=host \
    public_key=@/etc/ssh/ssh_host_rsa_key.pub
# Aquire the cert
vault write -field=signed_key ssh-host-signer/sign/hostrole \
    cert_type=host \
    public_key=@/etc/ssh/ssh_host_rsa_key.pub | tee /etc/ssh/ssh_host_rsa_key-cert.pub
if test ! -f "/etc/ssh/ssh_host_rsa_key-cert.pub"; then
    log "Failed to aquire /etc/ssh/ssh_host_rsa_key-cert.pub"
    exit 1
fi
chmod 0640 /etc/ssh/ssh_host_rsa_key-cert.pub

# Private key and cert are both required for ssh to another host.  Multiple entries for host key may exist.
grep -q "^HostKey /etc/ssh/ssh_host_rsa_key" /etc/ssh/sshd_config || echo 'HostKey /etc/ssh/ssh_host_rsa_key' | tee --append /etc/ssh/sshd_config

# Configure host cert to be recognised as a known host.
grep -q "^HostCertificate" /etc/ssh/sshd_config || echo 'HostCertificate' | tee --append /etc/ssh/sshd_config
sed -i 's@HostCertificate.*@HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub@g' /etc/ssh/sshd_config

# Add the CA cert to use it for known host verification # curl http://vault.service.consul:8200/v1/ssh-host-signer/public_key
key="$(vault read -field=public_key ssh-host-signer/config/ca)"

/usr/local/bin/ensure-known-hosts "/etc/ssh/ssh_known_hosts" "${aws_external_domain}" "$key"

### Finally allow users with signed client certs to login.
# If TrustedUserCAKeys not defined, then add it to sshd_config
grep -q "^TrustedUserCAKeys" /etc/ssh/sshd_config || echo 'TrustedUserCAKeys' | tee --append /etc/ssh/sshd_config
# Ensure the value for TrustedUserCAKeys is configured correctly
sed -i "s@TrustedUserCAKeys.*@TrustedUserCAKeys $trusted_ca@g" /etc/ssh/sshd_config 
systemctl daemon-reload

# restart network
systemctl restart sshd
sleep 5 # Wait 5 seconds for the ssh settings to update, preventing unknown host warnings.
if $(has_yum); then
  systemctl restart network # Allow users to connect!
else # assume ubuntu
  systemctl restart systemd-networkd
fi

vault token revoke -self
