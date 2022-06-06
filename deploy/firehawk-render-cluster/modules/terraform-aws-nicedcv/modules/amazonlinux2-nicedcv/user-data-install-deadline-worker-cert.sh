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
installer_file="install-deadline-worker.sh"
installer_path="/home/$deadlineuser_name/Downloads/$installer_file"

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
# A retry function that attempts to run a command a number of times and returns the output
function retry {
  local -r cmd="$1"
  local -r description="$2"
  attempts=5

  for i in $(seq 1 $attempts); do
    log "$description"

    # The boolean operations with the exit status are there to temporarily circumvent the "set -e" at the
    # beginning of this script which exits the script immediatelly for error status while not losing the exit status code
    output=$(eval "$cmd") && exit_status=0 || exit_status=$?
    errors=$(echo "$output") | grep '^{' | jq -r .errors

    log "$output"

    if [[ $exit_status -eq 0 && -z "$errors" ]]; then
      echo "$output"
      return
    fi
    log "$description failed. Will sleep for 10 seconds and try again."
    sleep 10
  done;

  log "$description failed after $attempts attempts."
  exit $exit_status
}
function retrieve_file {
  local -r source_path="$1"
  if [[ -z "$2" ]]; then
    local -r target_path="$source_path"
  else
    local -r target_path="$2"
  fi
  echo "Aquiring vault data... $source_path to $target_path"
  response=$(retry \
  "vault kv get -field=value $source_path/file" \
  "Trying to read secret from vault")

  echo "worker-cert retrieve_file mkdir: $(dirname $target_path)"
  mkdir -p "$(dirname $target_path)" # ensure the directory exists
  echo "Check file path is writable: $target_path"
  if test -f "$target_path"; then
    echo "File exists: ensuring it is writeable"
    chmod u+w "$target_path"
    touch "$target_path"
  else
    echo "Ensuring path is writeable"
    touch "$target_path"
    chmod u+w "$target_path"
  fi
  if [[ -f "$target_path" ]]; then
    chmod u+w "$target_path"
  else
    echo "Error: path does not exist, var may not be a file: $target_path "
  fi
  echo "Write file content: single operation"
  echo "$response" | base64 --decode > $target_path
  if [[ ! -f "$target_path" ]] || [[ -z "$(cat $target_path)" ]]; then
    echo "Error: no file or empty result at $target_path"
    exit 1
  fi
  echo "retrival done."
}

### Centos 7 fix: Failed dns lookup can cause sudo commands to slowdown
if $(has_yum); then
    hostname=$(hostname -s) 
    echo "127.0.0.1   $hostname.${aws_internal_domain} $hostname" | tee -a /etc/hosts
    hostnamectl set-hostname $hostname.${aws_internal_domain} # Red hat recommends that the hostname uses the FQDN.  hostname -f to resolve the domain may not work at this point on boot, so we use a var.
    # systemctl restart network # we restart the network later, needed to update the host name
fi

### Create deadlineuser
function add_sudo_user() {
  local -r user_name="$1"
  if $(has_apt_get); then
    sudo_group=sudo
  elif $(has_yum); then
    sudo_group=wheel
  else
    echo "ERROR: Could not find apt-get or yum."
    exit 1
  fi
  echo "Ensuring user exists: $user_name with groups: $sudo_group $user_name"
  if id "$user_name" &>/dev/null; then
    echo 'User found.  Ensuring user is in sudoers.'
    sudo usermod -a -G $sudo_group $user_name
  else
      echo 'user not found'
      sudo useradd -m -d /home/$user_name/ -s /bin/bash -G $sudo_group $user_name
  fi
  echo "Adding user as passwordless sudoer."
  touch "/etc/sudoers.d/98_$user_name"; grep -qxF "$user_name ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/98_$user_name || echo "$user_name ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers.d/98_$user_name"
  sudo -i -u $user_name mkdir -p /home/$user_name/.ssh
  # Generate a public and private key - some tools can fail without one.
  rm -frv /home/$user_name/.ssh/id_rsa*
  sudo -i -u $user_name bash -c "ssh-keygen -q -b 2048 -t rsa -f /home/$user_name/.ssh/id_rsa -C \"\" -N \"\""  
}
add_sudo_user $deadlineuser_name

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

### Vault Auth IAM Method CLI
retry \
  "vault login --no-print -method=aws header_value=vault.service.consul role=${example_role_name}" \
  "Waiting for Vault login"

# Retrieve previously generated secrets from Vault.  Would be better if we can use vault as an intermediary to generate certs.
retrieve_file "$client_cert_vault_path" "$client_cert_file_path"
echo "Finalise permissions"
chown $deadlineuser_name:$deadlineuser_name $client_cert_file_path
chmod u=rw,g=rw,o-rwx $client_cert_file_path

echo "Revoking vault token..."
vault token revoke -self

# ### Install Deadline
# # Client
# mkdir -p "$(dirname $installer_path)"
# aws s3api get-object --bucket "$installers_bucket" --key "$installer_file" "$installer_path"
# chown $deadlineuser_name:$deadlineuser_name $installer_path
# chmod u+x $installer_path
# sudo -i -u $deadlineuser_name installers_bucket="$installers_bucket" deadlineuser_name="$deadlineuser_name" deadline_version="$deadline_version" $installer_path

sudo service deadline10launcher restart

