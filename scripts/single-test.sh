#!/bin/bash

ansible-playbook -i ../secrets/dev/inventory ansible/ansible_collections/firehawkvfx/houdini/houdini_module.yaml -v --extra-vars 'variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser' --tags install_houdini --skip-tags sync_scripts