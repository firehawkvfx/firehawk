#!/bin/bash
# This script is meant to be run in the User Data of each EC2 Instance while it's booting. The script uses the
# run-consul script to configure and start Consul in client mode, and vault to sign the host key. Note that this script assumes it's running in an AMI
# built from the Packer template in firehawk-main/modules/terraform-aws-vault-client/modules/vault-client-ami

set -e

# Send the log output from this script to user-data.log, syslog, and the console. From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "Begin user-data script"

# catch errors
trap 'catch $? $LINENO' EXIT
catch() {
  if [ "$1" != "0" ]; then
    # error handling goes here
    echo "Error: $1 occurred on $2"
  else
    echo "Script successfully completed!"
  fi
}

export AWS_REGION="${aws_region}"

# Log the given message. All logs are written to stderr with a timestamp.
function log {
  local -r message="$1"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo >&2 -e "$timestamp $message"
}

function has_yum {
  [[ -n "$(command -v yum)" ]]
}

if $(has_yum); then
  hostname=$(hostname -s) # in centos, failed dns lookup can cause commands to slowdown
  echo "127.0.0.1   $hostname.${aws_internal_domain} $hostname" | tee -a /etc/hosts
  hostnamectl set-hostname $hostname.${aws_internal_domain} # Red hat recommends that the hostname uses the FQDN.  hostname -f to resolve the domain may not work at this point on boot, so we use a var.
  systemctl restart network
fi

log "hostname: $(hostname)"
log "hostname: $(hostname -f) $(hostname -s)"

# we get terraform to update this content with the serial so
# that when its content changes, it will trigger a redeploy of the instance.
echo "Download nebula_bootstrap.sh with serial ${bootstrap_serial}..."
# TODO: place this in the AMI
aws s3 cp s3://nebula.scripts.dev.firehawkvfx.com/nebula_bootstrap.sh nebula_bootstrap.sh
chmod +x nebula_bootstrap.sh

echo "Run nebula_bootstrap.sh..."

lighthouse="${lighthouse}"
if [[ "$lighthouse" == "true" ]]; then
  echo "lighthouse is true"
  ./nebula_bootstrap.sh --resourcetier "${resourcetier}" --nebula-name "${nebula_name}" --in-aws --lighthouse
else
  echo "lighthouse is false"
  ./nebula_bootstrap.sh --resourcetier "${resourcetier}" --nebula-name "${nebula_name}" --in-aws
fi
