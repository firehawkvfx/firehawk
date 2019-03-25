# you must install this plugin to set the disk size:
# vagrant plugin install vagrant-disksize

Vagrant.configure("2") do |config|
  # Ubuntu 16.04
  config.vm.box = "ubuntu/xenial64"
  #config.vm.box = "bento/ubuntu-16.04"
  #config.ssh.username = "vagrant"
  #config.ssh.password = "vagrant"
  
  mac_string = ENV['TF_VAR_vagrant_mac']
  vaultkeypresent = ENV['TF_VAR_vaultkeypresent']
  bridgenic = ENV['TF_VAR_bridgenic']
  envtier = ENV['TF_VAR_envtier']
  name = ENV['TF_VAR_openfirehawkserver_name']

  config.vm.define envtier
  config.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
  config.disksize.size = '50GB'
  #config.vm.network "public_network", bridge: "eno1",
  config.vm.network "public_network", mac: mac_string, bridge: bridgenic
  
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
  config.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/Australia/Brisbane /etc/localtime", run: "always"
  config.vm.provision "shell", inline: "sudo apt-get update"
  config.vm.provision "shell", inline: "sudo apt-get install -y sshpass"
  # Install ubuntu desktop and virtualbox additions.  Because a reboot is required only two choices to provision-
  # Install the gui with vagrant or install the gui with ansible installed on the host.  
  # This creates potentiall issues because ideally, Ansible should be used within the vm only to limit ansible version issues if the user updates vagrant on their host.
  config.vm.provision "shell", inline: "sudo apt-get install -y ubuntu-desktop virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 xserver-xorg-legacy"
  # Permit anyone to start the GUI
  config.vm.provision "shell", inline: "sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' /etc/X11/Xwrapper.config"
  #disable the update notifier.  We do not want to update to ubuntu 18, currently deadline installer gui doesn't work in 18.
  config.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
  # install ansible
  config.vm.provision "shell", inline: "sudo apt-get install -y software-properties-common"
  config.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
  config.vm.provision "shell", inline: "sudo apt-get install -y ansible"
  # we define the location of the ansible hosts file in an environment variable.
  config.vm.provision "shell", inline: "grep -qxF 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' /etc/environment || echo 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' | sudo tee -a /etc/environment"
  #reboot required for desktop to function.
  config.vm.provision "shell", inline: "sudo reboot"
  # trigger reload
  config.vm.provision :reload
  
  #ansible provissioning
  #ansible_inventory_dir = "ansible/hosts"
  # config.vm.provision "playbook1", type:'ansible_local' do |ansible|
  #   ansible.playbook = "ansible/init.yaml"
  # end
  config.trigger.after :up do |trigger|
    trigger.warn = "Taking Snapshot"
    trigger.run = {inline: "vagrant snapshot push"}
  end

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