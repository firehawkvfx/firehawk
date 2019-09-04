# you must install this plugin to set the disk size:
# vagrant plugin install vagrant-disksize

Vagrant.configure("2") do |config|
  # Ubuntu 16.04
  # ensure you have install the vbguest plugin with
  # vagrant plugin install vagrant-vbguest
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_version = "201906.18.0"

  config.vm.synced_folder "../secrets", "/secrets", create: true

  mac_string = ENV['TF_VAR_vagrant_mac']
  vaultkeypresent = ENV['TF_VAR_vaultkeypresent']
  bridgenic = ENV['TF_VAR_bridgenic']
  envtier = ENV['TF_VAR_envtier']
  name = ENV['TF_VAR_openfirehawkserver_name']
  openfirehawkserver = ENV['TF_VAR_openfirehawkserver']
  network = ENV['TF_VAR_network']

  config.vm.define "ansible_control_"+envtier
  config.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
  config.disksize.size = '65536MB'

  if network == 'public'
      # if you don't know the exact string for the bridgenic, eg '1) en0: Wi-Fi (AirPort)' then leave it as 'none'
      if bridgenic == 'none'
          #config.vm.network "public_network", ip: openfirehawkserver, mac: mac_string, use_dhcp_assigned_default_route: true
          config.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true
        else
          #config.vm.network "public_network", ip: openfirehawkserver, mac: mac_string, use_dhcp_assigned_default_route: true, bridge: bridgenic
          config.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true, bridge: bridgenic
        end
    else
      # use a private network mode if you don't have control over the network environment - eg wifi in a cafe / other location.
      config.vm.network "private_network", ip: openfirehawkserver, mac: mac_string, use_dhcp_assigned_default_route: true
    end
  
  # routing issues?  https://stackoverflow.com/questions/35208188/how-can-i-define-network-settings-with-vagrant
  config.vm.provider "virtualbox" do |vb|
    # fix time sync threshold to 10 seconds.  otherwise sleep on the host can cause time offset on wake.
    vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
    # Customize the amount of memory on the VM:
    vb.memory = ENV['TF_VAR_openfirehawkserver_ram']
    vb.cpus = ENV['TF_VAR_openfirehawkserver_vcpus']
    vb.customize ["modifyvm", :id, "--accelerate2dvideo", "on"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
    #enable promiscuous mode to enable routes from aws through the openfirehawkserver vpn into your local network
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
  end
  config.vm.provision "shell", inline: "echo 'source /vagrant/scripts/env.sh' > /etc/profile.d/sa-environment.sh", :run => 'always'
  config.vm.provision "shell", inline: "echo DEBIAN_FRONTEND=$DEBIAN_FRONTEND"

  config.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive"
  config.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/Australia/Brisbane /etc/localtime", run: "always"
  config.vm.provision "shell", inline: "sudo apt-get update"
  # temp disable as we are getting freezing with ssh issues
  config.vm.provision "shell", inline: "sudo apt-get install -y sshpass"

  ### Install Ansible Block ###
  config.vm.provision "shell", inline: "sudo apt-get install -y software-properties-common"
  #config.vm.provision "shell", inline: "pip install --upgrade pip"
  #config.vm.provision "shell", inline: "sudo apt-get install -y python-pip python-dev"
  #pip install --upgrade pip
  #config.vm.provision "shell", inline: "sudo -H pip install ansible==2.7.11"
  # to list available versions - pip install ansible==
  config.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
  config.vm.provision "shell", inline: "sudo apt-get install -y ansible"

  # we define the location of the ansible hosts file in an environment variable.
  config.vm.provision "shell", inline: "grep -qxF 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' /etc/environment || echo 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' | sudo tee -a /etc/environment"
  
  # these utils are likely require dfor promisc mode on ethernet which is required if routing on a local network.
  config.vm.provision "shell", inline: "sudo apt-get install -y virtualbox-guest-dkms"
  config.vm.provision "shell", inline: "sudo apt-get install -y virtualbox-guest-utils"

  #reboot required for desktop to function.

  # ### Install ubuntu desktop and virtualbox additions.  Because a reboot is required, provisioning is handled here. ###
  # # # Install the gui with vagrant or install the gui with ansible installed on the host.  
  # # # This creates potentiall issues because ideally, Ansible should be used within the vm only to limit ansible version issues if the user updates vagrant on their host.
  # config.vm.provision "shell", inline: "sudo apt-get install -y ubuntu-desktop"
  # # ...or xfce.  pick one.
  # #config.vm.provision "shell", inline: "sudo apt-get install -y curl xfce4"
  # config.vm.provision "shell", inline: "sudo apt-get install -y virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 xserver-xorg-legacy"
  # # Permit anyone to start the GUI
  # config.vm.provision "shell", inline: "sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' /etc/X11/Xwrapper.config"
  # ## End Ubuntu Desktop block ###

  # #disable the update notifier.  We do not want to update to ubuntu 18, currently deadline installer gui doesn't work in 18.
  config.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
  

  # for dpkg or virtualbox issues, see https://superuser.com/questions/298367/how-to-fix-virtualbox-startup-error-vboxadd-service-failed

  config.vm.provision "shell", inline: "sudo reboot"
  # trigger reload
  config.vm.provision :reload
  config.trigger.after :up do |trigger|
    trigger.warn = "Taking Snapshot"
    trigger.run = {inline: "vagrant snapshot push"}
  end

  config.vm.provision "shell", inline: "sudo reboot"
  config.vm.provision :reload

  # # default router
  # config.vm.provision "shell",
  #   run: "always",
  #   inline: "route add default gw 192.168.92.1"
  
end