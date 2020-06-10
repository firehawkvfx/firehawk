# Open Firehawk

Open Firehawk is an environment to create an on demand render farm for VFX with infrastructure as code.  It uses Terraform to orchestrate resources, Ansible to configure resources, and Vagrant (with Virtualbox) as a VM container for these tools to run within.  A Linux or Mac OS host for the VM's is recommended at this time.  Terraform is able to interface with many cloud providers, current base implementation is with AWS.  It does use resources that have costs for their use, the types of resources chosen are based off the ones that were most cost effective for my use case. PR's for other resource options are welcome!

## Intro

We document steps you can follow for replication of Firehawk in another environment.

Some of this documentation will share what you will need to learn if you are a TD / Pipeline TD new to running cloud resources.  I’d recommend learning Terraform and Ansible.  I recommend passively putting these tutorials on without necesarily following the steps to just expose yourself to the concepts and get an overview.  Going through the steps yourself is better.

These are some good paid video courses to try which I have taken on my own learning path-

### Pluralsight:

- Terraform - Getting Started
- Deep Dive - Terraform

### Udemy:

- Mastering Ansible
- Deploying to AWS with Ansible and Terraform - linux academy.

### Books:

- Terraform up and running.
- Ansible up and running.

## Disclaimer: Running your own AWS account.
You are going to be managing these resources from an AWS account and you are solely responsible for the costs incurred, and for your own education in managing these resources responsibly.  If new to AWS, tread slowly to understand AWS charges.  The information I provide here is not perfect, but shared in a best effort to help others get started.

## Getting Started

You will need two AWS Accounts.  One for the dev environment and one for the production environment.  When operating, we make changes to the dev branch/environment and test before we update the production environment.  Some exceptions during a deployment may mean changes unique to the production environment have to be done on the fly, and when they occur we merge those changes back to dev.

With each of the accounts:
- Create a user by your real name, and follow the instructions AWS provides for best practice.
- Ensure MFA is enabled, MFA is best done with a seperate device / phone. **Setup 2 factor authentication.  Do not skip this, any account with a login should have it.**
- Use a good password manager for passwords, ensure it has MFA for its ability to be accessed as well.  (I decided to use 1Password in a web browser for Linux and Mac OS- I'm not endorsed by this company, just sharing some of my own choices).
- Setup budget notifications.  Set a number you are willing to spend per month, and setup email notifications for every 20% of that budget.  The notifications are there in case you forget to do the next step...
- [Check your AWS costs](https://console.aws.amazon.com/cost-management/) for a daily breakdown of what you spend, and do it every day as you learn.  It's a good habit to do it at the start of every day.

Best practices for security and best practice around secrets management are important.  Feel free to notify us if you observe security implementation that could be improved.

## Permissions for the new user

Firehawk automates creation of some user accounts, instances, VPN, NAS storage and others.  A primary user with appropriate permissions must be manually created for this to be possible.
We will define the permissions for this new user (in each of the accounts).  Later we will generate secret keys that will be stored in an encrypted file to create resources with Terraform and Ansible that rely on these permissions.

- Goto Identity and Access Management (IAM)
- Create a new group ``DevAdmin``
- Attach these policies to that group
```
AmazonEC2FullAccess
IAMFullAccess
AmazonS3FullAccess
AmazonECS_FullAccess
AmazonRoute53FullAccess
```
- Create a new policy named ``GetCostAndUsage``
- Provide the following policy in JSON
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ce:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
- Attach that policy as well to the ``DevAdmin`` group.
- Make the new user a member of the ``DevAdmin`` group to inherit all of these policies.
- Ensure you have done this in both AWS accounts.
- When you create AWS access and secret keys, set a policy to age those keys out after 30 days.

## AWS Images

Some images are used with a cost associated.  Firehawk is not paid to recommend these, they are used because they are at the time of writing believed to be the most economical, fairly scalable, and automated choices available with good support.  Not  all of these images are open source themselves, but can be replaced.

Subscribe to these Images (AMIs), which will allow them to be used with automation after you have agreed to their terms.

- [Softnas Burst](https://aws.amazon.com/marketplace/pp/B086PGVGJS?qid=1591580034153&sr=0-1&ref_=srh_res_product_title)
- [Open VPN Access Server](https://aws.amazon.com/marketplace/pp/B00MI40CAE?qid=1591580399199&sr=0-1&ref_=srh_res_product_title)
- [Teradici PCOIP](https://aws.amazon.com/marketplace/pp/B07CT11PCQ?qid=1591580476870&sr=0-3&ref_=srh_res_product_title#pdp-reviews)
- [CentOS 7](https://aws.amazon.com/marketplace/pp/B00O7WM7QW?qid=1591580670593&sr=0-1&ref_=srh_res_product_title)

If you are new to AWS, [experiment with launching these instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html), and destroying them and their security groups.

## Keybase / PGP Keys

Install Keybase on your phone or PC - head to keybase.io to create an account.  Keybase is the easiest way to create a secure PGP key, allowing secrets to be encrypted using your email as a reference to a public key.  Only devices authorised with your private key that have been authorised can decrypt secrets, and you can easily initialise new devices from your phone.  It is possible to use your own key if you don't wish to use keybase.
Terraform uses PGP encryption when creating new aws users with AWS Secret keys.  PGP encryption ensures that the shell output is not readable by anyone except someone authorised with the PGP key.  Terraform requires this ability to create users with permissions to automate a remote system to have access to S3 Cloud Storage. Those systems have ability to write, read and list contents of bucket storage, unlike the admin account whcih can do far more.  The difference is the admin account credentials should only reside on the ansible_control VM.

## Vagrant

Vagrant is a tool that manages your initial VM configuration onsite.  It allows us to create a consistent environment to launch our infrastructure from with Ruby files that define the VM.  We create two VMS, ``ansiblecontrol`` and ``firehawkgateway``.  Ansible control is where terraform and ansible provision outwards from.  It is where the secrets and keys need to reside.  Firehawk Gateway will be configured as a VPN gateway and it will have the deadline DB and Deadline Remote Connection Server (RCS).

- Install [Hashicorp Vagrant](https://www.vagrantup.com/) and Virtualbox on your system (Linux / Mac OS recommended)

## Replicate a Firehawk clone and manage your secrets repository

- Login to github and view the [template repository](https://github.com/firehawkvfx/firehawk-template)
- Select [Use This Template](https://github.com/firehawkvfx/firehawk-template/generate)
- Give it a name like ``firehawk-deploy``
- **Make sure the new repository is Private. WARNING: NOT DOING THIS IS A SECURITY RISK.**
- Clone this new private repository to your system / somewhere in your home dir.  This first deployment will be a dev test deployment.
  ```
  git clone --recurse-submodules -j8 https://github.com/{my user}/firehawk-deploy.git firehawk-deploy-dev
  ```
- Submodules are not inherited with templates.  Add the submodule
  ```
  cd firehawk-deploy-dev; git submodule add https://github.com/firehawkvfx/firehawk.git
  git submodule update --init --recursive
  ```

This provides a structure for your encrypted secrets and configuration, which exist outside of the firehawk submodule.  The firehawk submodule is a public submodule, and it can exist as a fork or a clone.  This allows the code to be shared will keeping configuration and secrets seperate.

All these steps allow us to configure a setup in the 'dev' environment to test before you can deploy in the 'prod' environment, in a seperate folder.
You will have two versions of your infrastructure, we make changes in dev branches and test them before merging and deploying to production.

- Download the latest deadline installer tar, and place the .tar file in the local firehawk/downloads folder.
- If you are on a Mac, install homebrew and ensure you have the command envsubst
```
brew install gettext
brew link --force gettext
```
- Now we will setup our environment variables from a template. If you have already done this before, you will probably want to keep your old secrets instead of copying in the template.
    cp secrets.template secrets/secrets-master
- First step before launching vagrant is to ensure an environment var is set with a random mac (you can generate it yourself with scripts/random_mac_unicast.sh) and store it as a variable in secrets/secrets-prod.  eg,
    TF_VAR_gateway_mac_prod=0023AE327C51
- Set the environment variables from the secrets file.  --init assumes an unencrypted file is being used.  We always must do this before running vagrant.
    source ./update_vars.sh --prod --init
- Get your router to assign/reserve a static ip using this same mac address so that the address doesn't change.  if it does, then render nodes won't find the manager.



## Side Effects API OAuth2 keys
If you intend to use Houdini, Firehawk uses Side FX provided keys to query and download the latest daily and produciton builds from sidefx.com. It will query the current version, download it, install it and also preserve that installer in S3 cloud storage enabling you to lock infrastructure to a particular installation version if needed.

- goto [Services](https://www.sidefx.com/services/), and accept the EULA
- Create a New App under [Manage applications authentication](https://www.sidefx.com/oauth2/applications/) to get a Client ID and secret keys.
- Save these these into your decrypted secrets file and encrypt it.





## Security

Security isn't a state that you should believe you have reached, but a process that requires continuous evaluation.  It also results from effort that should be proportional to the value that you represent as risk and effort vs reward to an attacker.  An AWS account is quite a prize, because it can be used to mine crypto or perform other compute on.  An attacker could also use it to do harm by accessing client Intellectual Property or racking up a large bill for you.  So the steps taken should be proportional to the value of the work you are performing, and as much should be done as reasonably possible.

The systems that use your VM's to provision with, shouldn't be exposed to bad website browsing patterns, or sitting exposed on the public internet (they should be behind a NAT gateway- normal for any system at home connected to the internet).  If possible, ensure those systems are on a different subnet to other devices you don't have control over on your network (Guest wifi, non work related systems).

Ideally, if you wanted to step up security further, there could be entirely seperate systems (bare metal) dedicated for the unique purpose of Firehawk provisioning and the VPN alone and not for general use.  We have taken steps to make sure that ansible and terraform provisioning occurs on a unique vm to where the VPN and Deadline DB reside.  We could go further and put each of those (Deadline and VPN) on their own seperate metal.  Bare metal for a single purpose is more secure than a VM because if a hypervisor is compromised everything else on that system can be compromised.

We should be as difficult a target as reasonably possible, and we should have means to deactivate a vulnerability if actively used by an attacker.

For example:
- If you were to accidentally publicly push secrets or become aware that somehow they became publicly visible, you would change / cycle every single one and change all passwords on your AWS account.
- If an attacker were to aquire control of the user secret key used to provision resources, you would want means to be able to delete that user account (via another user or as the root account), and you would probably need to be able to do that on an uncompromised system or phone possibly.

It's also important that your router firmware is kept up to date (consider a regular reminder). It is a significant potential vulnerability between you and AWS - your router.  Open VPN encrypts traffic before it goes through the router, but if the router is compromised, enough information to establish those credentials can be gained for a man in the middle attack.

We configure AWS to ignore all inbound communication to instances from anywhere but your own IP at the time of provisioning.  You may encounter difficulty without a static IP, although it is possible to update security groups with a change to your IP on each Terraform apply.  Your secret keys if aquired could be used by an attacker to alter resources.  Provided you have a Static IP, you can alter policies to [deny access from anywhere but your own static IP](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_deny-ip.html).




## Pointers on cost awareness:

Initially run small tests and get an understanding of costs that never use more than say 100GB of storage, and that can be produced on light 2 core instances.  Cost managment in AWS is not without effort, and you usually should allow a day before you can see a break down of what happenned (though its possible to implement more aggressive cost analysis with developement).

- EBS volumes cost money even if not mounted.  Check for any volumes you don't need and delete them.

- S3 is cloud storage that also costs money, review buckets and their contents.

- Check that any outstanding deadline jobs are paused, and spot requests have been terminated in the spot fleet tab.  If you simply terminate an instance, but there are remaining render tasks in deadline, a spot fleet request might just replace it again.  If you see any autoscaling groups, these should also be set to 0.

- Turn off nodes when not using them.  When I'm done using the resources, do this from withing the ansible_control vm-

```
terraform plan -out=plan -var sleep=true
```

- Check the plan to see that it is going to do what it should.  Then run:
 
```
terraform apply plan
```
- Alternatively, you can use these scripts outside the vm, with an argument to determine if Softnas volumes will be preserved or destroyed.  Destroying the volumes is appropriate if you store production data in a bucket or elsewhere.


```
cd firehawk; source ./update_vars.sh --prod --init; ./firehawk.sh --sleep --softnas-destroy-volumes true
```

- When you run these commands you can put all the infrastructure to sleep (including the NAT gateway), but you should always verify through the AWS console that this actually happenned, and that all nodes, and NAT gateway are off.  

- The NAT gateway is a cost visible in your AWS VPC console, usually around $5/day when infrastructure is active.  It allows your private network (systems in the private subnet) outbound access to the internet.  Security groups can lock down any internet access to the minimum adresses required for licencing - things like softnas or other software, but that is not handled currently.  Licensing configuration with most software you would use makes it possible to not need any NAT gateway but that is beyond the scope of Firehawk at this point in time.



## Running Vagrant and configuring with Ansible

- Run this to download an ubuntu base image and install ansible in the vm.  Provisioning the ubuntu desktop GUI may take 15mins +. in case you are resinstalling, you may want to tun 'vagrant box update'.
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
- If you already have an aws account, ensure you have secret keys setup in your secrets file so that the aws CLI will be installed correctly.
- Now we can execute the first playbook to initialise the vm.
    ansible-playbook -i ansible/inventory/hosts ansible/init.yaml -v
- Download the deadline linux installer version 10.0.23.4 (or latest version) into downloads/Deadline-10.0.23.4-linux-installers.tar, then setup the deadline user and deadline db + deadline rcs with this playbook. set the version in your secrets file.
    ansible-playbook -i ansible/inventory/hosts ansible/newuser_deadlineuser.yaml -v
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
- before we run terraform, exit the vm and reload to reboot
    exit
    source ./update_vars.sh --prod
    vagrant reload
    vagrant ssh
- you should also ensure you have set correct Amazon Machine Image ID's for your regions and for each instance.  eg we can query for Softnas like this-
    aws ec2 describe-images --region ap-southeast-2 --filters Name=is-public,Values=true Name=name,Values=SoftNAS* Name=description,Values='*Platinum - Consumption - 4.2.3*' --query 'Images[*].{ID:ImageId}'
- Now lets initialise terraform, and run our first terraform apply.  Read more about this here for best practice - Your first terraform apply
    terraform init
    terraform plan -out=plan
- if this is without errors, apply the plan.
    terraform apply plan
- The terraform apply openvpn module will have altered the network settings, so a reboot may be necesary for routes to work through your local network.
    exit
    vagrant reload
    vagrant ssh
    cd /vagrant
    source ./update-vars.sh --prod
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

If you ever make commits to a git repo, ensure you never commit unencrypted secrets in the secrets/ path.  vault keys and pem keys for ssh access are stored in keys/ and these should not be committed to version control.

if you happen to accidentally publish private information you can remove it with this example to remove the secrets-prod file form the repository.  ensure you have a local backup - this operation will strip all branches.
https://help.github.com/en/articles/removing-sensitive-data-from-a-repository

    git clone (my repo)
    cd (my repo)
    git filter-branch --force --index-filter \ 'git rm --cached --ignore-unmatch secrets/secrets-prod' \ --prune-empty --tag-name-filter cat -- --all

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

    terraform taint module.vpc.module.vpn.module.openvpn.aws_instance.openvpn

- Now I should also taint what is downstream if there are dependencies that aren't being picked up too, like the eip.

    terraform taint module.vpc.module.vpn.module.openvpn.aws_eip.openvpnip
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
