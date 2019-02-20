# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
# Vagrant.configure("2") do |config|
#   # The most common configuration options are documented and commented below.
#   # For a complete reference, please see the online documentation at
#   # https://docs.vagrantup.com.

#   config.vm.box = "ubuntu/xenial64"
#   config.vm.provision :shell, path: "bootstrap.sh"
#   #config.vm.network :forwarded_port, guest: 80, host: 4567
#   config.vm.network "public_network"
#   config.vm.provider "virtualbox" do |vb|
#     # Display the VirtualBox GUI when booting the machine
#     vb.gui = true
  
#     # Customize the amount of memory on the VM:
#     vb.memory = "8192"
#     vb.cpus = 4
#   end
# end


Vagrant.configure("2") do |config|
  # Ubuntu 15.10
  config.vm.box = "ubuntu/xenial64"
  #config.vm.provision :shell, path: "bootstrap.sh"
  #config.vm.network :forwarded_port, guest: 80, host: 4567
  config.vm.network "public_network"
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
    # Customize the amount of memory on the VM:
    vb.memory = "8192"
    vb.cpus = 4
    vb.customize ["modifyvm", :id, "--accelerate2dvideo", "on"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
  end
  #can use this to encrypt shell input $(openssl passwd -1 password)
  #redhat - to change pass sudo useradd -p $(openssl passwd -1 password) username
  config.vm.provision "shell", inline: "sudo adduser --disabled-password --uid 9001 --gecos '' deadlineuser"
  config.vm.provision "shell", inline: "echo 'deadlineuser:DeleteThisPass' | sudo chpasswd"
  config.vm.provision "shell", inline: "echo 'ubuntu:DeleteThisPass' | sudo chpasswd"
  config.vm.provision "shell", inline: "sudo usermod -aG sudo deadlineuser"
  # Install xfce and virtualbox additions
  config.vm.provision "shell", inline: "sudo apt-get update"
  config.vm.provision "shell", inline: "sudo apt-get install -y ubuntu-desktop virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 xserver-xorg-legacy"
  # Permit anyone to start the GUI
  config.vm.provision "shell", inline: "sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' /etc/X11/Xwrapper.config"
  #disable the update notifier.  We do not want to update to ubuntu 18, currently deadline installer gui doesn't work in 18.
  config.vm.provision "shell", inline: "sudo sed -i 's/Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades"
  # install ansible
  config.vm.provision "shell", inline: "sudo apt-get install -y software-properties-common"
  config.vm.provision "shell", inline: "sudo apt-add-repository --yes --update ppa:ansible/ansible"
  config.vm.provision "shell", inline: "sudo apt-get install -y ansible"
  #reboot required for desktop to function.
  config.vm.provision "shell", inline: "sudo reboot"
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
  end
  
  #to check display manager run: 
  #cat /etc/X11/default-display-manager
  # to install terraform https://linuxacademy.com/community/posts/show/topic/18181-can-somebody-explain-how-to-install-terraform
#   sudo yum install -y zip unzip (if these are not installed)
#   wget https://releases.hashicorp.com/terraform/0.9.8/terraform_0.9.8_linux_amd64.zip
#   unzip terraform_0.9.8_linux_amd64.zip
#   sudo mv terraform /usr/local/bin/
#   Confirm terraform binary is accessible: terraform --version
end