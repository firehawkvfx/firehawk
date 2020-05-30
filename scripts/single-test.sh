#!/bin/bash

ansible-playbook -i ../secrets/dev/inventory ansible/ansible_collections/firehawkvfx/softnas/linux_volume_mounts.yaml --extra-vars 'variable_host=firehawkgateway variable_user=deployuser softnas_hosts=none' --tags local_install_onsite_mounts