#!/bin/bash

echo "Determining if resource already exists in state file...  Ignore any immediate errors below"
output=$(terragrunt state list | grep -m 1 'aws_iam_role.service_role') 2> /dev/null && exit_status=0 || exit_status=$?

if [[ ! exit_status -eq 0 ]]; then # if not, then attempt import
    output=$(terragrunt import aws_iam_role.service_role aws-ec2-spot-fleet-tagging-role) > /dev/null 2>&1 && exit_status=0 || exit_status=$?
    if [[ ! exit_status -eq 0 ]]; then # if import failed, assume we will be able to create it with terraform
        echo
        echo 'The iam role will be created by terraform'
        echo
    else
        echo "$output"
        echo
        echo "The resource was imported."
        echo
    fi
else
    echo
    echo "Resource already exists, no auto-import required"
    echo
fi