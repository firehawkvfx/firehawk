#!/bin/bash

set -e
exec > >(tee -a /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# User Defaults: these will be replaced with terraform template vars, defaults are provided to allow copy / paste directly into a shell for debugging.  These values will not be used when deployed.
deadlineuser_name="deadlineuser"
resourcetier="dev"
installers_bucket="software.$resourcetier.firehawkvfx.com"
example_role_name="rendernode-vault-role"

# User Vars: Set by terraform template
deadlineuser_name="${deadlineuser_name}"
resourcetier="${resourcetier}"
installers_bucket="${installers_bucket}"
deadline_version="${deadline_version}"

# Script vars (implicit)
export VAULT_ADDR=https://vault.service.consul:8200
client_cert_file_path="${client_cert_file_path}"
client_cert_vault_path="${client_cert_vault_path}"

# Functions
function log {
 local -r message="$1"
 local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
 >&2 echo -e "$timestamp $message"
}
function has_yum {
  [[ -n "$(command -v yum)" ]]
}
function has_apt_get {
  [[ -n "$(command -v apt-get)" ]]
}

### Centos 7 fix: Failed dns lookup can cause sudo commands to slowdown
if $(has_yum); then
    hostname=$(hostname -s) 
    echo "127.0.0.1   $hostname.${aws_internal_domain} $hostname" | tee -a /etc/hosts
    hostnamectl set-hostname $hostname.${aws_internal_domain} # Red hat recommends that the hostname uses the FQDN.  hostname -f to resolve the domain may not work at this point on boot, so we use a var.
    # systemctl restart network # we restart the network later, needed to update the host name
fi

### Create deadlineuser
/usr/local/bin/add-sudo-user $deadlineuser_name

printf "\n...Waiting for consul deadlinedb service before attempting to retrieve Deadline remote cert.\n\n"

tries=0
max_tries=90
until [ $tries -gt $max_tries ] || consul catalog services | grep -m 1 "deadlinedb"; do
  tries=$(( $tries + 1 ))
  sleep 10
done
if [ $tries -gt $max_tries ]; then
  echo "Command timed out before service arrived"
  exit 1
fi

echo "Ensure Required Directories exist with valid permissions"
mkdir -p $(dirname $client_cert_file_path)                                                                
chown $deadlineuser_name:$deadlineuser_name /opt/Thinkbox/
chown $deadlineuser_name:$deadlineuser_name /opt/Thinkbox/certs/
chown -R $deadlineuser_name:$deadlineuser_name /opt/Thinkbox/Deadline10/bin/pythonsync/apiclient # This might be a bug that we have to do this

### Vault Auth IAM Method CLI
/usr/local/bin/retry \
  "vault login --no-print -method=aws header_value=vault.service.consul role=${example_role_name}" \
  "Waiting for Vault login"

# Retrieve previously generated secrets from Vault.  Would be better if we can use vault as an intermediary to generate certs.
/usr/local/bin/retrieve-vault-file "$client_cert_vault_path" "$client_cert_file_path"
echo "Finalise permissions"
chown $deadlineuser_name:$deadlineuser_name $client_cert_file_path
chmod u=rw,g=rw,o-rwx $client_cert_file_path

echo "Revoking vault token..."
vault token revoke -self

houdini_license_server_enabled="${houdini_license_server_enabled}"
houdini_license_server_address="${houdini_license_server_address}"
if [[ "$houdini_license_server_enabled" == "true" ]] && [[ ! -z "$houdini_license_server_address" ]] && [[ "$houdini_license_server_address" != "0.0.0.0" ]]; then
  echo "...Wait until license server is reachable"
  if [[ $houdini_license_server_address == *"www.sidefx.com"* ]]; then 
    until nc -vzw 2 www.sidefx.com 443; do sleep 2; done
  else
    until nc -vzw 2 $houdini_license_server_address 22; do sleep 2; done
  fi
  echo "Set Houdini license server to: $houdini_license_server_address"
  echo "source ./houdini_setup and set hserver to: $houdini_license_server_address"
  set -x
  sudo -i -u $deadlineuser_name bash -c "echo \"serverhost=$houdini_license_server_address\" | sudo tee /home/$deadlineuser_name/.sesi_licenses.pref"

  if [[ $houdini_license_server_address == *"www.sidefx.com"* ]]; then 
    # If using houdini cloud license server, configure oauth2 keys.
    echo "...Connecting Side FX Cloud License Server"

    sesi_client_id="${sesi_client_id}"

    # retrieve secretsmanager secrets
    sesi_client_secret_key_path="/firehawk/resourcetier/${resourcetier}/sesi_client_secret_key"
    get_secret_strings=$(aws secretsmanager get-secret-value --secret-id "$sesi_client_secret_key_path")
    if [[ $? -eq 0 ]]; then
      export sesi_client_secret_key=$(echo $get_secret_strings | jq ".SecretString" --raw-output)
      if [[ -z "$sesi_client_secret_key" ]]; then
        echo "Secretsmanager secret missing: sesi_client_secret_key"
      fi
    else
      echo "Error retrieving: $sesi_client_secret_key_path"
      return
    fi

    sudo -i -u $deadlineuser_name bash -c "echo \"APIKey=www.sidefx.com ${sesi_client_id} $sesi_client_secret_key\" | tee /home/$deadlineuser_name/houdini19.0/hserver.opt"
  else
    echo "...Connecting Private License Server"
  fi

  sudo -i -u $deadlineuser_name bash -c "cd /opt/hfs${houdini_major_version} && source ./houdini_setup && hserver"
  echo "...End license server config"

  set +x
else
  printf "\n...Skippping setting of Houdini license server: houdini_license_server_enabled: ${houdini_license_server_enabled} houdini_license_server_address:${houdini_license_server_address}\n\n"
  echo "Starting hserver process to enable UBL"
  sudo -i -u $deadlineuser_name bash -c "cd /opt/hfs${houdini_major_version} && source ./houdini_setup && hserver ; sleep 10 ; hserver ; hserver -S 127.0.0.1"
fi

echo "Determine if mounts should be altered..."
prod_mount_target=${prod_mount_target}

onsite_nfs_export=${onsite_nfs_export}
onsite_nfs_mount_target=${onsite_nfs_mount_target}
onsite_storage="false"
if [[ "${onsite_storage}" == "true" ]] && [[ ! -z "$onsite_nfs_export" ]] && [[ ! -z "$onsite_nfs_mount_target" ]]; then
  onsite_storage="true"
fi

cloud_s3_gateway_dns_name=${cloud_s3_gateway_dns_name}
cloud_s3_gateway_mount_target=${cloud_s3_gateway_mount_target}
cloud_s3_gateway_mount_name=${cloud_s3_gateway_mount_name}
cloud_s3_gateway_export="${cloud_s3_gateway_dns_name}:/${cloud_s3_gateway_mount_name}"
cloud_s3_gateway="false"
if [[ "${cloud_s3_gateway}" == "true" ]] && [[ ! -z "$cloud_s3_gateway_dns_name" ]] && [[ ! -z "$cloud_s3_gateway_mount_target" ]] && [[ ! -z "$cloud_s3_gateway_mount_name" ]]; then
  cloud_s3_gateway="true"
fi

cloud_fsx_dns_name=${cloud_fsx_dns_name}
cloud_fsx_mount_target=${cloud_fsx_mount_target}
fsx_mount_name=${fsx_mount_name}
cloud_fsx_export="${cloud_fsx_dns_name}@tcp:/${fsx_mount_name}"
cloud_fsx_storage="false"
if [[ "${cloud_fsx_storage}" == "true" ]] && [[ ! -z "$cloud_fsx_dns_name" ]] && [[ ! -z "$cloud_fsx_mount_target" ]] && [[ ! -z "$fsx_mount_name" ]]; then
  cloud_fsx_storage="true"
fi

cloud_mount="false"
if [[ "$cloud_s3_gateway" == "true" ]] || [[ "$cloud_fsx_storage" == "true" ]]; then
  cloud_mount="true"
fi

houdini_major_version=${houdini_major_version}

function bind_to {
  local -r source="$1"
  local -r target="$2"
  mkdir -p "$target"
  chmod u=rwX,g=rwX,o=rwX "$target"
  echo "...Bind $source to $target"
  echo "$source $target none defaults,bind 0 0" | tee --append /etc/fstab 
}

function fstab_mount {
  ping_host="$1"
  ping_port="$2"
  mount_target="$3"
  fstab_entry="$4"
  echo ""
  echo "...Wait until server is reachable: $ping_host:$ping_port"
  until nc -vzw 2 $ping_host $ping_port; do sleep 2; done
  echo "...Ensuring mount paths exist for mount_target: $mount_target"
  mkdir -p "$mount_target"
  chmod u=rwX,g=rwX,o=rwX "$mount_target"
  echo "...Configure /etc/fstab"
  echo "$fstab_entry" | tee --append /etc/fstab
}

bind="false"

if [[ $onsite_storage == "true" ]]; then
  onsite_nfs_host=$(echo "$onsite_nfs_export" | awk -F ':' '{print $1}')
  fstab_mount "$onsite_nfs_host" "2049" "$onsite_nfs_mount_target" "$onsite_nfs_export $onsite_nfs_mount_target nfs defaults,_netdev,rsize=8192,wsize=8192,timeo=14,intr 0 0"
  if [[ $cloud_mount == "false" ]] && [[ "$onsite_storage" == "true" ]]; then # if no fsx ip adress exists, then we will mount the onsite storage over the vpn.
    echo "Since no cloud mounts are configured, onsite storage will be mounted to cloud nodes."
    bind="true"
    bind_source="$onsite_nfs_mount_target"
  fi
fi

if [[ $cloud_s3_gateway == "true" ]]; then
  fstab_mount "$cloud_s3_gateway_dns_name" "2049" "$cloud_s3_gateway_mount_target" "$cloud_s3_gateway_export $cloud_s3_gateway_mount_target nfs defaults,nolock,hard,_netdev 0 0"
  if [[ $cloud_fsx_storage == "false" ]]; then # If for some reason fsx is being used as well, fsx will get the production mount instead
    bind="true"
    bind_source="$cloud_s3_gateway_mount_target"
  fi
fi

if [[ $cloud_fsx_storage == "true" ]]; then
  fstab_mount "$cloud_fsx_dns_name" "988" "$cloud_fsx_mount_target" "$cloud_fsx_export $cloud_fsx_mount_target lustre defaults,noatime,flock,_netdev 0 0"
  bind="true"
  bind_source="$cloud_fsx_mount_target"
fi

if [[ "$bind" == "true" ]]; then # bind to prod
  bind_to "$bind_source" "$prod_mount_target"
fi

echo ""
echo "...Mounting."
mount -a
echo "...Finished mounting."
df -h

echo "...Enable: deadline10launcher"
systemctl enable deadline10launcher
echo "...Start: deadline10launcher"
systemctl start deadline10launcher

# If add to deadline group tag is found, then add the instance to the group.
this_instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)
add_to_deadline_group="$(aws ec2 describe-tags --filters Name=resource-id,Values=$this_instance_id --out=json|jq '.Tags[]| select(.Key == "add_to_deadline_group")|.Value' --raw-output)"
if [[ ! -z "$add_to_deadline_group" ]]; then
  echo "Found add_to_deadline_group tag: $add_to_deadline_group.  Will add to group."
  hostname_short=$(echo $HOSTNAME | awk -F '.' '{print $1}')
  sudo -i -u $deadlineuser_name bash -c "cd /opt/Thinkbox/Deadline10/bin && ./deadlinecommand -SetGroupsForSlave \"$hostname_short\" \"$add_to_deadline_group\""
fi

set +x
# Leave the following newline at the end of this template
