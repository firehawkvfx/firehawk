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
- Mastering Ansible
- Deploying to AWS with Ansible and Terraform - linux academy.

### Books:
- Terraform up and running.
- Ansible up and running.

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


## Preparing an onsite management VM with Vagrant

Vagrant is a tool that manages your initial VM configuration onsite.  It allows us to create a consistent environment to launch our infrastructure from.  From there we will provision the software installed on it with Ansible.

Currently, this has only been tested from a Linux RHEL 7.5/Centos Host.  You are welcome to experiment with other Operating systems so long as they can run the following-
    Vagrant
    VirtualBox
    Ansible

- All these steps will get you to configure a setup in the 'prod' environment.  Later, if you with to make alterations you can use 'dev' instead.
- Install Vagrant from Hashicorp.
- Install Virtualbox to run our VM from.
- Clone the openfirehawk repo into a folder named openfirehawk-prod.  Production operates from the master branch.
    git clone --recurse-submodules -j8 https://github.com/firehawkvfx/openfirehawk.git openfirehawk-prod
- You may also wish to clone with the dev branch into a seperate folder - openfirehawk-dev.  It's recommended to run dev in a seperate AWS account.  No changes to the master branch should be permitted without testing in dev first, including a full 'terrraform apply' from scratch.
- If you already cloned the repo but forgot the submodules, you can bring them in with
    git submodule update
- Download the latest deadline installer tar, and place the .tar file in the local openfirehawk/downloads folder.
- Download the latest houdini installer, and place the .tar file in the local openfirehawk/downloads folder.
- If you are on a mac, install homebrew and ensure you have the command envsubst
    brew install gettext
    brew link --force gettext
- Now we will setup our environment variables from a template. If you have already done this before, you will probably want to keep your old secrets instead of copying in the template.
    cp secrets.template secrets/secrets-prod
- First step before launching vagrant is to ensure an environment var is set with a random mac (you can generate it yourself with scripts/random_mac_unicast.sh) and store it as a variable in secrets/secrets-prod.  eg,
    TF_VAR_vagrant_mac_prod=0023AE327C51
- Set the environment variables from the secrets file.  --init assumes an unencrypted file is being used.  We always must do this before running vagrant.
    source ./update_vars.sh --prod --init
- Get your router to assign/reserve a static ip using this same mac address so that the address doesn't change.  if it does, then render nodes won't find the manager.

## Running Vagrant and configuring with Ansible

- Run this to download an ubuntu base image and install ansible in the vm.  Provisioning the ubuntu desktop GUI may take 15mins +
    vagrant up
- You will be asked which adaptor to bridge to. select the primary adapter for your internet connection.  This should be in the 192.168.x.x range.
- When the the process completes, take a snapshot of this initial state and verify its there in the list.
    vagrant snapshot push
    vagrant snapshot list
- IMPORTANT if you ever need to restore the snapshot, be sure to use the --no-delete option, otherwise the snapshot will be deleted.  Try restoring a snapshot now-
    vagrant snapshot pop --no-delete
- Now we will ssh into the vm and start provisioning with ansible.
    vagrant ssh
- The git repo tree we are running vagrant from is shared with the VM in /vagrant.
- Now edit secrets/secret-prod with your own values for configuration. If you already have AWS account keys and a aws public zone id, you will set them in this secrets file, otherwise read the steps on AWS configure, and How To Create a Hosted Zone.  Unless you are launching in Sydney, you are going to have to collect a few AMI ID's - read Getting AMI ID's for your region, and return to this step when complete.
- After this is done,
we can initialise the secrets keys and encrypt.
    cd /vagrant
    source ./update_vars.sh --prod --init
    ansible-playbook ansible/init-keys.yaml
- From now on, you can set environment variables without --init, which will use your now encrypted secrets file.  We can set our environment variables and make the values available to terraform and ansible.
    source ./update_vars.sh --prod
- If you already have an aws account,
- Now we can execute the first playbook to initialise the vm.
    ansible-playbook -i ansible/inventory/hosts ansible/init.yaml
- Download the deadline linux installer version 10.0.23.4 (or latest version) into downloads/Deadline-10.0.23.4-linux-installers.tar, then setup the deadline user and deadline db + deadline rcs with this playbook. set the version in your secrets file.
    ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadline.yaml -v
- Remember to always run source ./update_vars.sh before running any ansible playbooks, or using terraform.  Without your environment variables, nothing will work.
- Download the latest houdini installer tar to the downloads folder.
    ansible-playbook -i ansible/inventory/hosts ansible/openfirehawkserver_houdini.yaml -v
- Init your aws access key if you don't already have one setup from a previous installation of open firehawk
    ansible-playbook -i ansible/inventory/hosts ansible/aws-new-key.yaml
- Subscribe to these amis (it may take some time before your subscription is processed)-
    openvpn https://aws.amazon.com/marketplace/pp/B00MI40CAE
    centos7 https://aws.amazon.com/marketplace/pp/B00O7WM7QW?qid=1552746240289&sr=0-1&ref_=srh_res_product_title
    softnas cloud platinum https://aws.amazon.com/marketplace/pp/B07DGMG5ZD?qid=1552746298127&sr=0-2&ref_=srh_res_product_title
    softnas cloud platinum - lower compute https://aws.amazon.com/marketplace/pp/B07DGGZBCG?qid=1552746484959&sr=0-9&ref_=srh_res_product_title
- Now lets initialise terraform, and run our first terraform apply.  Read more about this here for best practice - Your first terraform apply
    terraform init
    terraform plan -out=plan
- if this is without errors, apply the plan.
    terraform apply plan
- later, you can destroy the infrastructure if you don't need it anymore.  note that ebs volumes may not be destroyed, and s3 disks will remain.  to destroy at any point, use...
    terraform destroy
Note: there are currently bugs with the way the aws terraform provider resolves dependencies to destroy in the correct order.  currently if you repeat is 3 times, it should remove the resources.  you can verify by checking the vpc is deleted from the aws management console.
- Also, you should turn off the infrastructure when not using it.  When I'm done using the resources I do this-
    terraform plan -out=plan -var sleep=true
I check the plan to see that it is going to do what it should.  then run this to execute it.  it is your responsibility to ensure that everything is turned off so you don't incur charges, but this is provided for connvenience.
    terraform apply plan
- ...and to turn everything back on, just run
    terraform apply
- While your Infrastructure is up, you should be able to select the deadlineuser in the VM GUI, and login with a password. Open a terminal in the VM GUI, logged in as deadlineuser and run this-
    deadlinemonitor
- IMPORTANT: After you start to render with more than 2 render nodes visible here in the monitor, you need to purchase UBL credits for deadline to play with.  Thinkbox will credit that to your AWS account on request if you email them and request it.  You won't be able to test deadline with more than 2 nodes visible to the manager.  You will configure your UBL credits to use with the deadline monitor (see deadline docs on how to do this)
- To launch instances in AWS, you will configure your AWS account to be used with the Command Line Interface.  See aws documentation - https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html
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

- Under security credentials, create Access Keys for the CLI.  Don't write these down anywhere, you are going to copy them straight into the secrets/secret-prod file.  its easy enough to destroy them and recreate them again in the future, you would just update with the init playbook again-
    ansible-playbook -i ansible/inventory/hosts ansible/init.yaml

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

## How To Create a Hosted Zone
If you want to be able to access your resources through a domain like the vpn, eg vpn.example.com
you can create a public hosted zone in route53.  since this will be a permanent part of your infrastructure you will need to do this manually.
you can either transfer an existing domain to aws (not recommended for dev if you are using this domain in production!)
or you can purchase a new domain of some random name with a cheap extension (doesn't need to be .com, there are plenty of cheap alternatives)

## OpenVPN Access Server

Then you can try starting an OpenVPN Access Server AMI by launching a new EC2 instance on AWS through the EC2 console.  It’s a good exercise for you to create one of these on your own (not using openFirehawk at this stage) in a public subnet.  

Its important to start a single instance to register yourself to the ami.  if you want to learn more about thi instance read on, otherwise skip to terraform!

You will also need to allow a security group to have inbound access from your onsite public static IP adress.
If you can succesfuly auto connect to this openvpn instance, then openFirehawk will be able to create its own OpenVPN Access Server and connect to it as well.

Instances that reside in the private subnet are currently configured through openvpn.  This is why we are moving to Ansible to handle this instead, and remove openVPN as a dependency for most of the configuration of the network.  open vpn will still be needed for render nodes to establish a connection with licence servers and the render management DB.

## Secrets
In the secrets file, you will set your own values for these configuration variables.  Many will be different for your environment, and you **absolutely must use unique passwords and set your static ip address for onsite**.

If you ever make commits to a git repo, ensure you never commit unencrypted secrets or anything in the secrets/ path.  vault keys and pem keys for ssh access are stoed in keys/ and these should not be committed to version control.

Security groups are configured to ignore any inbound internet traffic unless it comes from your onsite public ip address which should be static and you’ll need to arrange that with your ISP if you are working from home.  If it isn't static, this is currently an untested workflow (though we have already implemented some measures to update security groups automatically).

In terraform, each instance we start will use an AMI, and these AMI’s are unique to your region.  We would like the ability to query all ami’s for all regions (https://github.com/firehawkvfx/openfirehawk/projects/1#card-17639682) but for now it doesn’t appear possible for softnas.

## Getting AMI ID's for your region.

Currently, all the AMI's tested have been selected for use from Sydney.

So each instance like these that are used will need you to launch them once to get the AMI ID.
- CentOS7 (search for CentOS Linux 7 x86_64 HVM in your region)
- openvpn (search for OpenVPN Access Server in your region)
- Teradici pcoip for centos 7  (search for Teradici Cloud Access Software for CentOS 7 in your region)

You’ll need to agree to the conditions of the ami, and then enter the ami ID that resulted ) visible from the aws ec2 instance console) for your region into the map.  Feel free to commit the added AMI map back into the repo too to help others.  Here is an example of how to update that map-

In terraform, a map is a dictionary for those familiar with python.  This is an example of the ami_map variable in node_centos/variables.tf
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
...and provided your region is set correctly in your secrets file and environment, then that ami ID can be looked up correctly.


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

## Openvpn

- If you start the vagrant vm in the future, and your openvpn access server wasn't running, then the openvpn service wont be connected.  you can start the service with- 
    sudo service openvpn restart
- You can check the logs after 1 minute with..
    cat /var/log/syslog
Here you should see the connection was initialised.  if not, try running this playbook (provided all your infrastructure is up)
- You can also verify the connection by pinging your softnas instance, or another instance in the private subnet with
    ping 10.0.1.11
- If you can't establish a connection, you can try tainting the open vpn resources, rebuilding them and try again.

## Terraform - taint

If you make changes to your infrastructure that you want to recover from, a good way to replace resources is something like this...  lets say I just moved to a different network that has a different subnet, or my local IP changes for openfirehawkserver.  its easy to to destroy my openvpn instance and start over

    terraform taint -module vpc.vpn.openvpn aws_instance.openvpn

- Now I should also taint what is downstream if there are dependencies that aren't being picked up too, like the eip.

    terraform taint -module vpc.vpn.openvpn aws_eip.openvpnip
    The resource aws_eip.openvpnip in the module root.vpc.vpn.openvpn has been marked as tainted!

After I'm happy with this I can run terraform apply to recrete the vpn.
    terraform plan -out=plan
    terraform apply plan
- When this is done, check the logs for the connection being initialised
    sudo cat /var/log/syslog
- You should see a line toward the end with
    openfirehawkserver ovpn-openvpn[21984]: Initialization Sequence Completed
- Validate this by pinging an ip in the private subnet
    ping 10.0.1.11

## Softnas

You can keep tabs on an S3 bucket's size with this command, 
    aws s3 ls s3://bucket_name --recursive  | grep -v -E "(Bucket: |Prefix: |LastWriteTime|^$|--)" | awk 'BEGIN {total=0}{total+=$3}END{print total/1024/1024" MB"}'

To improve performance, you can add a write log and read cache to the s3 pool.  Write logs should 2 ssd's mirrored since they form a dependency for writing data to your pool, a read cache doesn't require mirroring.



<!--stackedit_data:
eyJoaXN0b3J5IjpbLTEyNzAwNzg1NjUsMTkzMzQ5NTI3MCwxNz
ExNzUxMTEsOTU5NjMzNDQzLC0xMTU5MjY5MzYwLC0xNzMwNTc1
MzU0LC0xNTAxNTY2OTMsLTM2Njk0ODcwLDY1OTA4OTA5NCw1ND
g5ODM2OTYsLTc5NDU5MjA1LDUwODUzMDQ4MSw3MDgxNzYyOV19

-->