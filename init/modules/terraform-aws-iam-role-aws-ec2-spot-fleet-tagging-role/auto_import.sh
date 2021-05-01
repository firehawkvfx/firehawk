#!/bin/bash

echo "Determining if resource already exists in state file"
output=$(terragrunt state list | grep -m 1 'aws_iam_role.service_role') && exit_status=0 || exit_status=$?

if [[ ! exit_status -eq 0 ]]; then # if not, then attempt import
    output=$(terragrunt import aws_iam_role.service_role aws-ec2-spot-fleet-tagging-role) && exit_status=0 || exit_status=$?
    if [[ ! exit_status -eq 0 ]]; then # if import failed, assume we will be able to create it with terraform
        echo 'The iam role will be created by terraform'
    else
        echo "$output"
        echo "The resource was imported."
    fi
else
    echo "Resource already exists, no auto-import required"
fi