#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script

# Take the base AMI created from the bastion-ami folder and install NVIDIA drivers.

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')

# Packer Vars
# export PKR_VAR_aws_region="$AWS_DEFAULT_REGION"
# if [[ -f "$SCRIPTDIR/../bastion-ami/manifest.json" ]]; then
#     export PKR_VAR_bastion_centos7_ami="$(jq -r '.builds[] | select(.name == "centos7-ami") | .artifact_id' $SCRIPTDIR/../bastion-ami/manifest.json | tail -1 | cut -d ":" -f2)"
#     echo "Found bastion_centos7_ami in manifest: PKR_VAR_bastion_centos7_ami=$PKR_VAR_bastion_centos7_ami"
# fi
set -e

export PACKER_LOG=1
export PACKER_LOG_PATH="$SCRIPTDIR/packerlog.log"

mkdir -p /tmp/nvidia/
aws s3 sync s3://ec2-linux-nvidia-drivers/latest/ /tmp/nvidia/. --include "NVIDIA-Linux-x86_64-*-grid-aws.run"
export PKR_VAR_nvidia_driver=$(ls /tmp/nvidia/NVIDIA-Linux-x86_64-*-grid-aws.run | tail -1)

export PKR_VAR_manifest_path="$SCRIPTDIR/manifest.json"
rm -f $PKR_VAR_manifest_path
packer build $SCRIPTDIR/nice-dcv.json.pkr.hcl -var ca_public_key_path=$TF_VAR_ca_public_key_file_path