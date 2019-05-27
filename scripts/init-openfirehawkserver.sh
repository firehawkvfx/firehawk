echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"
cd /vagrant
ansible-playbook -i ansible/inventory/hosts ansible/init.yaml -v --extra-vars "variable_user=vagrant"
ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadline.yaml -v
ansible-playbook -i ansible/inventory/hosts ansible/openfirehawkserver_houdini.yaml -v
ansible-playbook -i ansible/inventory/hosts ansible/aws-new-key.yaml -v

# add local host ssh keys to list of accepted keys on ansible control, example for another onsite workstation-
ansible-playbook -i ansible/inventory ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=192.168.92.12 local=True"

# create and copy an ssh rsa key from ansible control to the workstation for provisioning
ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser"

# This provisions the deadline slave and monitor on another local workstation.
# ansible -m ping workstation.firehawkvfx.com -i "$TF_VAR_inventory"
# ansible-playbook -i "$TF_VAR_inventory" ansible/localworkstation-deadlineuser.yaml --tags "onsite-install"

#reboot
# terraform apply --auto-approve