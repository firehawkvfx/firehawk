# openFirehawk
Written by Andrew Graham

=== This is in developement - not ready for production. ===

The initial goals of this project are to setup an AWS VPC, Storage, a VPN, connect License Servers, and batch workloads for SideFX Houdini.  It also serves as a foundation for other linux 3D rendering software.

Contribution to extend functionality is welcome.  Please contact me if you wish to contribute in a particular area so that we can collaborate efficiently.  Planned changes in implementation could affect what is currently in the major branch that at this stage is good to be aware of:

Storage and Node configuration with Ansible is intended, but not currently in place. Onsite VM configuration with Vagrant and Ansible is also intended but not yet in place.


The goals of this project are to setup an AWS VPC, Storage, a VPN, connection with License Servers (onsite), and batch workloads for SideFX Houdini

Currently this is being developed in and launched from an Ubuntu 16.04.5 vm in vmware workstation, running in a RHEL 7.5 host.
Eventually this could be replaced with docker for virtualisation.

The Ubuntu 16.04 VM requires the following default components-
50GB mounted volume size.
4 cores.
16GB RAM.

Set a host name like-
deadlinedb.example.com

Assign a static ip address from your router to the bridge vm ethernet adaptor.  This address will be used for security groups.

A new user with UID 9001 and Gid 9001 named:
deadlineuser : deadlineuser
in ubuntu use adduser (not useradd)

This user should exist in the vm, and on your workstation.  we will always log in as this user from now on to simplify permissions issues.  onces everything is working you can implement groups with other users.

Packages:  
apt-get install openvpn
apt-get install lsb
apt-get install libx11-6
apt-get install libxext-6
apt-get install libgl1-mesa-6

note: the last two weren't available per the thinkbox docs.  using these instead
apt-get install libxext6
apt-get install libgl1-mesa-dev

Installed software and package notes:
AWS CLI with your access credentials  
Terraform 0.11.11  
Installations of Deadline 10 repository, database, and RCS

in ubuntu vm on site:
For launcher setup (during client setup), dont tick any boxes to launch the slave when launcher starts, or to install it as a daemon- This vm wont be used as a render node.

Deadline RCS on port 8080
Deadline TLS HTTPS 4433

Mongo DB on port
27100

install generated certificates in a safe location accessible with root only permissions.

deadline cert will need to have read access for deadline user.
/opt/Thinkbox/DeadlineDatabase10/certs/Deadline10Client.pfx


AWS Parameters will need some manual configuration and approving subscriptions.
Start by creating a new m4xlarge instance
with the ami, select - softnas, consumption based platinum for low compute requirements.  you can switch to medium or high to test as well.
aggree to the subscription and once the instance starts, get the ami id and insert it into the terraform variables to launch.

in the tf_aws_open vpn module be sure to follow the instructions on its reuired permissions.
this will enable storing vpn files for the auto login feature to work.

### client side openvpn (tested in ubuntu 16.04.05) ###

before running anything, ensure you follow the instructions of this file and that it is executable without having to enter a password.
modules/tf_aws_openvpn/startvpn.sh

the steps if followed correctly should allowed the script to be executed as the user without entering a password.  if you can't get it to work, test each line and identify if you have made an error in your visudo file.

### client side deadline config (tested in ubuntu 16.04.05) ###

Generally the client side ubuntu vm will have these components running so you should start each component in a terminal to observe logs or run them as services

-inside the git repository, running 'terraform apply' will create all infrastructure and ensure it is running.  (it can be put to sleep with 'terraform apply -var sleep=true --auto-approve').  if you happen to commit any changes, it is your responsibility to make sure that any private information is excluded from those commits.  private information should be stored with vault, or in the private-variables.tf file you need to customise.

-'service openvpn restart' - will connect to the remote vpn.  ensure you can ping instances in the private subnet.
-run deadline rcs.  The Remote connection server is the process that render nodes will connect to the Deadline DB with
-run deadline monitor to observe processes and configure your Usage Based Licencing, and spot fleet JSON settings.
-run deadline pulse.  Deadline will use the json definition you provide in the event plugin named spot to spin up spot instances.

Before submission, ensure the single render node is visible to the monitor.  create an Amazon Machine Image (AMI) of that instance, and ensure this AMI ID is in your JSON spot definition.

## client side workstation

Your workstation will probably want the deadline client installed.  You can install it with the same method used to install on the render node.  an example below-

su - deadlineuser
sudo ./DeadlineClient-10.0.23.4-linux-x64-installer.run --mode unattended --debuglevel 2 --prefix /opt/Thinkbox/Deadline10 --connectiontype Remote --noguimode true --licensemode UsageBased --launcherdaemon true --slavestartup 1 --daemonuser deadlineuser --enabletls true --tlsport 4433 --httpport 8080 --proxyrootdir 192.168.96.4:4433 --proxycertificate /opt/Thinkbox/certs/Deadline10RemoteClient.pfx --proxycertificatepassword SomePassword

Ensure you have read + write permissions for the user and group on the proxy certificate.

after this you can run the deadline client.
cd /opt/Thinkbox/Deadline10
./deadlinemonitor

You can install the houdini deadline submission rop with these instructions-
https://docs.thinkboxsoftware.com/products/deadline/10.0/1_User%20Manual/manual/app-houdini.html

The installer is found in the deadilne repository.  this smb share should have been setup already when you configured the deadline repository, so you can mount it to your workstation temporarily
sudo mount -t cifs -o username=deadlineuser,password=<password> //<samba_server_address>/DeadlineRepository /mnt/repo

if the automatic installer doesn't work, follow the manual instructions.
