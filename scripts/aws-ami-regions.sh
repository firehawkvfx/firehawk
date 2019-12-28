#!/bin/bash
# Takes a filter in the form "Name=description,Values=SoftNAS Cloud Platinum - Consumption - 4.3.0" and provides the AMI ID's for all regions

if [ -z "$1" ] ; then
    echo '"Provide a filter as a second argument, eg "Name=description,Values=SoftNAS Cloud Platinum - Consumption - 4.3.0"'
    exit 1
fi
filters="$1"

declare -a regions=($(aws ec2 describe-regions --output json | jq '.Regions[].RegionName' | tr "\\n" " " | sed 's/"//g'))
for region in "${regions[@]}" ; do
    ami=$(aws ec2 describe-images --filters "$filters" --region ${region} --query 'Images[*].[ImageId]' --output json | jq '.[0][0]')
    printf "${region} = ${ami}\n"
done