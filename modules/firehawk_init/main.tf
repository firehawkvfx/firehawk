
resource "null_resource" "init_awscli" {
  count = var.firehawk_init ? 1 : 0

  triggers = {
    storage_user_access_key_id = var.storage_user_access_key_id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      # set -x
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

      # # configure routes to opposite environment for licence server to communicate if in dev environment
      ansible-playbook -i "$TF_VAR_inventory" ansible/firehawkgateway-update-routes.yaml; exit_test

      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=firehawkgateway variable_connect_as_user=deployuser variable_user=deadlineuser" --tags 'newuser,onsite-install'; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=firehawkgateway variable_connect_as_user=deployuser variable_user=deadlineuser"; exit_test
      # Add deployuser user to group syscontrol.   this is local and wont apply until after reboot, so try to avoid since we dont want to reboot the ansible control.
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars 'variable_user=deployuser' --tags 'onsite-install'; exit_test
      # Add user to syscontrol without the new user tag, it will just add a user to the syscontrol group
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars 'variable_host=firehawkgateway variable_connect_as_user=deployuser variable_user=deployuser' --tags 'onsite-install'; exit_test

      # configure onsite NAS mounts to firehawkgateway and ansible control for sync handling
      ansible-playbook -i "$TF_VAR_inventory" ansible/linux-volume-mounts.yaml --extra-vars "variable_host=firehawkgateway variable_user=deployuser softnas_hosts=none" --tags 'local_install_onsite_mounts'; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/linux-volume-mounts.yaml --extra-vars "variable_host=localhost variable_user=deployuser softnas_hosts=none" --tags 'local_install_onsite_mounts'; exit_test
EOT
}
}

output "init_awscli_complete" {
  value = null_resource.init_awscli
  depends_on = [
    null_resource.init_awscli
  ]
}

resource "null_resource" "init_deadlinedb_firehawk" {
  count = var.firehawk_init ? 1 : 0

  depends_on = [ null_resource.init_awscli ]

  triggers = {
    install_deadline_db = var.install_deadline_db
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      # set -x
      cd /deployuser

      export storage_user_access_key_id=${var.storage_user_access_key_id}
      export storage_user_secret=${var.storage_user_secret}

      export storage_user_access_key_id=${var.storage_user_access_key_id}
      echo "storage_user_access_key_id=$storage_user_access_key_id"
      export storage_user_secret=${var.storage_user_secret}
      echo "storage_user_secret= $storage_user_secret"
      if [[ "$TF_VAR_install_deadline_db" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-install.yaml -v --extra-vars "user_deadlineuser_name=deployuser"; exit_test
        if [[ "$TF_VAR_install_deadline_rcs" == true ]]; then
          ansible-playbook -i "$TF_VAR_inventory" ansible/deadlinercs.yaml -v --extra-vars "user_deadlineuser_name=deployuser"; exit_test
          ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-repository-custom-events.yaml -v --extra-vars "user_deadlineuser_name=deployuser"; exit_test
          ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test  
        fi
      fi
EOT
}
}

locals {
  deadlinedb_complete = element(concat(null_resource.init_deadlinedb_firehawk.*.id, list("")), 0)
}

output "deadlinedb_complete" {
  value = local.deadlinedb_complete
  depends_on = [
    null_resource.init_deadlinedb_firehawk
  ]
}

# Consider placing a dependency on cloud nodes on the deadline install.  Not likely to occur but would be better practice.

resource "null_resource" "init_houdini_license_server" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.init_deadlinedb_firehawk]

  triggers = {
    install_deadline_db = var.install_deadline_db
    install_houdini = var.install_houdini
    deadlinedb = local.deadlinedb_complete
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      # set -x
      cd /deployuser
      
      # ssh will be killed from the previous script because users were added to a new group and this will not update unless your ssh session is restarted.
      # login again and continue...
      if [[ "$TF_VAR_install_houdini_license_server" == true ]]; then
        # install houdini with the same procedure as on render nodes and workstations, and initialise the licence server on this system.
        ansible-playbook -i "$TF_VAR_inventory" ansible/collections/ansible_collections/firehawkvfx/houdini/houdini_module.yaml -v --extra-vars "variable_host=firehawkgateway variable_connect_as_user=deployuser variable_user=deployuser houdini_install_type=server" --tags "install_houdini set_hserver install_deadline_db" --skip-tags "sync_scripts"; exit_test
      fi
EOT
}
}

resource "null_resource" "init_aws_local_workstation" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.init_deadlinedb_firehawk]

  triggers = {
    # deadlinedb = local.deadlinedb_complete
    storage_user_access_key_id = var.storage_user_access_key_id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      # set -x
      cd /deployuser

      export storage_user_access_key_id=${var.storage_user_access_key_id}
      echo "storage_user_access_key_id=$storage_user_access_key_id"
      export storage_user_secret=${var.storage_user_secret}
      echo "storage_user_secret= $storage_user_secret"
      # add local host ssh keys to list of accepted keys on ansible control. Example for another onsite workstation-
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=$TF_VAR_workstation_address local=True"; exit_test

      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "variable_host=$TF_VAR_workstation_address variable_user=deployuser local=True"; exit_test

      # now add this host and address to ansible inventory
      ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=workstation1 host_ip=$TF_VAR_workstation_address group_name=role_local_workstation insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key"; exit_test

      # Now this will init the deployuser on the workstation.  the deployuser wil become the primary user with ssh access.  once this process completes the first time.
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_sshuser.yaml -v --extra-vars "variable_host=workstation1 user_inituser_name=$TF_VAR_user_inituser_name ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key"; exit_test

      # test connection as new deployuser
      ansible -m ping workstation1 -i "$TF_VAR_inventory" --private-key=$TF_VAR_general_use_ssh_key -u deployuser --become; exit_test

      # we can use the deploy user to create more users as well, like the deadlineuser for artist use.
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_connect_as_user=deployuser variable_user=deadlineuser variable_host=workstation1 ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key" --tags 'newuser,onsite-install'; exit_test

      # create and copy an ssh rsa key from ansible control to the workstation for provisioning.  1st time will error, run it twice
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key"; exit_test

      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-copy-id-private-host.yaml -v --extra-vars "variable_host=workstation1 variable_user=$TF_VAR_user_inituser_name ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key"; exit_test

      # configure aws for all users
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -vv --extra-vars "variable_host=workstation1 variable_user=deployuser aws_cli_root=true ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key"; exit_test

      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -vv --extra-vars "variable_host=workstation1 variable_user=deadlineuser aws_cli_root=true ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key"; exit_test
      
      # configure mounts
      ansible-playbook -i "$TF_VAR_inventory" ansible/linux-volume-mounts.yaml --extra-vars "variable_host=workstation1 variable_user=deployuser softnas_hosts=none" --tags 'local_install_onsite_mounts'; exit_test
EOT
}
}

resource "null_resource" "local_workstation_disk_space_check" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.init_aws_local_workstation]
  triggers = {
    install_houdini = var.install_houdini
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      # set -x
      cd /deployuser
      if [[ "$TF_VAR_install_houdini" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/diskspace-check.yaml -v --extra-vars "variable_host=workstation1 variable_connect_as_user=deployuser"; exit_test
      fi
EOT
}
}

resource "null_resource" "install_houdini_local_workstation" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.init_awscli, null_resource.init_aws_local_workstation, null_resource.local_workstation_disk_space_check, null_resource.init_houdini_license_server]

  triggers = {
    install_houdini = var.install_houdini
    init_awscli = "${join(",", null_resource.init_awscli.*.id)}"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      # set -x
      cd /deployuser
      # install houdini on a local workstation with deadline submitters and environment vars.
      if [[ "$TF_VAR_install_houdini" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/collections/ansible_collections/firehawkvfx/houdini/houdini_module.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser" --tags "install_houdini" --skip-tags "sync_scripts"; exit_test
        ansible-playbook -i "$TF_VAR_inventory" ansible/collections/ansible_collections/firehawkvfx/houdini/configure_hserver.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser firehawk_sync_source=$TF_VAR_firehawk_sync_source"; exit_test
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-ffmpeg.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser"; exit_test
      fi
EOT
}
}

resource "null_resource" "install_deadline_worker_local_workstation" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.init_aws_local_workstation, null_resource.init_houdini_license_server, null_resource.init_deadlinedb_firehawk, null_resource.install_houdini_local_workstation]

  triggers = {
    install_deadline_db = var.install_deadline_db
    install_deadline_worker = var.install_deadline_worker
    install_houdini = var.install_houdini
    deadlinedb = local.deadlinedb_complete
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      # set -x
      cd /deployuser
      if [[ "$TF_VAR_install_deadline_worker" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
        # configure deadline on the local workstation with the keys from this install to run deadline slave and monitor
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-worker-install.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser"; exit_test
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      fi
EOT
}
}


resource "null_resource" "install_houdini_deadline_plugin_local_workstation" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.install_deadline_worker_local_workstation, null_resource.init_aws_local_workstation, null_resource.init_houdini_license_server, null_resource.init_deadlinedb_firehawk, null_resource.install_houdini_local_workstation]

  triggers = {
    install_deadline_db = var.install_deadline_db
    install_deadline_worker = var.install_deadline_worker
    install_houdini = var.install_houdini
    deadlinedb = local.deadlinedb_complete
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      # set -x
      cd /deployuser
      if [[ "$TF_VAR_install_deadline_worker" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      fi
      # install houdini on a local workstation with deadline submitters and environment vars.
      if [[ "$TF_VAR_install_houdini" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/collections/ansible_collections/firehawkvfx/houdini/houdini_module.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser" --tags "install_deadline_db" --skip-tags "sync_scripts"; exit_test
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-ffmpeg.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser"; exit_test

        if [[ $TF_VAR_houdini_test_connection == true ]]; then
          # last step before building ami we run a unit test to ensure houdini runs
          ansible-playbook -i "$TF_VAR_inventory" ansible/collections/ansible_collections/firehawkvfx/houdini/houdini_unit_test.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser variable_connect_as_user=deployuser firehawk_sync_source=$TF_VAR_firehawk_sync_source execute=true"; exit_test
        fi
      fi
      # if [[ "$TF_VAR_install_deadline_worker" == true ]]; then
      #   ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      # fi
EOT
}
}

resource "null_resource" "local-provisioning-complete" {
  count = var.firehawk_init ? 1 : 0
  depends_on = [null_resource.install_houdini_deadline_plugin_local_workstation, null_resource.install_deadline_worker_local_workstation, null_resource.init_aws_local_workstation, null_resource.init_houdini_license_server, null_resource.init_deadlinedb_firehawk]

  triggers = {
    install_deadline_db = var.install_deadline_db
    install_deadline_worker = var.install_deadline_worker
    install_houdini = var.install_houdini
    deadlinedb = local.deadlinedb_complete
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      if [[ "$TF_VAR_install_deadline_db" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      fi
      echo '...Firehawk Init Complete'
EOT
}
}

locals {
  local_provisioning_complete = element(concat(null_resource.local-provisioning-complete.*.id, list("")), 0)
}

output "local-provisioning-complete" {
  value = local.local_provisioning_complete
  depends_on = [
    null_resource.local-provisioning-complete
  ]
}

