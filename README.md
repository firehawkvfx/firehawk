# firehawk-compute-batch
This is in developement - Unstable

The goals of this project are to setup an AWS VPC, Storage, a VPN, connection with License Servers (onsite), and batch workloads for SideFX Houdini

Currently this is being developed in and launched from an Ubuntu 16.04.5 vm in vmware workstation, running in a RHEL 7.5 host.
Eventually this could be replaced with docker for virtualisation.

The Ubuntu VM requires the following default components-
50GB mounted volume size.
4 cores.
16GB RAM.

Set a host name like-
deadlinedb.example.com

Assign a static ip address from your router to the bridge vm ethernet adaptor.  This address will be used for security groups.

A new user with UID 9001 and Gid 9001 named:
deadlineuser : deadlineuser
in ubuntu use adduser (not useradd)


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