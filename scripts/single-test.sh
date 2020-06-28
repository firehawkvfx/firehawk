#!/bin/bash

echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"

aws ec2 describe-instances --filter "Name=instance-state-name,Values=running" --filter "Name=tag:conflictkey,Values=$TF_VAR_conflictkey" --query "Reservations[*].Instances[*][Tags[?Key=='Name'].Value[],NetworkInterfaces[0].PrivateIpAddresses[0].PrivateIpAddress]" --output text