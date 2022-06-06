#!/bin/bash

echo "Configure known hosts to avoid Trust On First Use warnings."

set -e

EXECDIR="$(pwd)"
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script
cd "$SCRIPTDIR"

readonly DEFAULT_resourcetier="$TF_VAR_resourcetier"
readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TRUSTED_CA="/etc/ssh/trusted-user-ca-keys.pem"
readonly DEFAULT_SSH_KNOWN_HOSTS="$HOME/.ssh/ssh_known_hosts_fragment"
readonly DEFAULT_EXTERNAL_DOMAIN="$TF_VAR_aws_external_domain"

function print_usage {
  echo
  echo "Usage: known-hosts [OPTIONS]"
  echo
  echo "If authenticated to Vault, signs a public key with Vault for use as an SSH client, generating a public certificate in the same directory as the public key with the suffix '-cert.pub'."
  echo
  echo "Example: Configure the CA for this host to recognize known hosts with Vault."
  echo
  echo "  ./known-hosts"
  echo
  echo "Example: Using AWS SSM parameters, Configure a provided CA file and trusted known hosts CA where vault access is not available, specifying a valid external dns name"
  echo
  echo "  ./known-hosts --ssm --external-domain ap-southeast-2.compute.amazonaws.com"
  echo
  echo "Example: Configure a provided CA file and trusted known hosts CA where vault access is not available, specifying a valid external dns name"
  echo
  echo "  ./known-hosts --external-domain ap-southeast-2.compute.amazonaws.com --trusted-ca ~/Downloads/trusted-user-ca-keys.pem --ssh-known-hosts ~/Downloads/ssh_known_hosts_fragment"
}

function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local -r message="$1"
  log "INFO" "$message"
}

function log_warn {
  local -r message="$1"
  log "WARN" "$message"
}

function log_error {
  local -r message="$1"
  log "ERROR" "$message"
}

function error_if_empty {
  if [[ -z "$2" ]]; then
    log_error "$1"
  fi
  return
}

function assert_not_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

function set_ssm_parm_value {
  local -r parm_name="$1"
  local -r value="$2"
  aws ssm put-parameter \
    --name "${parm_name}" \
    --type "String" \
    --value "${value}" \
    --overwrite
}

function request_trusted_ca {
  local -r trusted_ca="$1"
  # Aquire the public CA cert to approve an authority for known hosts.
  trusted_ca_value=$(vault read -field=public_key ssh-client-signer/config/ca)
  echo "$trusted_ca_value" | sudo tee $trusted_ca

  if [[ -z "$TF_VAR_resourcetier" ]]; then
    log_error "TF_VAR_resourcetier is not defined.  Ensure you have run source ./update_vars.sh"
  fi
  # store the ca as a parameter
  parm_name="/firehawk/resourcetier/${TF_VAR_resourcetier}/trusted_ca"
  set_ssm_parm_value "$parm_name" "$trusted_ca_value"
}

function configure_trusted_ca {
  local -r trusted_ca="$1"

  if [[ -z "$trusted_ca" ]]; then
    log_error "No path to trusted CA provided.  Exiting..."
    exit 1
  fi

  sudo chmod 0644 "$trusted_ca"
  # If TrustedUserCAKeys not defined, then add it to sshd_config
  sudo grep -q "^TrustedUserCAKeys" /etc/ssh/sshd_config || echo 'TrustedUserCAKeys' | sudo tee -a /etc/ssh/sshd_config
  # Ensure the value for TrustedUserCAKeys is configured correctly
  # sudo sed -i "s@TrustedUserCAKeys.*@TrustedUserCAKeys $trusted_ca@g" /etc/ssh/sshd_config 
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.tmp
  sudo python3 $SCRIPTDIR/replace_value.py -f /etc/ssh/sshd_config.tmp "TrustedUserCAKeys" " $trusted_ca"
  sudo mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config # if the python script doesn't error, then we update the original.  If this file were to be misconfigured it will break SSH and your instance.
}


function request_ssh_known_hosts {
  # local -r ssh_known_hosts_path="$1"
  # Add the CA cert to use it for known host verification
  # curl http://vault.service.consul:8200/v1/ssh-host-signer/public_key
  local -r value=$(vault read -field=public_key ssh-host-signer/config/ca)
  echo "$value" | tee "$HOME/.ssh/ssh_known_hosts_fragment" # we store the fragment for use on other hosts that need configuration.

  echo "Store the ssh_known_hosts_fragment as SSM parameter."
  if [[ -z "$TF_VAR_resourcetier" ]]; then
    log_error "TF_VAR_resourcetier is not defined.  Ensure you have run source ./update_vars.sh"
  fi
  parm_name="/firehawk/resourcetier/${TF_VAR_resourcetier}/ssh_known_hosts_fragment"
  aws ssm put-parameter \
      --name "${parm_name}" \
      --type "String" \
      --value "${value}" \
      --overwrite
}

function configure_ssh_known_hosts {
  local -r ssh_known_hosts_fragment="$1"
  local -r external_domain="$2"
  local -r key=$(cat $ssh_known_hosts_fragment)
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local -r ssh_known_hosts_path="/usr/local/etc/ssh/ssh_known_hosts"
  else
    local -r ssh_known_hosts_path="/etc/ssh/ssh_known_hosts"
  fi

  if sudo test ! -f $ssh_known_hosts_path; then
      echo "Creating $ssh_known_hosts_path"
      sudo touch $ssh_known_hosts_path # ensure known hosts file exists
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then # Acquire file permissions.
      octal_permissions=$(sudo stat -f %A "$ssh_known_hosts_path" | rev | sed -E 's/^([[:digit:]]{4})([^[:space:]]+)/\1/' | rev ) # clip to 4 zeroes
  else
      octal_permissions=$(sudo stat --format '%a' "$ssh_known_hosts_path" | rev | sed -E 's/^([[:digit:]]{4})([^[:space:]]+)/\1/' | rev) # clip to 4 zeroes
  fi
  octal_permissions=$( python3 -c "print( \"$octal_permissions\".zfill(4) )" ) # pad to 4 zeroes
  echo "$ssh_known_hosts_path octal_permissions currently $octal_permissions."
  if [[ "$octal_permissions" != "0644" ]]; then
      echo "...Setting to 0644"
      sudo chmod 0644 $ssh_known_hosts_path
  fi

  # init the cert auth line
  sudo grep -q "^@cert-authority \*\.consul" $ssh_known_hosts_path || echo "@cert-authority *.consul,*.$external_domain" | sudo tee -a $ssh_known_hosts_path
  # sudo sed -i "s#@cert-authority \*\.consul.*#@cert-authority *.consul,*.$external_domain $key#g" $ssh_known_hosts_path
  sudo python3 $SCRIPTDIR/replace_value.py -f $ssh_known_hosts_path "@cert-authority *.consul" ",*.$external_domain $key"

  echo "Added CA to $ssh_known_hosts_path."

  log_info "Restarting SSH service..."
  # mac / centos / amazon linux, restart ssh service
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
  else
    sudo systemctl restart sshd
  fi
  echo "Configure signed known hosts done."
}

function get_trusted_ca_ssm {
  local -r trusted_ca="$1"
  local -r resourcetier="$2"
  log_info "Validating that credentials are configured..."
  aws sts get-caller-identity
  log_info "Updating: $trusted_ca"
  aws ssm get-parameters --names /firehawk/resourcetier/$resourcetier/trusted_ca | jq -r '.Parameters[0].Value' | sudo tee "$trusted_ca"
}

function get_known_hosts_fragment_ssm {
  local -r ssh_known_hosts_fragment="$1"
  local -r resourcetier="$2"
  log_info "Updating: $cert"
  aws ssm get-parameters --names /firehawk/resourcetier/$resourcetier/ssh_known_hosts_fragment | jq -r '.Parameters[0].Value' | tee "$ssh_known_hosts_fragment"
}

function install {
  local ssh_known_hosts=""
  local trusted_ca=""
  local external_domain="$DEFAULT_EXTERNAL_DOMAIN"
  local aquire_ca_certs_via_ssm="false"
  local resourcetier="$DEFAULT_resourcetier"

  while [[ $# > 0 ]]; do
    local key="$1"
    case "$key" in
      --ssh-known-hosts)
        assert_not_empty "$key" "$2"
        local ssh_known_hosts="$2"
        shift
        ;;
      --trusted-ca)
        assert_not_empty "$key" "$2"
        trusted_ca="$2"
        shift
        ;;
      --external-domain)
        assert_not_empty "$key" "$2"
        external_domain="$2"
        shift
        ;;
      --ssm)
        aquire_ca_certs_via_ssm="true"
        ;;
      --resourcetier)
        resourcetier="$2"
        shift
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        log_error "Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac
    shift
  done

  error_if_empty "Argument resourcetier or env var TF_VAR_resourcetier not provided" "$resourcetier"

  if [[ "$aquire_ca_certs_via_ssm" == "true" ]]; then
    log_info "Requesting trusted CA via SSM Parameter..."
    trusted_ca="$DEFAULT_TRUSTED_CA"
    get_trusted_ca_ssm $trusted_ca "$resourcetier"
  elif [[ -z "$trusted_ca" ]]; then # if no trusted ca provided, request it from vault and store in default location.
    trusted_ca="$DEFAULT_TRUSTED_CA"
    log_info "Requesting Vault provide the trusted CA..."
    request_trusted_ca "$trusted_ca"
  else
    log_info "Trusted CA path provided. Skipping vault request. Copy to standard path..."
    cp -frv "$trusted_ca" "$DEFAULT_TRUSTED_CA"
    trusted_ca="$DEFAULT_TRUSTED_CA"
  fi

  log_info "Configure this host to use trusted CA: $trusted_ca"
  configure_trusted_ca "$trusted_ca" # configure trusted ca for our host

  if [[ "$aquire_ca_certs_via_ssm" == "true" ]]; then
    log_info "Requesting known hosts fragment via SSM Parameter..."
    ssh_known_hosts="$DEFAULT_SSH_KNOWN_HOSTS"
    get_known_hosts_fragment_ssm $ssh_known_hosts "$resourcetier"
  elif [[ -z "$ssh_known_hosts" ]]; then # if no trusted ca provided, request it from vault and store in default location.
    ssh_known_hosts="$DEFAULT_SSH_KNOWN_HOSTS"
    log_info "Requesting Vault provide the SSH known hosts CA as a fragment..."
    request_ssh_known_hosts
  else
    log_info "SSH known hosts CA path provided. Skipping vault request. Copy to standard path..."
    cp -frv "$ssh_known_hosts" "$DEFAULT_SSH_KNOWN_HOSTS"
    ssh_known_hosts="$DEFAULT_SSH_KNOWN_HOSTS"
  fi
  log_info "Configure this known hosts: $ssh_known_hosts external domain: $external_domain"

  if [[ -z "$external_domain" ]]; then
    log_error "You must provide a value for --external-domain"
    exit 1
  fi
  configure_ssh_known_hosts "$ssh_known_hosts" "$external_domain" # configure trusted ca for our host

  log_info "Complete!"
}

install "$@"



### End sign SSH host key




cd "$EXECDIR"