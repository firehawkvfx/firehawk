# ensure the version of virutal box installed matches all dependencies - VirtualBox 6.0.14:
# further notes on plugin versions at the end of this script

def shared_config(host, memory = 1024, cpus = 1, mac_string = 'none', disk = '65536MB', promisc = false)
  bridgenic = ENV['TF_VAR_bridgenic']
  envtier = ENV['TF_VAR_envtier']
  openfirehawkserver = ENV['TF_VAR_openfirehawkserver']
  network = ENV['TF_VAR_network']
  selected_ansible_version = ENV['TF_VAR_selected_ansible_version']
  syscontrol_gid=ENV['TF_VAR_syscontrol_gid']

  host.vm.box = "bento/ubuntu-16.04"
  host.vm.box_version = "201912.03.0"
  host.vm.provision "shell", inline: "sudo groupadd -g #{syscontrol_gid} syscontrol"
  host.vm.provision "shell", inline: "sudo usermod -aG syscontrol vagrant"
  host.vm.synced_folder "../secrets", "/secrets", create: true, owner: "vagrant", group: syscontrol_gid
  host.vm.define "host_"+envtier
  host.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
  host.disksize.size = disk
  if network == 'public'
      # if you don't know the exact string for the bridgenic, eg '1) en0: Wi-Fi (AirPort)' then leave it as 'none'
      if bridgenic == 'none'
          if mac_string == 'none'
              host.vm.network "public_network", use_dhcp_assigned_default_route: true
          else
              host.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true
          end
      else
          if mac_string == 'none'
              host.vm.network "public_network", use_dhcp_assigned_default_route: true, bridge: bridgenic
          else
              host.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true, bridge: bridgenic
          end
      end
  else
      # use a private network mode if you don't have control over the network environment - eg wifi in a cafe / other location.
      if mac_string == 'none'
          host.vm.network "private_network", use_dhcp_assigned_default_route: true
      else
          host.vm.network "private_network", ip: openfirehawkserver, mac: mac_string, use_dhcp_assigned_default_route: true
      end
  end
  host.vm.provider "virtualbox" do |vb|
      # fix time sync threshold to 10 seconds.  otherwise sleep on the host can cause time offset on wake.
      vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
      # Display the VirtualBox GUI when booting the machine
      vb.gui = false
      # Customize the amount of memory on the VM:
      vb.memory = memory
      vb.cpus = cpus
      if promisc == true
          vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
          vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
      end
  end
  # host.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; sudo apt-get update"
  # host.vm.provision "shell", inline: "echo 'source /vagrant/scripts/env.sh' > /etc/profile.d/sa-environment.sh", :run => 'always'
  # host.vm.provision "shell", inline: "echo DEBIAN_FRONTEND=$DEBIAN_FRONTEND"
  # host.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive"
  # host.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s #{ENV['TF_VAR_timezone_localpath']} /etc/localtime", run: "always"
  # host.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; sudo apt-get install -y sshpass"
  # ### Install Ansible Block ###
  # host.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; sudo apt-get install -y software-properties-common"
  # if selected_ansible_version == 'latest'
  #     host.vm.provision "shell", inline: "echo 'installing latest version of ansible with apt-get'"
  #     host.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
  #     host.vm.provision "shell", inline: "sudo apt-get install -y ansible"
  # else
  #     # Installing a specific version of ansible with pip creates dependency issues pip potentially.
  #     host.vm.provision "shell", inline: "sudo apt-get install -y python-pip"
  #     host.vm.provision "shell", inline: "pip install --upgrade pip"    
  #     # to list available versions - pip install ansible==
  #     host.vm.provision "shell", inline: "sudo -H pip install ansible==#{ansible_version}"
  # end
  # # configure a connection timeout to prevent ansible from getting stuck when there is an ssh issue.
  # host.vm.provision "shell", inline: "echo 'ConnectTimeout 60' >> /etc/ssh/ssh_config"

  # # we define the location of the ansible hosts file in an environment variable.
  # host.vm.provision "shell", inline: "grep -qxF 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' /etc/environment || echo 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' | sudo tee -a /etc/environment"
  # # disable the update notifier.  We do not want to update to ubuntu 18, deadline installer doesn't work in 18 when last tested.
  # host.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
  # # for dpkg or virtualbox issues, see https://superuser.com/questions/298367/how-to-fix-virtualbox-startup-error-vboxadd-service-failed
  # # disable password authentication - ssh key only.
  # host.vm.provision "shell", inline: <<-EOC
  #     sudo sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  #     sudo service ssh restart
  # EOC
  # host.vm.provision "shell", inline: "sudo reboot"
  # # trigger reload
  # host.vm.provision :reload
  # host.trigger.after :up do |trigger|
  #     trigger.warn = "Taking Snapshot"
  #     trigger.run = {inline: "vagrant snapshot push"}
  # end
  # host.vm.provision "shell", inline: "sudo reboot"
  # host.vm.provision :reload
  # host.vm.post_up_message = "You must install this plugin to set the disk size: vagrant plugin install vagrant-disksize\nEnsure you have installed the vbguest plugin with: vagrant plugin update; vagrant plugin install vagrant-vbguest; vagrant vbguest; vagrant vbguest --status"
end

Vagrant.configure("2") do |config|
  mac_string = ENV['TF_VAR_vagrant_mac']
  bridgenic = ENV['TF_VAR_bridgenic']
  envtier = ENV['TF_VAR_envtier']
  openfirehawkserver = ENV['TF_VAR_openfirehawkserver']
  network = ENV['TF_VAR_network']
  selected_ansible_version = ENV['TF_VAR_selected_ansible_version']
  syscontrol_gid=ENV['TF_VAR_syscontrol_gid']
  # the guest additions below are matched to virtual box 6.0.16
  config.vbguest.iso_path = "https://download.virtualbox.org/virtualbox/6.0.16/VBoxGuestAdditions_6.0.16.iso"
  config.vbguest.auto_update = false
  # config.vbguest.auto_update = true

  ### ANSIBLE CONTROL / SECRETS MANAGEMENT ###
  config.vm.define "ansiblecontrol", primary: true do |ansiblecontrol|
    shared_config(ansiblecontrol, memory: 1024, cpus: 1, mac_string: 'none', disk: '65536MB', promisc: false)
    # # Ubuntu 16.04
    # ansiblecontrol.vm.box = "bento/ubuntu-16.04"
    # ansiblecontrol.vm.box_version = "201912.03.0"
    # # create syscontrol group and add vagrant user
    # ansiblecontrol.vm.provision "shell", inline: "sudo groupadd -g #{syscontrol_gid} syscontrol"
    # ansiblecontrol.vm.provision "shell", inline: "sudo usermod -aG syscontrol vagrant"
    # ansiblecontrol.vm.synced_folder "../secrets", "/secrets", create: true, owner: "vagrant", group: syscontrol_gid
    # ansiblecontrol.vm.define "ansible_control_"+envtier
    # ansiblecontrol.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
    # if network == 'public'
    #   # if you don't know the exact string for the bridgenic, eg '1) en0: Wi-Fi (AirPort)' then leave it as 'none'
    #   if bridgenic == 'none'
    #       ansiblecontrol.vm.network "public_network", use_dhcp_assigned_default_route: true
    #     else
    #       ansiblecontrol.vm.network "public_network", use_dhcp_assigned_default_route: true, bridge: bridgenic
    #     end
    # else
    #   # use a private network mode if you don't have control over the network environment - eg wifi in a cafe / other location.
    #   ansiblecontrol.vm.network "private_network", use_dhcp_assigned_default_route: true
    # end
    # ansiblecontrol.vm.provider "virtualbox" do |vb|
    #   # fix time sync threshold to 10 seconds.  otherwise sleep on the host can cause time offset on wake.
    #   vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
    #   # Display the VirtualBox GUI when booting the machine
    #   vb.gui = false
    #   # Customize the amount of memory on the VM:
    #   vb.memory = 1024
    #   vb.cpus = 1
    # end
    # ansiblecontrol.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; sudo apt-get update"
    # ansiblecontrol.vm.provision "shell", inline: "echo 'source /vagrant/scripts/env.sh' > /etc/profile.d/sa-environment.sh", :run => 'always'
    # ansiblecontrol.vm.provision "shell", inline: "echo DEBIAN_FRONTEND=$DEBIAN_FRONTEND"
    # ansiblecontrol.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive"
    # ansiblecontrol.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s #{ENV['TF_VAR_timezone_localpath']} /etc/localtime", run: "always"
    # ansiblecontrol.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; sudo apt-get install -y sshpass"
    # ### Install Ansible Block ###
    # ansiblecontrol.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; sudo apt-get install -y software-properties-common"
    # if selected_ansible_version == 'latest'
    #   ansiblecontrol.vm.provision "shell", inline: "echo 'installing latest version of ansible with apt-get'"
    #   ansiblecontrol.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
    #   ansiblecontrol.vm.provision "shell", inline: "sudo apt-get install -y ansible"
    # else
    #   # Installing a specific version of ansible with pip creates dependency issues pip potentially.
    #   ansiblecontrol.vm.provision "shell", inline: "sudo apt-get install -y python-pip"
    #   ansiblecontrol.vm.provision "shell", inline: "pip install --upgrade pip"    
    #   # to list available versions - pip install ansible==
    #   ansiblecontrol.vm.provision "shell", inline: "sudo -H pip install ansible==#{ansible_version}"
    # end
    # # configure a connection timeout to prevent ansible from getting stuck when there is an ssh issue.
    # ansiblecontrol.vm.provision "shell", inline: "echo 'ConnectTimeout 60' >> /etc/ssh/ssh_config"

    # # we define the location of the ansible hosts file in an environment variable.
    # ansiblecontrol.vm.provision "shell", inline: "grep -qxF 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' /etc/environment || echo 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' | sudo tee -a /etc/environment"
    # # disable the update notifier.  We do not want to update to ubuntu 18, deadline installer doesn't work in 18 when last tested.
    # ansiblecontrol.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
    # # for dpkg or virtualbox issues, see https://superuser.com/questions/298367/how-to-fix-virtualbox-startup-error-vboxadd-service-failed
    # # disable password authentication - ssh key only.
    # ansiblecontrol.vm.provision "shell", inline: <<-EOC
    #   sudo sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    #   sudo service ssh restart
    # EOC
    # ansiblecontrol.vm.provision "shell", inline: "sudo reboot"
    # # trigger reload
    # ansiblecontrol.vm.provision :reload
    # ansiblecontrol.trigger.after :up do |trigger|
    #   trigger.warn = "Taking Snapshot"
    #   trigger.run = {inline: "vagrant snapshot push"}
    # end
    # ansiblecontrol.vm.provision "shell", inline: "sudo reboot"
    # ansiblecontrol.vm.provision :reload  
  end

  ### GATEWAY / VPN / DEADLINE DB / LICENSE SERVER ###
  config.vm.define "firehawkgateway" do |firehawkgateway|
    shared_config(firehawkgateway, memory: 1024, cpus: 1, mac_string: 'none', disk: '65536MB', promisc: false)
  #   firehawkgateway.vm.box = "bento/ubuntu-16.04"
  #   firehawkgateway.vm.box_version = "201912.03.0"
  #   firehawkgateway.vm.provision "shell", inline: "sudo groupadd -g #{syscontrol_gid} syscontrol"
  #   firehawkgateway.vm.provision "shell", inline: "sudo usermod -aG syscontrol vagrant"
  #   firehawkgateway.vm.synced_folder "../secrets", "/secrets", create: true, owner: "vagrant", group: syscontrol_gid
  #   firehawkgateway.vm.define "firehawkgateway_"+envtier
  #   firehawkgateway.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
  #   firehawkgateway.disksize.size = '65536MB'
  #   if network == 'public'
  #     # if you don't know the exact string for the bridgenic, eg '1) en0: Wi-Fi (AirPort)' then leave it as 'none'
  #     if bridgenic == 'none'
  #         firehawkgateway.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true
  #       else
  #         firehawkgateway.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true, bridge: bridgenic
  #       end
  #   else
  #     # use a private network mode if you don't have control over the network environment - eg wifi in a cafe / other location.
  #     firehawkgateway.vm.network "private_network", ip: openfirehawkserver, mac: mac_string, use_dhcp_assigned_default_route: true
  #   end
  #   # routing issues?  https://stackoverflow.com/questions/35208188/how-can-i-define-network-settings-with-vagrant
  #   firehawkgateway.vm.provider "virtualbox" do |vb|
  #     # fix time sync threshold to 10 seconds.  otherwise sleep on the host can cause time offset on wake.
  #     vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
  #     # Display the VirtualBox GUI when booting the machine
  #     vb.gui = false
  #     # Customize the amount of memory on the VM:
  #     vb.memory = ENV['TF_VAR_openfirehawkserver_ram']
  #     vb.cpus = ENV['TF_VAR_openfirehawkserver_vcpus']
  #     #enable promiscuous mode to enable routes from aws through the openfirehawkserver vpn into your local network
  #     vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
  #     vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
  #   end
  #   firehawkgateway.vm.provision "shell", inline: "sudo apt-get update"
  #   firehawkgateway.vm.provision "shell", inline: "echo 'source /vagrant/scripts/env.sh' > /etc/profile.d/sa-environment.sh", :run => 'always'
  #   firehawkgateway.vm.provision "shell", inline: "echo DEBIAN_FRONTEND=$DEBIAN_FRONTEND"
  #   firehawkgateway.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive"
  #   firehawkgateway.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s #{ENV['TF_VAR_timezone_localpath']} /etc/localtime", run: "always"
  #   firehawkgateway.vm.provision "shell", inline: "sudo apt-get install -y sshpass"
  #   ### Install Ansible Block ###
  #   firehawkgateway.vm.provision "shell", inline: "sudo apt-get install -y software-properties-common"
  #   if selected_ansible_version == 'latest'
  #     firehawkgateway.vm.provision "shell", inline: "echo 'installing latest version of ansible with apt-get'"
  #     firehawkgateway.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
  #     firehawkgateway.vm.provision "shell", inline: "sudo apt-get install -y ansible"
  #   else
  #     # Installing a specific version of ansible with pip creates dependency issues pip potentially.
  #     firehawkgateway.vm.provision "shell", inline: "sudo apt-get install -y python-pip"
  #     firehawkgateway.vm.provision "shell", inline: "pip install --upgrade pip"    
  #     # to list available versions - pip install ansible==
  #     firehawkgateway.vm.provision "shell", inline: "sudo -H pip install ansible==#{ansible_version}"
  #   end
  #   # configure a connection timeout to prevent ansible from getting stuck when there is an ssh issue.
  #   firehawkgateway.vm.provision "shell", inline: "echo 'ConnectTimeout 60' >> /etc/ssh/ssh_config"
  #   # these utils are likely require dfor promisc mode on ethernet which is required if routing on a local network.
  
  #   # disable the update notifier.  We do not want to update to ubuntu 18, deadline installer doesn't work in 18 when last tested.
  #   firehawkgateway.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
  #   # for dpkg or virtualbox issues, see https://superuser.com/questions/298367/how-to-fix-virtualbox-startup-error-vboxadd-service-failed
  #   # disable password authentication - ssh key only.
  #   firehawkgateway.vm.provision "shell", inline: <<-EOC
  #     sudo sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  #     sudo service ssh restart
  #   EOC
  #   firehawkgateway.vm.provision "shell", inline: "sudo reboot"
  #   # trigger reload
  #   firehawkgateway.vm.provision :reload
  #   firehawkgateway.trigger.after :up do |trigger|
  #     trigger.warn = "Taking Snapshot"
  #     trigger.run = {inline: "vagrant snapshot push"}
  #   end
  #   firehawkgateway.vm.provision "shell", inline: "sudo reboot"
  #   firehawkgateway.vm.provision :reload
  #   firehawkgateway.vm.post_up_message = "You must install this plugin to set the disk size: vagrant plugin install vagrant-disksize\nEnsure you have installed the vbguest plugin with: vagrant plugin update; vagrant plugin install vagrant-vbguest; vagrant vbguest; vagrant vbguest --status"
  end
end