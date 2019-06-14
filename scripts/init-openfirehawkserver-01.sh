echo 'Use vagrant reload and vagrant ssh after eexecuting each .sh script'

cd /vagrant
source ./update_vars.sh --dev
echo "openfirehawkserver ip: $TF_VAR_openfirehawkserver"

ansible-playbook -i ansible/inventory/hosts ansible/init.yaml --extra-vars "variable_user=vagrant"
ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadline.yaml
ansible-playbook -i ansible/inventory/hosts ansible/deadline-repository-custom-events.yaml

echo "if above was succesful, exit the vm and use 'vagrant reload' before continuing with the next script.  New user group added wont have user added until reload."