
cd /vagrant
source ./update_vars.sh --dev
echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

ansible-playbook -i ansible/inventory/hosts ansible/init.yaml --extra-vars "variable_user=vagrant"
ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadline.yaml
