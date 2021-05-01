#!/bin/bash

terragrunt state list | grep -m 1 'aws_iam_role.service_role' || terragrunt import aws_iam_role.service_role aws-ec2-spot-fleet-tagging-role || echo 'The iam role will be created by terraform'