#!/bin/bash

# This installs a Deadline Worker

set -e

# User vars
installers_bucket="${installers_bucket}"
deadlineuser_name="${deadlineuser_name}"
deadline_version="${deadline_version}"
download_dir="/var/tmp/downloads"
dbport="27100"
db_host_name="deadlinedb.service.consul"
deadline_proxy_certificate="Deadline10RemoteClient.pfx"

# Script vars (implicit)
deadline_proxy_root_dir="$db_host_name:4433"
deadline_client_certificate_basename="${deadline_client_certificate%.*}"
deadline_linux_installers_tar="/tmp/Deadline-${deadline_version}-linux-installers.tar"
deadline_linux_installers_filename="$(basename $deadline_linux_installers_tar)"
deadline_linux_installers_basename="${deadline_linux_installers_filename%.*}"
deadline_installer_dir="$download_dir/$deadline_linux_installers_basename"
deadline_client_installer_filename="DeadlineClient-${deadline_version}-linux-x64-installer.run"

# # set hostname
# cat /etc/hosts | grep -m 1 "127.0.0.1   $this_host_name" || echo "127.0.0.1   $this_host_name" | sudo tee -a /etc/hosts
# sudo hostnamectl set-hostname $this_host_name

# Functions
function has_yum {
  [[ -n "$(command -v yum)" ]]
}
function has_apt_get {
  [[ -n "$(command -v apt-get)" ]]
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
function install_dependencies {
  log_info "Installing dependencies"
  if $(has_apt_get); then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y lsb xdg-utils
    sudo mkdir -p /usr/share/desktop-directories
  elif $(has_yum); then
    sudo yum install -y redhat-lsb samba-client samba-common cifs-utils nfs-utils tree bzip2 nmap
  else
    log_error "Could not find apt-get or yum. Cannot install dependencies on this OS."
    exit 1
  fi
  
}
install_dependencies

# ensure directory exists
# sudo mkdir -p "$download_dir"
# sudo chown $deadlineuser_name:$deadlineuser_name "$download_dir"

# # Download Deadline
# if [[ -f "$deadline_linux_installers_tar" ]]; then
#     echo "File already exists: $deadline_linux_installers_tar"
# else
#     # Prefer installation from Thinkbox S3 Bucket for visibility when a version is deprecated.
#     output=$(aws s3api head-object --bucket thinkbox-installers --key "Deadline/${deadline_version}/Linux/${deadline_linux_installers_filename}") && exit_status=0 || exit_status=$?
#     if [[ $exit_status -eq 0 ]]; then
#         echo "...Downloading Deadline from: thinkbox-installers"
#         aws s3api get-object --bucket thinkbox-installers --key "Deadline/${deadline_version}/Linux/${deadline_linux_installers_filename}" "${deadline_linux_installers_tar}"
#         # If this doesn't exist in user bucket, upload it for reproducibility (incase the Thinkbox installer becomes unavailable).
#         echo "...Querying if this file exists in $installers_bucket"
#         output=$(aws s3api head-object --bucket $installers_bucket --key "$deadline_linux_installers_filename") && exit_status=0 || exit_status=$?
#         if [[ ! $exit_status -eq 0 ]]; then
#             echo "Uploading the file to $installers_bucket $deadline_linux_installers_filename"
#             aws s3api put-object --bucket $installers_bucket --key "$deadline_linux_installers_filename" --body "${deadline_linux_installers_tar}"
#         else
#             echo "The bucket $installers_bucket already contains: $deadline_linux_installers_filename"
#         fi
#     else
#         printf "\n\nWarning: The installer was not aquired from Thinkbox.  It may have become deprecated.  Other AWS Accounts will not be able to install this version.\n\n"
#         echo "...Downloading from: $installers_bucket"
#         aws s3api get-object --bucket $installers_bucket --key "$deadline_linux_installers_filename" "${deadline_linux_installers_tar}"
#     fi
# fi

# Directories and permissions
sudo mkdir -p /opt/Thinkbox
sudo chown $deadlineuser_name:$deadlineuser_name /opt/Thinkbox
sudo chmod u=rwX,g=rX,o-rwx /opt/Thinkbox

# Client certs live here
deadline_client_certificates_location="/opt/Thinkbox/certs"
sudo mkdir -p "$deadline_client_certificates_location"
sudo chown $deadlineuser_name:$deadlineuser_name $deadline_client_certificates_location
sudo chmod u=rwX,g=rX,o-rwx "$deadline_client_certificates_location"

sudo mkdir -p $deadline_installer_dir

# Extract Installer
# sudo tar -xvf $deadline_linux_installers_tar -C $deadline_installer_dir

# Install Client:
# Deadline Worker
echo "Installing Client $deadline_installer_dir/$deadline_client_installer_filename"
sudo $deadline_installer_dir/$deadline_client_installer_filename \
--mode unattended \
--launcherdaemon true \
--debuglevel 2 \
--prefix /opt/Thinkbox/Deadline10 \
--connectiontype Remote \
--noguimode true \
--licensemode UsageBased \
--daemonuser "$deadlineuser_name" \
--httpport 8080 \
--tlsport 4433 \
--enabletls true \
--slavestartup 1 \
--proxyrootdir $deadline_proxy_root_dir \
--proxycertificate $deadline_client_certificates_location/$deadline_proxy_certificate
# --proxycertificatepassword avaultpassword

# finalize permissions post install:
sudo chown $deadlineuser_name:$deadlineuser_name /opt/Thinkbox/certs/*
sudo chmod u=wr,g=r,o-rwx /opt/Thinkbox/certs/*
# sudo chmod u=wr,g=r,o=r /opt/Thinkbox/certs/ca.crt

sudo service deadline10launcher restart

# echo "Validate that a connection with the database can be established with the config"
# sudo /opt/Thinkbox/DeadlineDatabase10/mongo/application/bin/deadline_mongo --eval 'printjson(db.getCollectionNames())'
