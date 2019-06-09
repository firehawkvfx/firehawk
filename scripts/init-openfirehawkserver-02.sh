# ssh will be killed from the above command because users were added to a new group and this will not update unless your ssh session is restarted.
# login again and continue...
# vagrant reload
# vagrant ssh

cd /vagrant
source ./update_vars.sh --dev
ansible-playbook -i ansible/inventory/hosts ansible/openfirehawkserver_houdini.yaml
ansible-playbook -i ansible/inventory/hosts ansible/aws-new-key.yaml

# these are optional if you have an onsite RHEL / CENTOS workstation
# add local host ssh keys to list of accepted keys on ansible control, example for another onsite workstation-
ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=192.168.92.12 local=True"

# create and copy an ssh rsa key from ansible control to the workstation for provisioning.  1st time will error, run it twice
ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"
ansible-playbook -i secrets/dev/inventory/hosts ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"

# configure deadline on the local workstation with the keys from this install to run deadline slave and monitor
ansible-playbook -i secrets/dev/inventory/hosts ansible/localworkstation-deadlineuser.yaml --tags "onsite-install" --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_key"

echo "if above was succesful, exit the vm and use 'vagrant reload' before continuing with the next script"