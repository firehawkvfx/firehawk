#!/bin/bash

ansible-playbook -i ../secrets/dev/inventory ansible/aws-cli-ec2-install.yaml -v --extra-vars 'variable_host=firehawkgateway variable_user=deployuser'