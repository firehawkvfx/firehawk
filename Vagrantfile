# you must install this plugin to set the disk size:
# vagrant plugin install vagrant-disksize

Vagrant.configure("2") do |config|
  # Ubuntu 16.04
  config.vm.box = "ubuntu/xenial64"
  # networking issues
  #config.vm.box = "bento/ubuntu-16.04"
  # cant install xserver-xorg-legacy
  # config.vm.box = "ubuntu/trusty64"
  #config.vm.box = "bento/ubuntu-17.10"
  #18 has no rc.local
  #config.vm.box = "bento/ubuntu-18.04"
  #config.vm.box_version = "20190411.0.0"
  #config.ssh.username = "vagrant"
  #config.ssh.password = ENV['TF_VAR_vagrant_password']

  mac_string = ENV['TF_VAR_vagrant_mac']
  vaultkeypresent = ENV['TF_VAR_vaultkeypresent']
  bridgenic = ENV['TF_VAR_bridgenic']
  envtier = ENV['TF_VAR_envtier']
  name = ENV['TF_VAR_openfirehawkserver_name']
  openfirehawkserver = ENV['TF_VAR_openfirehawkserver']
  network = ENV['TF_VAR_network']

  config.vm.define "ansible_control_"+envtier
  config.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
  config.disksize.size = '50GB'


  # #config.vm.network "public_network", bridge: "eno1",
  if network == 'public'
      config.vm.network "public_network", mac: mac_string, bridge: bridgenic
    else
      # use a private network mode if you don't have control over the network environment - eg wifi in a cafe / other location.
      config.vm.network "private_network", ip: openfirehawkserver, mac: mac_string
    end
  
  # routing issues?  https://stackoverflow.com/questions/35208188/how-can-i-define-network-settings-with-vagrant
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
    # Customize the amount of memory on the VM:
    vb.memory = ENV['TF_VAR_openfirehawkserver_ram']
    vb.cpus = ENV['TF_VAR_openfirehawkserver_vcpus']
    vb.customize ["modifyvm", :id, "--accelerate2dvideo", "on"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
    #enable promiscuous mode to enable routes from aws through the openfirehawkserver vpn into your local network
    vb.customize ["modifyvm", :id, "--nicpromisc0", "allow-all"]
    vb.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
  end
  config.vm.provision "shell", inline: "echo 'source /vagrant/scripts/env.sh' > /etc/profile.d/sa-environment.sh", :run => 'always'
  config.vm.provision "shell", inline: "echo DEBIAN_FRONTEND=$DEBIAN_FRONTEND"

  # ## block to install custom private key
  # config.ssh.insert_key = false
  # config.ssh.private_key_path = ["keys/my_key_pair_"+envtier+".pem", "~/.vagrant.d/insecure_private_key"]
  # config.vm.provision "file", source: "keys/my_key_pair_"+envtier+".pub", destination: "~/.ssh/authorized_keys"
  # config.vm.provision "shell", inline: <<-EOC
  #   sudo sed -i -e "\\#PasswordAuthentication yes# s#PasswordAuthentication yes#PasswordAuthentication no#g" /etc/ssh/sshd_config
  #   sudo service ssh restart
  # EOC
  # ## end block for custom private key

  config.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive"
  config.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/Australia/Brisbane /etc/localtime", run: "always"
  config.vm.provision "shell", inline: "sudo apt-get update"
  #config.vm.provision "shell", inline: "sudo apt-get upgrade"
  config.vm.provision "shell", inline: "sudo apt-get install -y sshpass"

  ### Install Ansible Block ###
  config.vm.provision "shell", inline: "sudo apt-get install -y software-properties-common"
  config.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
  config.vm.provision "shell", inline: "sudo apt-get install -y ansible"
  # ='2.7.10-1ppa~xenial'"
  # we define the location of the ansible hosts file in an environment variable.
  config.vm.provision "shell", inline: "grep -qxF 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' /etc/environment || echo 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' | sudo tee -a /etc/environment"
  #reboot required for desktop to function.
  ### End Install Ansible Block ###

  # config.vm.provision "shell", inline: "sudo apt-get upgrade -y"

  # config.vm.provision "shell", inline: "sudo reboot"
  # # trigger reload
  # config.vm.provision :reload

  ### Install ubuntu desktop and virtualbox additions.  Because a reboot is required, provisioning is handled here. ###
  # # Install the gui with vagrant or install the gui with ansible installed on the host.  
  # # This creates potentiall issues because ideally, Ansible should be used within the vm only to limit ansible version issues if the user updates vagrant on their host.
  # install ubuntu
  config.vm.provision "shell", inline: "sudo apt-get install -y ubuntu-desktop"
  # ...or xfce.  pick one.
  #config.vm.provision "shell", inline: "sudo apt-get install -y curl xfce4"
  config.vm.provision "shell", inline: "sudo apt-get install -y virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 xserver-xorg-legacy"

  # Permit anyone to start the GUI
  config.vm.provision "shell", inline: "sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' /etc/X11/Xwrapper.config"
  #disable the update notifier.  We do not want to update to ubuntu 18, currently deadline installer gui doesn't work in 18.
  config.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
  ### End Ubuntu Desktop block ###
  # for dpkg or virtualbox issues, see https://superuser.com/questions/298367/how-to-fix-virtualbox-startup-error-vboxadd-service-failed

  config.vm.provision "shell", inline: "sudo reboot"
  # trigger reload
  config.vm.provision :reload

  # configure routes on startup.  not working for unknown reason.
  # config.vm.provision "shell", inline: "set -x && cd /vagrant && source ./update_vars.sh $TF_VAR_envtier && ansible-playbook -i ansible/inventory ansible/openvpn.yaml -v --tags add-routes --extra-vars 'variable_gather_facts=false' ", run:"always"

  #config.vm.provision "shell", inline: "sudo VBoxClient-all"
  #config.vm.provision "shell", inline: "sudo startxfce4&"
  
  #ansible provissioning
  #ansible_inventory_dir = "ansible/hosts"
  # config.vm.provision "playbook1", type:'ansible_local' do |ansible|
  #   ansible.playbook = "ansible/init.yaml"
  # end
  config.trigger.after :up do |trigger|
    trigger.warn = "Taking Snapshot"
    trigger.run = {inline: "vagrant snapshot push"}
  end

  config.vm.provision "shell", inline: "sudo reboot"
  # trigger reload
  config.vm.provision :reload
  
  # ansible_inventory_dir = "ansible/inventory/hosts"
  # config.vm.define "autoconfig" do |autoconfig|
  #   #this currently has issues in replicating identical behaviour to running ansible within the vm and errors occur.
  #   config.vm.provision "shell", inline: "cd /vagrant && source ./update_vars.sh --$TF_VAR_envtier && ansible-playbook -i ansible/inventory/hosts ansible/init.yaml"
  #   # config.vm.provision "playbook1", type:'ansible_local' do |ansible|
  #   #   ansible.playbook = "ansible/init.yaml"
  #   #   ansible.inventory_path = "ansible/inventory/hosts"
  #   # end
  # end
end