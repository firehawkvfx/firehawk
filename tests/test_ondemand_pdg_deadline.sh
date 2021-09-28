#!/bin/bash

# This is an automated cook test.  

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script
mount_cloud_prod="/Volumes/cloud_prod"
test_dir="$mount_cloud_prod/tests"

echo "...Ensuring filegateway is mounted"
mount | grep $mount_cloud_prod

sudo rm -fr "$test_dir"
mkdir "$test_dir"
sudo chown 9001:9001 "$test_dir"
sudo chmod 777 "$test_dir"

cp -frv $SCRIPTDIR/test_ondemand_pdg_deadline* "$test_dir"

output_dir="$test_dir/geo"
output_file="$output_dir/test_ondemand_pdg_deadline.spheregeo.0001.bgeo.sc"

cd /opt/hfs18.5; source ./houdini_setup
cd $SCRIPTDIR

hython $test_dir/test_ondemand_pdg_deadline.hip $test_dir/test_ondemand_pdg_deadline.py

if [[ -z "$output_file" ]]; then
    echo "FAILED: output was not on disk after test at path: $output_dir"
    exit 1
else
    echo "PASSED: output was found on disk after test at path: $output_dir"
    exit 0
fi