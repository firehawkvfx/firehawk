# ensure the version of virutal box installed matches all dependencies - VirtualBox 6.0.14:
# further notes on plugin versions at the end of this script

bridgenic = ENV['TF_VAR_bridgenic']
envtier = ENV['TF_VAR_envtier']
network = ENV['TF_VAR_network']
selected_ansible_version = ENV['TF_VAR_selected_ansible_version']
syscontrol_gid=ENV['TF_VAR_syscontrol_gid']
deployuser_uid=ENV['TF_VAR_deployuser_uid']
disk = '65536MB'

servers=[
  {
    :hostname => "ansiblecontrol",
    :mac_string => ENV['TF_VAR_ansible_mac'],
    :ip => "auto",
    :bridgenic => bridgenic,
    :promisc => false,
    :box => "bento/ubuntu-16.04",
    :ram => 1024,
    :cpu => 2,
    :primary => true
  },
  {
    :hostname => "firehawkgateway",
    :mac_string => ENV['TF_VAR_gateway_mac'],
    :ip => ENV['TF_VAR_openfirehawkserver'],
    :bridgenic => bridgenic,
    :promisc => true,
    :box => "bento/ubuntu-16.04",
    :ram => 8192,
    :cpu => 4,
    :primary => false
  }
]

Vagrant.configure(2) do |config|
    config.vbguest.iso_path = "https://download.virtualbox.org/virtualbox/6.0.14/VBoxGuestAdditions_6.0.14.iso"
    config.vbguest.auto_update = false
    
    servers.each do |machine|
        config.vm.define machine[:hostname], primary: machine[:primary] do |node|
        # config.vm.define machine[:hostname] do |node|
            node.vm.box = machine[:box]
            node.vm.hostname = machine[:hostname]+envtier
            node.vm.box_version = "201912.03.0"
            node.vm.provision "shell", inline: "sudo groupadd -g #{syscontrol_gid} syscontrol"
            node.vm.provision "shell", inline: "sudo usermod -aG syscontrol vagrant"
            node.vm.provision "shell", inline: "sudo useradd -m -s /bin/bash -U deployuser -u #{deployuser_uid}"
            node.vm.provision "shell", inline: "sudo usermod -aG syscontrol deployuser"
            node.vm.provision "shell", inline: "sudo usermod -aG sudo deployuser"
            # give deploy user passwordless sudo as with vagrant user.
            node.vm.provision "shell", inline: "touch /etc/sudoers.d/98_deployuser; grep -qxF 'deployuser ALL=(ALL) NOPASSWD:ALL' /etc/sudoers.d/98_deployuser || echo 'deployuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/98_deployuser"
            # allow ssh access as deploy user
            # node.vm.provision "shell", inline: "mkdir -p /home/deployuser/.ssh; chown -R deployuser:deployuser /home/deployuser/.ssh; chmod 700 /home/deployuser/.ssh"
            node.vm.provision "shell", inline: "cp -fr /home/vagrant/.ssh /home/deployuser/; chown -R deployuser:deployuser /home/deployuser/.ssh; chown deployuser:deployuser /home/deployuser/.ssh/authorized_keys"
            # Allow deployuser to have passwordless sudo
            node.vm.synced_folder ".", "/vagrant", create: true, owner: "vagrant", group: "vagrant"
            node.vm.synced_folder ".", "/deployuser", owner: deployuser_uid, group: deployuser_uid, mount_options: ["uid=#{deployuser_uid}", "gid=#{deployuser_uid}"]
            node.vm.synced_folder "../secrets", "/secrets", create: true, owner: "deployuser", group: "deployuser", mount_options: ["uid=#{deployuser_uid}", "gid=#{deployuser_uid}"]
            node.vm.define machine[:hostname]+envtier
            node.vagrant.plugins = ['vagrant-disksize', 'vagrant-reload']
            node.disksize.size = disk
            mac_string = machine[:mac_string]
            if network == 'public'
                # if you don't know the exact string for the bridgenic, eg '1) en0: Wi-Fi (AirPort)' then leave it as 'none'
                if bridgenic == 'none'
                    if mac_string == 'none'
                        node.vm.network "public_network", use_dhcp_assigned_default_route: true
                    else
                        node.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true
                    end
                else
                    if mac_string == 'none'
                        node.vm.network "public_network", use_dhcp_assigned_default_route: true, bridge: bridgenic
                    else
                        node.vm.network "public_network", mac: mac_string, use_dhcp_assigned_default_route: true, bridge: bridgenic
                    end
                end
            else
                # use a private network mode if you don't have control over the network environment - eg wifi in a cafe / other location.
                if mac_string == 'none'
                    node.vm.network "private_network", use_dhcp_assigned_default_route: true
                else
                    node.vm.network "private_network", ip: machine[:ip], mac: mac_string, use_dhcp_assigned_default_route: true
                end
            end
            
            node.vm.provider "virtualbox" do |vb|
                vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
                # Display the VirtualBox GUI when booting the machine
                vb.gui = false
                # Promisc mode is needed for open vpn gateway to forward packets
                if machine[:promisc] == true
                    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
                    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
                end
                # Customize the amount of memory on the VM:
                vb.customize ["modifyvm", :id, "--memory", machine[:ram]]
                vb.customize ["modifyvm", :id, "--cpus", machine[:cpu]]
            end

            node.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; sudo apt-get update"
            node.vm.provision "shell", inline: "echo 'source /vagrant/scripts/env.sh' > /etc/profile.d/sa-environment.sh", :run => 'always'
            node.vm.provision "shell", inline: "echo DEBIAN_FRONTEND=$DEBIAN_FRONTEND"
            node.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive"
            node.vm.provision "shell", inline: "sudo rm /etc/localtime && sudo ln -s #{ENV['TF_VAR_timezone_localpath']} /etc/localtime", run: "always"
            node.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; sudo apt-get install -y sshpass"
            ### Install Ansible Block ###
            node.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; sudo apt-get install -y software-properties-common"
            if machine[:hostname] == "ansiblecontrol"
                if selected_ansible_version == 'latest'
                    node.vm.provision "shell", inline: "echo 'installing latest version of ansible with apt-get'"
                    node.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible-2.9"
                    node.vm.provision "shell", inline: "sudo apt-get install -y ansible"
                else
                    # Installing a specific version of ansible with pip creates dependency issues pip potentially.
                    node.vm.provision "shell", inline: "sudo apt-get install -y python-pip"
                    node.vm.provision "shell", inline: "pip install --upgrade pip"    
                    # to list available versions - pip install ansible==
                    node.vm.provision "shell", inline: "sudo -H pip install ansible==#{ansible_version}"
                end
            end
            # configure a connection timeout to prevent ansible from getting stuck when there is an ssh issue.
            node.vm.provision "shell", inline: "echo 'ConnectTimeout 60' >> /etc/ssh/ssh_config"
          
            # we define the location of the ansible hosts file in an environment variable.
            node.vm.provision "shell", inline: "grep -qxF 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' /etc/environment || echo 'ANSIBLE_INVENTORY=/vagrant/ansible/hosts' | sudo tee -a /etc/environment"
            # disable the update notifier.  We do not want to update to ubuntu 18, deadline installer doesn't work in 18 when last tested.
            node.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
            # for dpkg or virtualbox issues, see https://superuser.com/questions/298367/how-to-fix-virtualbox-startup-error-vboxadd-service-failed
            # disable password authentication - ssh key only.
            node.vm.provision "shell", inline: <<-EOC
                sudo sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
                sudo service ssh restart
            EOC
            node.vm.provision "shell", inline: "sudo reboot"
            # trigger reload
            node.vm.provision :reload
            node.trigger.after :up do |trigger|
                trigger.warn = "Taking Snapshot"
                trigger.run = {inline: "vagrant snapshot push"}
            end
            node.vm.provision "shell", inline: "sudo reboot"
            node.vm.provision :reload
            node.vm.post_up_message = "You must install this plugin to set the disk size: vagrant plugin install vagrant-disksize\nEnsure you have installed the vbguest plugin with: vagrant plugin update; vagrant plugin install vagrant-vbguest; vagrant vbguest; vagrant vbguest --status"

            node.trigger.before :destroy, :halt, :reload do |trigger|
                trigger.info = "Stopping node..."
                trigger.run = {inline: "echo 'stopping node'"}
              end
          
        end
    end
    VAGRANT_COMMAND = ARGV[0]
    if VAGRANT_COMMAND == "ssh"
        config.ssh.username = 'deployuser'
        config.ssh.extra_args = ["-t", "cd /deployuser; bash --login"]
    end
end