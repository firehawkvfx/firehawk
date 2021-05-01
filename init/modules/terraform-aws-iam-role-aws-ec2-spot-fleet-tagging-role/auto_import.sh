#!/bin/bash

state_path='aws_iam_role.service_role'
resource_id='aws-ec2-spot-fleet-tagging-role'

echo "Determining if resource already exists in state file..."
output=$((terragrunt state list | grep -m 1 $state_path) 2>&1) && exit_status=0 || exit_status=$?

if [[ ! exit_status -eq 0 ]]; then # if not, then attempt import
    output=$((terragrunt import $state_path $resource_id) 2>&1) && exit_status=0 || exit_status=$?
    if [[ ! exit_status -eq 0 ]]; then # if import failed, assume we will be able to create it with terraform
        echo
        echo "The resource $resource_id will be created by terraform"
        echo
    else
        echo "$output"
        echo
        echo "The resource was imported."
        echo
    fi
else
    echo
    echo "Resource already exists, no auto-import required for: $resource_id"
    echo
fi