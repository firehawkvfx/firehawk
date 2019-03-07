# openFirehawk
This is in developement and not ready for production.  Written by Andrew Graham for use with Hashicorp Terraform.

openFirehawk is a set of modules to help VFX artists create an on demand render farm with infrastructure as code.  It is written in Terraform.  While Terraform is able to interface with many cloud providers, current implementation is with AWS.  Extension to Google Cloud Platform is planned once a good simple foundation is established with these initial modules.

## Intro

I'll be changing the way things work to make openFirehawk easier for people over time.  Currently it is not ready for simple replication in another environment without challenges. It’s not going to be easy yet!  Much of the current work needs to be automated further, and learning it all if you are new to it is going to be a challenge.

Until we are ready for beta testing, these docs are still here for people driven to learn how things work and want to be involved as an early adopter.  I will work on these docs to give you a path to learn. contribution to these docs is welcomed!

But I do want to provide a path to get started for TDs that want to contribute, learn terraform, and are not afraid to push their bash skills in a shell further and learn new tools.

So for those that are comfortable with a challenge at this early stage and want to help develop, I’d recommend learning Terraform and Ansible.  Terraform is how we will define our infrastructure. Ansible (though not implemented at this time of writing) is how openFirehawk will be able go forward provisioning / configuring systems in a more modular fashion.  Currently provisioning is done in terraform over ssh, and it has a dependency on your open vpn connection to the access server to be working before any nodes in the private subnet can be provisioned.   Ansible will be able to replace this dependency being better suited to the task.

If you are totally new to this and you think its a lot to learn, I recommend just passively putting these tutorials on without necesarily following the steps to just expose yourself to the concepts and get an overview.  Going through the steps yourself is obviously better though.

These are some good paid video courses to try-
### Pluralsight:
- Terraform - Getting Started
- Deep Dive - Terraform

### Udemy:
- Mastering Ansible (its a little clunky at times but its still good)  
- Deploying to AWS with Ansible and Terraform - linux academy.

### Books:
- Terraform up and running.

## Getting Started

You will want to experiment with spinning up an AWS account.  You will need to start an instance in your nearest region with this ami - (softnas platinum consumption based for lower compute requirements).  take note of the AMI.  you wont need to leave this instance running.  You can terminate it, and delete the EBS volume.
Next startup up an open vpn access server instance from the openvpn AMI, and when started, take note of this AMI.  these will need to be added into terraform variables later, because they are unique to your region.

## Security
openFirehawk is not ready for production.  There are outstanding changes that need to be done to improve security for general use.

It's important that your router firmware is kept up to date.  We configure AWS to ignore all inbound communication from anywhere but your own static ip.  The greatest vulnerability between you and AWS is your router.  open vpn encrypts traffic before it goes through the router, but if the router is compromised, enough information to establish those credentials can be gained for a man in the middle attack.

## Disclaimer: Running your own AWS account.
You are going to be managing these resources from an AWS account and you are solely responsible for the costs incurred, and you should tread slowly to understand AWS charges.

The first thing to do is **setup 2 factor authentication.  Do not skip this**.  You'll make it easy for hackers to misuse you credit card to mine crypto.  Eye watering bills are possible!

So The next thing you should do is setup budget notifications.  Set a number you are willing to spend per month, and setup email notifications for every 20% of that budget.  The notifications are there in case you forget to do this step - check your AWS costs for a daily breakdown of what you spend, and do it every day to learn.  its a good habit to do it at the start of every day.

Lastly, when you create aws access and secret keys, set a policy to age those keys out after 30 days.  unlike normal access from a workstation, which can be 
limited down to a specific static ip with security groups, these access keys allow resources to be created from anywhere, and even for security groups to be changed, guard them closely.  Personally, I dont even write them down - If I need to enter them again for some reason, I take that opportunity to cycle them and enter update them into the encrypted vault.

## Pointers on cost awareness:

Initially run very small tests and get an understanding of costs with small tests that never use more than say 100GB of storage, that can be produced on light 2 core instances.  Cost managment in AWS is not easy, and you usually should allow a day before you can see a break down of what happenned (though its possible to implement more aggressive cost analysis with developement).

- EBS volumes (think virtual hard drives) cost money.  check for any volumes you don't need and delete them.

- S3 is cloud storage that also costs money.  Be mindful of it.  if you create an S3 drive with softnas, set a limit on that size that you are most comfortable spending if it fills up.  Make sure softnas is using a thin volume in S3, otherwise you allocate the full amount of data to be used even if the drive is empty.

- Check that any outstanding jobs are paused, and spot requests have been terminated in the spot fleet tab.  If you simply terminate an instance, but there are remaining render tasks, a spot fleet request may just replace it.  if you see any autoscaling groups, these should also be set to 0 (but we dont use them at the time of this writing).

- Turn off nodes when not using them.  When I'm done using the resources I do this-
terraform plan -out=plan -var sleep=true
I check the plan to see that it is going to do what it should.  then run this to execute it.
terraform apply plan

- If you run this command you can put all the infrastructure to sleep (including the NAT gateway), but you should always verify through the AWS console that this actually happenned, and that all nodes, and nate gateway are off.  

- The NAT gateway is another sneaky cost visible in your AWS VPC console, usually around $5 /day if you forget about it.  It allows your private network (systems in the private subnet) outbound access to the internet.  Security groups can lock down any internet access to the minimum adresses required for licencing things like softnas or other software.  Licensing configuration with most software you would use makes possible to not need any NAT gateway but that is beyond the scope of openFirehawk at this point in time.


## Running an onsite management VM with Vagrant

Vagrant is a tool that manages your initial VM configuration onsite.  It allows us to create a consistent environment to launch our infrastructure from.  From there we will provision the software installed on it with Ansible.

Currently, this has only been tested from a Linux RHEL 7.5/Centos Host.  You are welcome to experiment with other Operating systems so long as they can run the following-
    Vagrant
    VirtualBox
    Ansible

- Install Vagrant from Hashicorp.
- Install Virtualbox to run our VM from.
- Clone the openfirehawk repo
    git clone https://github.com/firehawkvfx/openfirehawk.git
- Download the latest deadline installer tar, and place the .tar file in the local openfirehawk/downloads folder.
- Download the latest houdini installer, and place the .tar file in the local openfirehawk/downloads folder.
- Run this to download an ubuntu base image and install ansible in the vm.  Provisioning the ubuntu desktop GUI may take 15mins +
    vagrant up
- When the the process completes, take a snapshot of this initial state and verify its there in the list.
    vagrant snapshot push
    vagrant snapshot list
- IMPORTANT if you ever need to restore the snapshot, be sure to use the --no-delete option, otherwise the snapshot will be deleted.  Try restoring a snapshot now-
    vagrant snapshot pop --no-delete
- Now we will ssh into the vm and start provisioning with ansible.
    vagrant ssh
- The git repo tree we are running vagrant from is shared with the VM in /vagrant
  We run our first playbook to create the deadlineuser and change the default password for the ubuntu user and deadlineuser.  This will also install deadline DB, and RCS, provided you have a tar downloaded in openfirehawk/downloads.
    ansible-playbook /vagrant/ansible/newuser_deadline.yaml

- You should be able to select the deadlineuser in the VM GUI, and login with a password. Open a terminal in the VM and run-
    deadlinemonitor
- You should see 1 slave exist in the bottom window, which is this vm.  since we can validate that the deadline DB and RCS is working, we will disable this because we won't want to use this server to render!
- INMPORTANT: After you start to render with more than 2 render nodes visible here, you need to purchase UBL credits for deadline to play with.  Thinkbox will credit that to your AWS account on request if you email them and request it.  You won't be able to test deadline with more than 2 nodes visible to the manager.  You will configure your UBL credits to use with the deadline monitor (see deadline docs on how to do this)
- to launch instances in AWS, you will configure your AWS account to be used with the Command Line Interface.  See aws documentation - https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html
More on this below...

## AWS configure

You should create a new user in your AWS account for the Command Line Interface(CLI).  Don’t use root account credentials.  if theres ever a problem with security, you want root to be able to disable the cli users access keys.

- Create a new user in your AWS management Console -> IAM.

- Give the user these permissions for testing only.  These permissions should be altered to be the minimum neecesary for your production after testing.
Permissions:
EC2FullAccess
IAMFullAccess
Route53FullAccess
s3AdminAcces

We currently use cloudfromation and need admin access.  It will be removed in the future but for now add these permissions:
AdministratorAccess

If you think you will need Active Directory for some reason, also add these permissions:
DirectoryServiceAdministrators

- Under security credentials, create Access Keys for the CLI.  Don't write these down anywhere, you are going to copy them straight into the VM.  its easy enough to destroy them and recreate them again in the future, you would just update with "aws configure" again.

- Enter the new users cli keys with:
    aws configure

- When asked for the region specify it from this list. https://docs.aws.amazon.com/general/latest/gr/rande.html
for example sydney is-
    ap-southeast-2
- When asked for the default output format, enter
    json

- Test that its working by running
    aws ec2 describe-regions --output table --debug

- This should out put a table of regions if working-

    ----------------------------------------------------------
    |                     DescribeRegions                    |
    +--------------------------------------------------------+
    ||                        Regions                       ||
    |+-----------------------------------+------------------+|
    ||             Endpoint              |   RegionName     ||
    |+-----------------------------------+------------------+|
    ||  ec2.eu-north-1.amazonaws.com     |  eu-north-1      ||
    ||  ec2.ap-south-1.amazonaws.com     |  ap-south-1      ||
    ||  ec2.eu-west-3.amazonaws.com      |  eu-west-3       ||
    ||  ec2.eu-west-2.amazonaws.com      |  eu-west-2       ||
    ||  ec2.eu-west-1.amazonaws.com      |  eu-west-1       ||
    ||  ec2.ap-northeast-2.amazonaws.com |  ap-northeast-2  ||
    ||  ec2.ap-northeast-1.amazonaws.com |  ap-northeast-1  ||
    ||  ec2.sa-east-1.amazonaws.com      |  sa-east-1       ||
    ||  ec2.ca-central-1.amazonaws.com   |  ca-central-1    ||
    ||  ec2.ap-southeast-1.amazonaws.com |  ap-southeast-1  ||
    ||  ec2.ap-southeast-2.amazonaws.com |  ap-southeast-2  ||
    ||  ec2.eu-central-1.amazonaws.com   |  eu-central-1    ||
    ||  ec2.us-east-1.amazonaws.com      |  us-east-1       ||
    ||  ec2.us-east-2.amazonaws.com      |  us-east-2       ||
    ||  ec2.us-west-1.amazonaws.com      |  us-west-1       ||
    ||  ec2.us-west-2.amazonaws.com      |  us-west-2       ||
    |+-----------------------------------+------------------+|

- You now have established the ability to control instances from within this VM.

## Create a key pair to manage AWS EC2

- ssh into the openfirehawk server vm
    vagrant ssh
    cd ~
- We should be in the vagrant user home dir within the vm.  now we generate a key pair with the AWS CLI. See this reference for more info https://sharadchhetri.com/2015/03/09/create-and-remove-aws-ec2-key-pair-by-using-command-line/
    aws ec2 create-key-pair --key-name my_key_pair --query 'KeyMaterial' --output text > ~/my_key_pair.pem
- And we set the permissions on that keypair so that only the vagrant user has read access.
    sudo chmod 400 ~/my_key_pair.pem
- Add the key for ssh forwarding.
    ssh-add ~/my_key_pair.pem

https://stackoverflow.com/questions/17846529/could-not-open-a-connection-to-your-authentication-agent/17848593#17848593

## Create a hosted zone
If you want to be able to access your resources through a domain like the vpn, eg vpn.example.com
you can create a public hosted zone in route53.  since this will be a permanent part of your infrastructure you will need to do this manually.
you can either transfer an existing domain to aws (not recommended for dev if you are attached to this domain!)
or you can purchase a new domain of some random name with a cheap extension (doesn't need to be .com)




## OpenVPN Access Server

Then you can try starting an OpenVPN Access Server AMI by launching a new EC2 instance on AWS through the EC2 console.  It’s a good exercise for you to create one of these on your own (not using openFirehawk at this stage) in a public subnet.  

Its important to start a single instance to register yourself to the ami.  if you want to learn more about thi instance read on, otherwise skip to terraform!

You will also need to allow a security group to have inbound access from your onsite public static IP adress.
If you can succesfuly auto connect to this openvpn instance, then openFirehawk will be able to create its own OpenVPN Access Server and connect to it as well.

Instances that reside in the private subnet are currently configured through openvpn.  This is why we are moving to Ansible to handle this instead, and remove openVPN as a dependency for most of the configuration of the network.  open vpn will still be needed for render nodes to establish a connection with licence servers and the render management DB.


## Terraform

Terraform is used to create all our infrastructure in the cloud provider.  It is launched from with your vm which contains all the credentials required to create resources.

- From the git repo folder on your host, we will ssh into the openfirehawk server with vagrant ssh-
    :../openfirehawk/$ vagrant ssh
- Once in, type 
    cd /vagrant
    ls
- The contents of this shared folder should be identical to the openfirehawk repository folder.
- If you cannot see anything in here, you may need to reload the vm and try again-
    exit
    vagrant reload
    vagrant ssh


- now we will initialise terraform. in the /vagrant path.
    terraform init

- when it completes, spin up the infrastructure.
    terraform plan -out=plan

- if all seem well, apply the plan.
    terraform apply plan

- now provision openvpn.
cd /vagrant && ansible-playbook -i /usr/local/bin/terraform-inventory /vagrant/ansible/openvpn.yaml


## Configuring private variables

Next you can clone the git repository into your ubuntu vm-
git clone https://github.com/firehawkvfx/openfirehawk.git

I do need to make it known that the way we are storing private variables is not best practice, and I intend to move to a product called vault to handle the storing of secrets in the future in an encrypted format.

Currently, we have a [private-variables.example](https://github.com/firehawkvfx/openfirehawk/blob/master/private-variables.example) file, which you will copy and rename to [private-variables.tf](https://github.com/firehawkvfx/openfirehawk/blob/master/private-variables.example)
This filename is in .gitignore, so it will not be in any git commits.  You should set permissions on it so that only you have read access, and root has write access.

In it you will set your own values for these variables.  Many will be different for your environment, and you **absolutely must use unique passwords and set your public static ip address for onsite**.

Security groups are configured to ignore any inbound internet traffic unless it comes from your onsite public ip address
 which should be static and you’ll need to arrange that with your ISP if you are working from home.

In terraform, each instance we start will use an AMI, and these AMI’s are unique to your region.  We would like the ability to query all ami’s for all regions (https://github.com/firehawkvfx/openfirehawk/projects/1#card-17639682) but for now it doesn’t appear possible for softnas.

So each instance like these that are used will need you to launch them once to get the AMI ID.
- CentOS7 (search for CentOS Linux 7 x86_64 HVM in your region)
- openvpn (search for OpenVPN Access Server in your region)
- Teradici pcoip for centos 7  (search for Teradici Cloud Access Software for CentOS 7 in your region)

You’ll need to agree to the conditions of the ami, and then enter the ami ID that resulted ) visible from the aws ec2 instance console) for your region into the map.  Feel free to commit the added AMI map back into the repo too to help others.

In terraform, a map is really a dictionary for those familiar with python.  This is an example of the ami_map variable in node_centos/variables.tf
```
variable "ami_map" {
  type = "map"

  default = {
    ap-southeast-2 = "ami-d8c21dba"
  }
}
```
ap-southeast-2 is the sydney region, so if that region is set correctly in private-variables.tf
then when we lookup the dictionary, we will get the ami with this function in main.tf

    lookup(var.ami_map, var.region)

So if I’m located at us-east-1, after starting up the latest CentOS 7 AMI, I can enter that in like so
```
variable "ami_map" {
  type = "map"

  default = {
    ap-southeast-2 = "ami-d8c21dba"
    us-east-1 = “ami ID goes here”
  }
}
```
and provided your region is set correctly in private-variables.tf, then that ami IDwill be looked up correctly.


## Your first terraform apply
In the open firehawk repo, I recommend you pen up the main.tf file and comment out everything except the vpc to ensure you can create the vpc, and also connect openvpn.  It’s necesary for the openvpn component to work before moving forward.

Run:

    terraform init

Review the plan output is without errors:

    terraform plan -out=plan

Execute the plan.  Writing out a plan before execution and reviewing it is best practice.

    terraform apply plan

If at any point you want to remove all the infrastructure (to save cost, perhaps you don't need it anymore, or you want to start over)

    terraform destroy

Keep in mind that you may still have ebs volumes, s3 usage or other resources to consider in your account costs that will remain.

openFirehawk also uses a sleep variable.  When sleep is set to true, it will shutdown all systems, including the NAT gateway.  its a good idea to do this when nothing is needed, but you want to continue working later.

    terraform plan -out=plan -var sleep=true

View the plan and run it if all is well to turn things off

    terraform apply plan

Make sure you check your aws account for any resources that haven't been turned off.

## Terraform - taint

if you make changes to your infrastructure that you want to recover from, a good way to replace resources is something like this...  lets say I want to destroy my openvpn instance and start over

    terraform taint -module vpc.vpn.openvpn aws_instance.openvpn

Now I should also taint what is downstream if there are dependencies that aren't being picked up too, like the eip.

    terraform taint -module vpc.vpn.openvpn aws_eip.openvpnip

The resource aws_eip.openvpnip in the module root.vpc.vpn.openvpn has been marked as tainted!

    terraform taint -module vpc.vpn.openvpn aws_route53_record.openvpn_record

The resource aws_route53_record.openvpn_record in the module root.vpc.vpn.openvpn has been marked as tainted!


after I'm happy with this I can run terraform apply.
    terraform plan -out=plan
    terraform apply plan


## Preparation of open vpn

Read these docs to set permissions on the autostart openvpn config and startvpn.sh script, and how to configure the access server.  Some settings are required to allow access to the ubuntu VM you have onsite, and we go through these steps in the tf_aws_openvpn readme-

[README.md](https://github.com/firehawkvfx/tf_aws_openvpn/blob/master/README.md)
[startvpn.sh](https://github.com/firehawkvfx/tf_aws_openvpn/blob/master/startvpn.sh)

## Important Notes for Routing:

### You can check /var/log/syslog to confirm vpn connection.
check autoload is set to all or openvpn in /etc/default
ensure startvpn.sh is in ~/openvpn_config.  openvpn.conf auto login files are constructed here and placed in /etc/openvpn before execution.  
  
read more here to learn about setting up routes  
https://openvpn.net/vpn-server-resources/site-to-site-routing-explained-in-detail/  
https://askubuntu.com/questions/612840/adding-route-on-client-using-openvpn  

You will need ip forwarding on client and server if routing both sides.  
https://community.openvpn.net/openvpn/wiki/265-how-do-i-enable-ip-forwarding  


**These are the manual steps required to get both private subnets to connect, and we'd love to figure out the equivalent commands drop in when I'm provisioning the access server to automate them, but for now these are manual steps.**
  
-  in VPN Settings | Should VPN clients have access to private subnets  
(non-public networks on the server side)?  
Yes, enable routing  
  
- Specify the private subnets to which all clients should be given access (one per line):  
10.0.1.0/24
10.0.101.0/24
172.27.232.0/24
(these subnets are in aws, the open vpn access server resides in the 10.0.101.0/24 subnet)  

- Allow access from these private subnets to all VPN client IP addresses and subnets : on  
  
- in user permissions | user  
configure vpn gateway:  
yes  
  
- Allow client to act as VPN gateway (enter the cidr block for your onsite network)
for these client-side subnets:  
192.168.92.0/24

# ssh in to node in the private subnet and attempt to ping the openfirehawkserver.  if you cannot try also adding this in the vpn settings-
- Allow client to act as VPN gateway (enter the cidr block for your onsite network)
for these client-side subnets:  
172.27.232.0/24

At this point, your client side vpn client should be able to ping any private ip, and if you ssh into one of those ips, it whould be able to ping your client side ip with its private ip address.

If not you will have to trouble shoot before you can continue further because this functionality is required.
  
if you intend to provide access to other systems on your local network, promiscuous mode must enabled on host ethernet adapters.  for example, if openvpn client is in ubuntu vm, and we are running the vm with bridged ethernet in a linux host, then enabling promiscuous mode, and setting up a static route is needed in the host.  
https://askubuntu.com/questions/430355/configure-a-network-interface-into-promiscuous-mode  
for example, if you use a rhel host run this in the host to provide static route to the adaptor inside the vm (should be on the same subnet)
```
sudo ip route add 10.0.0.0/16 via [ip adress of the bridged ethernet adaptor in the vm]
```
check routes with:
```
sudo route -n
ifconfig eth1 up
ifconfig eth1 promisc
```

In the ubuntu vm where where terraform is running, ip forwarding must be on.  You must be using a bridged adaptor.
http://www.networkinghowtos.com/howto/enable-ip-forwarding-on-ubuntu-13-04/

```
sudo sysctl net.ipv4.ip_forward=1
```


This allows permission for startvpn.sh script to copy open vpn startup settings from the access server into your openvpn settings.  sudo permissions must be allowed for the specific commands executed so they can be performed without a password.

If all goes well, the startvpn.sh script when executed will initiate a connection with the openvpn access server, and you will be able to ping the access server's private IP.  You should also be able to ping the public ip too.  If you can’t ping the public ip you have a security group issue and your onsite static ip isn’t in the private-variables.tf file.

You can also manually start open vpn with:

    sudo service openvpn restart




<!--stackedit_data:
eyJoaXN0b3J5IjpbLTEyNzAwNzg1NjUsMTkzMzQ5NTI3MCwxNz
ExNzUxMTEsOTU5NjMzNDQzLC0xMTU5MjY5MzYwLC0xNzMwNTc1
MzU0LC0xNTAxNTY2OTMsLTM2Njk0ODcwLDY1OTA4OTA5NCw1ND
g5ODM2OTYsLTc5NDU5MjA1LDUwODUzMDQ4MSw3MDgxNzYyOV19

-->