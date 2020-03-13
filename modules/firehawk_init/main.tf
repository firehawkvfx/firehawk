
resource "null_resource" "init-awscli-deadlinedb-firehawk" {
  count = var.firehawk_init ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x
      cd /deployuser
      export storage_user_access_key_id=${var.storage_user_access_key_id}
      echo "storage_user_access_key_id=$storage_user_access_key_id"
      export storage_user_secret=${var.storage_user_secret}
      echo "storage_user_secret= $storage_user_secret"
      # Test keybase / pgp decryption options
      ./scripts/keybase-pgp-test.sh; exit_test
      # Install aws cli for user with s3 credentials.  root user only needs s3 access.  in future consider provisining a replacement access key for vagrant with less permissions, and remove the root account keys?
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=ansible_control variable_user=root"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=ansible_control variable_user=deployuser"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=firehawkgateway variable_user=deployuser"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=firehawkgateway variable_connect_as_user=deployuser variable_user=deadlineuser" --tags 'newuser,onsite-install'; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=firehawkgateway variable_connect_as_user=deployuser variable_user=deadlineuser"; exit_test
      # Add deployuser user to group syscontrol.   this is local and wont apply until after reboot, so try to avoid since we dont want to reboot the ansible control.
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars 'variable_user=deployuser' --tags 'onsite-install'; exit_test
      # Add user to syscontrol without the new user tag, it will just add a user to the syscontrol group
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars 'variable_host=firehawkgateway variable_connect_as_user=deployuser variable_user=deployuser' --tags 'onsite-install'; exit_test
      # Install deadline
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-install.yaml -v; exit_test
      # First db check
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
EOT
}
}

locals {
  deadlinedb_complete = element(concat(null_resource.init-awscli-deadlinedb-firehawk.*.id, list("")), 0)
}

output "deadlinedb-complete" {
  value = local.deadlinedb_complete
}

# Consider placing a dependency on cloud nodes on the deadline install.  Not likely to occur but would be better practice.

resource "null_resource" "init-routes-houdini-license-server" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.init-awscli-deadlinedb-firehawk]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x
      cd /deployuser
      # check db
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      # custom events auto assign groups to slaves on startup, eg slaveautoconf
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-repository-custom-events.yaml; exit_test
      # configure onsite NAS mounts to firehawkgateway
      ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml --extra-vars "variable_host=firehawkgateway variable_user=deployuser softnas_hosts=none" --tags 'local_install_onsite_mounts'; exit_test
      # ssh will be killed from the previous script because users were added to a new group and this will not update unless your ssh session is restarted.
      # login again and continue...
      # install houdini with the same procedure as on render nodes and workstations, and initialise the licence server on this system.
      ansible-playbook -i "$TF_VAR_inventory" ansible/modules/houdini-module/houdini-module.yaml -v --extra-vars "sesi_username=$TF_VAR_sesi_username sesi_password=$TF_VAR_sesi_password variable_host=firehawkgateway variable_connect_as_user=deployuser variable_user=deployuser houdini_install_type=server" --skip-tags "sync_scripts"; exit_test
      # ensure an aws pem key exists for ssh into cloud nodes
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-new-key.yaml; exit_test
      # configure routes to opposite environment for licence server to communicate if in dev environment
      ansible-playbook -i "$TF_VAR_inventory" ansible/firehawkgateway-update-routes.yaml; exit_test
      #check db
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
EOT
}
}

resource "null_resource" "init-aws-local-workstation" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.init-routes-houdini-license-server]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x
      cd /deployuser
      export storage_user_access_key_id=${var.storage_user_access_key_id}
      echo "storage_user_access_key_id=$storage_user_access_key_id"
      export storage_user_secret=${var.storage_user_secret}
      echo "storage_user_secret= $storage_user_secret"
      # add local host ssh keys to list of accepted keys on ansible control. Example for another onsite workstation-
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=$TF_VAR_workstation_address local=True"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "variable_host=$TF_VAR_workstation_address variable_user=deployuser local=True"; exit_test
      # now add this host and address to ansible inventory
      ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=workstation1 host_ip=$TF_VAR_workstation_address group_name=role_local_workstation insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test
      # Now this will init the deployuser on the workstation.  the deployuser wil become the primary user with ssh access.  once this process completes the first time.
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_sshuser.yaml -v --extra-vars "variable_host=workstation1 user_inituser_name=$TF_VAR_user_inituser_name ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test
      # test connection as new deployuser
      ansible -m ping workstation1 -i "$TF_VAR_inventory" --private-key=$TF_VAR_general_use_ssh_key -u deployuser --become; exit_test
      # we can use the deploy user to create more users as well, like the deadlineuser for artist use.
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_connect_as_user=deployuser variable_user=deadlineuser variable_host=workstation1 ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key" --tags 'newuser,onsite-install'; exit_test
      # create and copy an ssh rsa key from ansible control to the workstation for provisioning.  1st time will error, run it twice
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation1 variable_user=$TF_VAR_user_inituser_name ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test
      # configure aws for all users
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=workstation1 variable_user=deployuser aws_cli_root=true ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser aws_cli_root=true ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_private_key"; exit_test

      #check db
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
EOT
}
}

resource "null_resource" "install-deadline-local-workstation" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.init-aws-local-workstation]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x
      cd /deployuser
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      # configure deadline on the local workstation with the keys from this install to run deadline slave and monitor
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-worker-install.yaml --tags "onsite-install" --extra-vars "variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
EOT
}
}

resource "null_resource" "install-houdini-local-workstation" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.install-deadline-local-workstation]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x
      cd /deployuser
      ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      # install houdini on a local workstation with deadline submitters and environment vars.
      if [[ "$TF_VAR_install_houdini"==true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/modules/houdini-module/houdini-module.yaml -v --extra-vars "sesi_username=$TF_VAR_sesi_username sesi_password=$TF_VAR_sesi_password variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser" --skip-tags "sync_scripts"; exit_test
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-ffmpeg.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser"; exit_test
      fi
EOT
}
}

resource "null_resource" "local-provisioning-complete" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.install-houdini-local-workstation]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      echo '...Firehawk Init Complete'
EOT
}
}

locals {
  local_provisioning_complete = element(concat(null_resource.local-provisioning-complete.*.id, list("")), 0)
}

output "local-provisioning-complete" {
  value = local.local_provisioning_complete
}

