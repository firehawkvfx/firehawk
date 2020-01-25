# You must install this plugin to set the disk size:
# vagrant plugin install vagrant-disksize
# Ensure you have installed the vbguest plugin with:
# vagrant plugin install vagrant-vbguest

Vagrant.configure("2") do |config|
  mac_string = ENV['TF_VAR_vagrant_mac']
  bridgenic = ENV['TF_VAR_bridgenic']
  envtier = ENV['TF_VAR_envtier']=
  openfirehawkserver = ENV['TF_VAR_openfirehawkserver']
  network = ENV['TF_VAR_network']
  selected_ansible_version = ENV['TF_VAR_selected_ansible_version']

  ### ANSIBLE CONTROL / SECRETS MANAGEMENT ###
  config.vm.define "control", primary: true do |control|
    # Ubuntu 16.04
    control.vm.box = "bento/ubuntu-16.04"
    control.vm.box_version = "201906.18.0"
    control.vm.synced_folder "../secrets", "/secrets", create: true
    control.vm.define "ansible_control_"+envtier
    control.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
    control.disksize.size = '65536MB'
    if network == 'public'
      # if you don't know the exact string for the bridgenic, eg '1) en0: Wi-Fi (AirPort)' then leave it as 'none'
      if bridgenic == 'none'
          control.vm.network "public_network", use_dhcp_assigned_default_route: true
        else
          control.vm.network "public_network", use_dhcp_assigned_default_route: true, bridge: bridgenic
        end
    else
      # use a private network mode if you don't have control over the network environment - eg wifi in a cafe / other location.
      control.vm.network "private_network", use_dhcp_assigned_default_route: true
    end
    control.vm.provider "virtualbox" do |vb|
      # fix time sync threshold to 10 seconds.  otherwise sleep on the host can cause time offset on wake.
      vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
      # Display the VirtualBox GUI when booting the machine
      vb.gui = false
      # Customize the amount of memory on the VM:
      vb.memory = 1024
      vb.cpus = 1
    end
    control.vm.provision "shell", inline: "echo 'source /vagrant/scripts/env.sh' > /etc/profile.d/sa-environment.sh", :run => 'always'
    control.vm.provision "shell", inline: "echo DEBIAN_FRONTEND=$DEBIAN_FRONTEND"
    control.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive"
    control.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s #{ENV['TF_VAR_timezone_localpath']} /etc/localtime", run: "always"
    control.vm.provision "shell", inline: "sudo apt-get update"
    # temp disable as we are getting freezing with ssh issues
    control.vm.provision "shell", inline: "sudo apt-get install -y sshpass"
    ### Install Ansible Block ###
    control.vm.provision "shell", inline: "sudo apt-get install -y software-properties-common"
    if selected_ansible_version == 'latest'
      control.vm.provision "shell", inline: "echo 'installing latest version of ansible with apt-get'"
      control.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
      control.vm.provision "shell", inline: "sudo apt-get install -y ansible"
    else
      # Installing a specific version of ansible with pip creates dependency issues pip potentially.
      control.vm.provision "shell", inline: "sudo apt-get install -y python-pip"
      control.vm.provision "shell", inline: "pip install --upgrade pip"    
      # to list available versions - pip install ansible==
      control.vm.provision "shell", inline: "sudo -H pip install ansible==#{ansible_version}"
    end
    # configure a connection timeout to prevent ansible from getting stuck when there is an ssh issue.
    control.vm.provision "shell", inline: "echo 'ConnectTimeout 60' >> /etc/ssh/ssh_config"
    # we define the location of the ansible hosts file in an environment variable.
    control.vm.provision "shell", inline: "grep -qxF 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' /etc/environment || echo 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' | sudo tee -a /etc/environment"
    # disable the update notifier.  We do not want to update to ubuntu 18, deadline installer doesn't work in 18 when last tested.
    control.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
    # for dpkg or virtualbox issues, see https://superuser.com/questions/298367/how-to-fix-virtualbox-startup-error-vboxadd-service-failed
    # disable password authentication - ssh key only.
    control.vm.provision "shell", inline: <<-EOC
      sudo sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
      sudo service ssh restart
    EOC
    control.vm.provision "shell", inline: "sudo reboot"
    # trigger reload
    control.vm.provision :reload
    control.trigger.after :up do |trigger|
      trigger.warn = "Taking Snapshot"
      trigger.run = {inline: "vagrant snapshot push"}
    end
    control.vm.provision "shell", inline: "sudo reboot"
    control.vm.provision :reload  
  end

  ### GATEWAY / VPN / DEADLINE DB / LICENSE SERVER ###
  config.vm.define "gateway" do |gateway|
    gateway.vm.box = "bento/ubuntu-16.04"
    gateway.vm.box_version = "201906.18.0"
    gateway.vm.synced_folder "../secrets", "/secrets", create: true
    gateway.vm.define "gateway_"+envtier
    gateway.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
    gateway.disksize.size = '65536MB'
    if network == 'public'
      # if you don't know the exact string for the bridgenic, eg '1) en0: Wi-Fi (AirPort)' then leave it as 'none'
      if bridgenic == 'none'
          gateway.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true
        else
          gateway.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true, bridge: bridgenic
        end
    else
      # use a private network mode if you don't have control over the network environment - eg wifi in a cafe / other location.
      gateway.vm.network "private_network", ip: openfirehawkserver, mac: mac_string, use_dhcp_assigned_default_route: true
    end
    # routing issues?  https://stackoverflow.com/questions/35208188/how-can-i-define-network-settings-with-vagrant
    gateway.vm.provider "virtualbox" do |vb|
      # fix time sync threshold to 10 seconds.  otherwise sleep on the host can cause time offset on wake.
      vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
      # Display the VirtualBox GUI when booting the machine
      vb.gui = false
      # Customize the amount of memory on the VM:
      vb.memory = ENV['TF_VAR_openfirehawkserver_ram']
      vb.cpus = ENV['TF_VAR_openfirehawkserver_vcpus']
      #enable promiscuous mode to enable routes from aws through the openfirehawkserver vpn into your local network
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
    end
    gateway.vm.provision "shell", inline: "echo 'source /vagrant/scripts/env.sh' > /etc/profile.d/sa-environment.sh", :run => 'always'
    gateway.vm.provision "shell", inline: "echo DEBIAN_FRONTEND=$DEBIAN_FRONTEND"
    gateway.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive"
    gateway.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s #{ENV['TF_VAR_timezone_localpath']} /etc/localtime", run: "always"
    gateway.vm.provision "shell", inline: "sudo apt-get update"
    # configure a connection timeout to prevent ansible from getting stuck when there is an ssh issue.
    gateway.vm.provision "shell", inline: "echo 'ConnectTimeout 60' >> /etc/ssh/ssh_config"
    # these utils are likely require dfor promisc mode on ethernet which is required if routing on a local network.
    gateway.vm.provision "shell", inline: "sudo apt-get install -y virtualbox-guest-dkms"
    gateway.vm.provision "shell", inline: "sudo apt-get install -y virtualbox-guest-utils"
    # disable the update notifier.  We do not want to update to ubuntu 18, deadline installer doesn't work in 18 when last tested.
    gateway.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
    # for dpkg or virtualbox issues, see https://superuser.com/questions/298367/how-to-fix-virtualbox-startup-error-vboxadd-service-failed
    # disable password authentication - ssh key only.
    gateway.vm.provision "shell", inline: <<-EOC
      sudo sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
      sudo service ssh restart
    EOC
    gateway.vm.provision "shell", inline: "sudo reboot"
    # trigger reload
    gateway.vm.provision :reload
    gateway.trigger.after :up do |trigger|
      trigger.warn = "Taking Snapshot"
      trigger.run = {inline: "vagrant snapshot push"}
    end
    gateway.vm.provision "shell", inline: "sudo reboot"
    gateway.vm.provision :reload  
  end
end