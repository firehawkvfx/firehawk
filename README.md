# openFirehawk
Written by Andrew Graham for use with Hashicorp Terraform.

This is in developement and not ready for production.  

# Getting Started

I'll be changing the way things work to make openFirehawk easier for people over time.  Currently it is not ready for simple replication in another environment without challenges. It’s not going to be easy yet!  Much of the current work needs to be automated further, and learning it all if you are new to it is going to be a challenge.

Until we are ready for beta testing, these docs are still here for people driven to learn how things work and want to be involved as an early adopter.  I will work on these docs to give you a path to learn. contribution to these docs is welcomed!

But I do want to provide a path to get started for TDs that want to contribute, learn terraform, and are not afraid to push their bash skills in a shell further and learn new tools.

So for those that are comfortable with a challenge at this early stage and want to help develop, I’d recommend learning Terraform and Ansible.  Terraform is how we will define our infrastructure. Ansible (though not implemented at this time of writing) is how openFirehawk will be able go forward provisioning / configuring systems in a more modular fashion.

If you are totally new to this and you think its a lot to learn, I recommend just passively putting these tutorials on without necesarily following the steps to just expose yourself to the concepts and get an overview.  Going through the steps yourself is obviously better though.

These might be good paid video courses to try-
Pluralsight:
Terraform - Getting Started
Deep Dive - Terraform

Udemy:
Mastering Ansible (its a little clunky at times but its still good)  
Deploying to AWS with Ansible and Terraform - linux academy.

There is also the book:
Terraform up and running.

# Getting Started

You will want to experiment with spinning up an AWS account.  You will need to start an instance in your nearest region with this ami - (softnas platinum consumption based for lower compute requirements).  take note of the AMI.  you wont need to leave this instance running.  You can terminate it, and delete the EBS volume.
Next startup up an open vpn access server instance from the openvpn AMI, and when started, take note of this AMI.  these will need to be added into terraform variables later, because they are unique to your region.


### Some notes on you own AWS account - with great power comes great responsibility:
You are going to be managing these resources from an AWS account and you are solely responsible for the costs incurred, and to understand AWS charges.  The first thing you should be doing is setup 2 factor authentication.  Do not skip this.  You'll make it easy for hackers to misuse you credit card to mine crypto.  Eye watering bills are possible!  

So The next thing you should do is setup budget notifications.  Set a number you are willing to spend per month, and setup email notifications for every 20% of that budget.  The notifications are there in case you forget to do this step - check your AWS costs for a daily breakdown of what you spend, and do it every day to learn.  its a good habit to do it at the start of every day.

These are the main pointers I have on cost awareness -

Run very small tests and get an understanding of costs with small tests that never use more than say 100GB of storage, and can be produced on light 2 core instances.

EBS volumes (think virtual hard drives) cost money.  check for any volumes you don't need and delete them.

S3 is cloud storage that also costs money.  Be mindful of it.  if you create an S3 drive with softnas, set a limit on that size that you are most comfortable spending if it fills up.  Make sure softnas is using a thin volume in S3, otherwise you allocate the full amount of data to be used even if the drive is empty.

Check that any outstanding jobs are paused, and spot requests have been terminated in the spot fleet tab.  If you simply terminate an instance, but there are remaining render tasks, a spot fleet request may just replace it.  if you see any autoscaling groups, these should also be set to 0 (but we dont use them at the time of this writing).

Turn off nodes when not using them.  When I'm done using the resources I do this-
terraform plan -out=plan -var sleep=true
I check the plan to see that it is going to do what it should.  then run this to execute it.
terraform apply plan

If you run this command you can put all the infrastructure to sleep (including the NAT gateway), but you should always verify through the AWS console that this actually happenned, and that all nodes, and nate gateway are off.  

The NAT gateway is another sneaky cost visible in your AWS VPC console, usually around $5 /day if you forget about it.  It allows your private network (systems in the private subnet) outbound access to the internet.  Security groups can lock down any internet access to the minimum adresses required for licencing things like softnas or other software.  Licensing configuration with most software you would use makes possible to not need any NAT gateway but that is beyond the scope of openFirehawk at this point in time.


### running the onsite component

You can also start experimenting with an Ubuntu 16 VM with 4 vcpus, and a 50GB volume to install to.  8GB RAM is a good start.
Buy a few UBL credits for deadline, $10 worth or so to play with.  Thinkbox will credit that to your AWS account on request if you email them.

The vm will need a new user.  we will call it deadlineuser.  it will also have auid of 9001.  its possible to change this uid but be mindful of the variables set in private-variable.tf if you do,
sudo adduser -u 9001 deadlineuser.
This user should also be the member of a group, deadlineuser, and the gid should be 9001.  you can review this with the command
cat /etc/group
Next you will want the user to be a super user for now.  it will be possible to tighten the permissions later, but for testing we will do this-
sudo usermod -aG wheel ${var.deadline_user}

now log out and log back in as the new user.

You will want to install deadline DB, and deadline RCS in the vm, and take note of all the paths where you place your certificates.  We selected the ubuntu 16 VM because at this time its the easiest way to install Deadline DB and RCS on. 

In the ubuntu 16 VM you will also want to install open vpn with:
sudo apt-install openvpn
Then you can try starting an openvpn access server AMI on AWS.  It’s a good exercise for you to create one of these on your own (not using openFirehawk at this stage) in a public subnet.  learning how to get the autoconnect feature working for the ubuntu vm to this openVPN instance will be needed.  if you can do that, openFirehawk will be able to create its own open vpn server and connect to it.

Instances that reside in the private subnet are currently configured through openvpn.  This is why we are moving to Ansible to handle this instead, and remove openVPN as a dependency for most of the configuration of the network.  open vpn will still be needed for render nodes to establish a connection with licence servers and the render management DB.

### AWS configure

Next you will go through the steps to install the AWS cli into the ubuntu 16 VM.
You should create a new user in aws for the cli.  don’t use the root account.  if theres ever a problem with security, you want root to be able to disable the cli users access keys.

when you enter the new users cli keys with:
aws cli configure

and test that its working by running
aws ec2 describe-regions --output table --debug
Which should out put a table of regions if working.

### Install Terraform ###

https://learn.hashicorp.com/terraform/getting-started/install.html

### configuring private variables

Next you can clone the git repository into your ubuntu vm-
git clone https://github.com/firehawkvfx/openfirehawk.git

I do need to make it known that the way we are storing private variables is not good, and I intend to move to a product called vault to handle the storing of secrets in the future.

Currently, we have a private-variables.example file, which you will copy and rename to private-variables.tf
This filename is in .gitignore, so it will not be in any git commits.
You should set permissions on it so that only you have read acces, and root has write access.
In it you will set your own values for these variables.  many will be different for your environment, and you absolutely must use unique passwords and set your public static ip address for onsite.

Security groups are configured to ignore any inbound internet traffic unless it comes from your onsite public ip address
 which should be static and you’ll need to arrange that with your ISP if you are working from home.

In terraform, each instance we start will use an AMI, and these AMI’s are unique to your region.  We would like the ability to query all ami’s for all regions (https://github.com/firehawkvfx/openfirehawk/projects/1#card-17639682) but for now it doesn’t appear possible for softnas.

so each instance like these that are used will need you to launch them once.
centos7 (search for CentOS Linux 7 x86_64 HVM in your region)
openvpn (search for OpenVPN Access Server in your region)
Teradici pcoip for centos 7  (search for Teradici Cloud Access Software for CentOS 7 in your region)

you’ll need to agree to the conditions of the ami, and then enter the ami ID that resulted ) visible from the aws ec2 instance console) for your region into the map.  Feel free to commit the added AMI map back into the repo too to help others.

This is an example of the map in node_centos/variables.tf

variable "ami_map" {
  type = "map"

  default = {
    ap-southeast-2 = "ami-d8c21dba"
  }
}

ap-southeast-2 is the sydney region, so if that region is set correctly in private-variables.tf
then when we lookup the dictionary, we will get the ami with this function in main.tf
lookup(var.ami_map, var.region)

so if I’m us-east-1, after starting up the latest centos 7 ami, I can enter that in like so
variable "ami_map" {
  type = "map"

  default = {
    ap-southeast-2 = "ami-d8c21dba"
    us-east-1 = “ami ID goes here”
  }
}

and provided your region is set correctly in private-variables.tf, then that ami will be looked up.


### your first terraform apply ###
in the open firehawk repo, I recommend open up the main.tf file and comment out everything except the vpc to ensure you can create the vpc, and connect openvpn.  It’s necesary for this component to work before moving forward.

run:
terraform init

review the output is without errors:
terraform plan -out=plan

Execute the plan.
terraform apply plan

### preparation of open vpn

Read these docs to set permissions on the autostart openvpn script, and how to configure the access server.  some settings are required to allow access to the ubuntu VM you have onsite.

README.md
startvpn.sh

this allows permission for a script to copy open vpn startup settings from the access server into your openvpn settings.

if all goes well, the startvpn.sh script when executed will initiate a connection with the openvpn access server, and you will be able to ping its private ip.  you should be able to ping the public ip too.  if you can’t ping the public ip you have a security group issue and your onsite static ip isn’t in the private-variables.tf file.

### old docs to migrate

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
<!--stackedit_data:
eyJoaXN0b3J5IjpbNTQ4OTgzNjk2LC03OTQ1OTIwNSw1MDg1Mz
A0ODEsNzA4MTc2MjldfQ==
-->