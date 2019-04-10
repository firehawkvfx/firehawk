echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"
cd /vagrant
ansible-playbook -i ansible/inventory/hosts ansible/init.yaml -v
ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadline.yaml -v
ansible-playbook -i ansible/inventory/hosts ansible/openfirehawkserver_houdini.yaml -v
ansible-playbook -i ansible/inventory/hosts ansible/aws-new-key.yaml -v

# This provisions the deadline slave and monitor on another local workstation.
# ansible -m ping workstation.firehawkvfx.com -i "$TF_VAR_inventory"
# ansible-playbook -i "$TF_VAR_inventory" ansible/localworkstation-deadlineuser.yaml --tags "onsite-install"

#reboot
# terraform apply --auto-approve