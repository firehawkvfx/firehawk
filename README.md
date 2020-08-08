# Open Firehawk

Open Firehawk is an environment to create an on demand render farm for VFX with infrastructure as code.  It uses Terraform to orchestrate resources, Ansible to configure resources, and Vagrant (with Virtualbox) as a VM container for these tools to run within.  A Linux or Mac OS host for the VM's is recommended at this time.  Terraform is able to interface with many cloud providers, current base implementation is with AWS.  It does use resources that have costs for their use, the types of resources chosen are based off the ones that were most cost effective for my use case. PR's for other resource options are welcome!

## Intro

We document steps you can follow for replication of Firehawk in another environment.

Some of this documentation will share what you will need to learn if you are a TD / Pipeline TD new to running cloud resources.  I'd recommend learning Terraform and Ansible.  I recommend passively putting these tutorials on without necesarily following the steps to just expose yourself to the concepts and get an overview.  Going through the steps yourself is even better.

These are some good paid video courses to try which I have taken on my own learning path-

### Pluralsight:

- Terraform - Getting Started
- Deep Dive - Terraform

### Udemy:

- Mastering Ansible
- Deploying to AWS with Ansible and Terraform - Linux Academy.

### Books:

- Terraform up and running.
- Ansible up and running.

## Disclaimer: Running your own AWS account.
You are going to be managing these resources from an AWS account and you are solely responsible for the costs incurred, and for your own education in managing these resources responsibly.  If new to AWS, tread slowly to understand AWS charges.  The information I provide here is not perfect, but shared in a best effort to help others get started.

## Requirements
- 2 aws accounts.
- NFS / NAS for sharing a file system. (Optional but recommended)
- An AWS Thinkbox account
- A houdini license server with 1 floating houdini engine license (Optional, it is possible to use Firehawk without Houdini)
- A system with at least 16 GB RAM and 8 threads to run up to 4 VM's. Linux or MacOS recommended.  Windows is untested but PR's encouraged.
- If intended for production 2+ seperate physical machines with 4 cores and 8 GB ram is recommended for a Green/Blue deployment (redundancy).
- A keybase account and app setup on your phone for PGP encryption

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

Firehawk automates creation of some user accounts, instances, images, VPN, NAS storage and others.  An AWS user with appropriate permissions to create all these resources must be manually created for this to be possible.
We will define the permissions for this new user (in each of the accounts).  Later we will generate secret keys that will be stored in an encrypted file to create resources with Terraform and Ansible that rely on these permissions.

- Goto Identity and Access Management (IAM)
- Create a new group ``StorageAdmin``
- Attach these policies to that group
```
AmazonS3FullAccess
AmazonFSxConsoleFullAccess
AmazonFSxFullAccess
```
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
- Create a new policy named ``ResourceGroupsAdmin``
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "resource-groups:*",
        "cloudformation:DescribeStacks",
        "cloudformation:ListStackResources",
        "tag:GetResources",
        "tag:TagResources",
        "tag:UntagResources",
        "tag:getTagKeys",
        "tag:getTagValues",
        "resource-explorer:*"
      ],
      "Resource": "*"
    }
  ]
}
```
You can read more about the above policy here https://docs.aws.amazon.com/ARG/latest/userguide/gettingstarted-prereqs.html
- Attach this policy to the ``DevAdmin`` group.
- Make the new user a member of both the ``StorageAdmin`` and ``DevAdmin`` groups to inherit all of these policies.
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

## Limits
In the AWS console for your dev and prod accounts, you will need to ensure the limits (Services/EC2/Limits) for any resources can be provided.  Request the following for each account:

Elastic IP Addresses: 8

If at any point a dpeloyment fails due to limits not being high enough you will need to request an increase for the relevent resource.


## Keybase / PGP Keys

Install Keybase on your phone or PC - head to keybase.io to create an account.  Keybase is the easiest way to create a secure PGP key, allowing secrets to be encrypted using your email as a reference to a public key.  Only devices authorised with your private key that have been authorised can decrypt secrets, and you can easily initialise new devices from your phone.  It is possible to use your own key if you don't wish to use keybase.
Terraform uses PGP encryption when creating new aws users with AWS Secret keys.  PGP encryption ensures that the shell output is not readable by anyone except someone authorised with the PGP key.  Terraform requires this ability to create users with permissions to automate a remote system to have access to S3 Cloud Storage. Those systems have ability to write, read and list contents of bucket storage, unlike the admin account whcih can do far more.  The difference is the admin account credentials should only reside on the ansible_control VM.

## Vagrant

Vagrant is a tool that manages your initial VM configuration onsite.  It allows us to create a consistent environment to launch our infrastructure from with Ruby files that define the VMs.  We create two VMs, ``ansiblecontrol`` and ``firehawkgateway``.  Ansible control is where terraform and ansible provision outwards from.  It is where the secrets and keys need to reside.  Firehawk Gateway will be configured as a VPN gateway and it will have the deadline DB and Deadline Remote Connection Server (RCS).

- Install [Hashicorp Vagrant](https://www.vagrantup.com/) and Virtualbox on your system (Linux / Mac OS recommended). Mac OS users may choose to use the homebrew package mager to do this.

## 3 Seperate Resource files for Green / Blue Deployment
There are a minimum of 3 virtual resources that we deploy to.  Grey (Dev environment) resources are for testing.  Any deployment we use in production will use either Green or Blue resources.  This allows us to deploy an update to the Green or Blue environemnt using those resources, what ever is not currently in use.  This can allow us to test and fallback if the update is not ready for production.

- The dev environment will be tested on the resources specified in the resources-grey file.
- resources-blue and resources-green files are used for production.

Currently the green blue deployment method being implemented will replace configuration on a workstation as each color is deployed.  We still need to implement Rez to be able to switch a users workstation / render nodes between these environments. The primary benefit of where this implementation is now is the reduced downtime that could be assciated with a failed deployment is much better than not having the current system.  The changes that need to be managed on a workstation are what software version you might be using for houdini, and what Deadline RCS host is being used for the monitor.

## Vagrant workstation for the dev environment

When doing test deployments, we can use seperate VM's from production systems to test on.  This Vagrant VM to test a workstation creates a CentOS 7 VM with a Gnome GUI.  Even if you want to experiment with another OS for your workstation, it is recommended that you use a Centos machine/VM to test and diagnose problems.  To isolate your workstation from testing, it is recommended that you use this VM here to simulate an isolated a workstation in a dev environment.  This protects your actual workstation from testing failed deplopyments that would affect productivity.  In the production environment, you would replace any IP adresses and ssh keys / passwords with those used for your actual workstation in the resources-green and resources-blue files.  Alternatively you can allow password login and the authorization will be handled automatically with ssh keys.  After this, password use for ssh login is disabled for security reasons.

- [Clone this repository to a seperate folder](https://github.com/queglay/vagrant-centos-gui) to create a workstation VM to test deployments in a dev environment
```
Vagrant up
```
- Once the UI is up configure a new user name (user) and password, this will be used to bootstrap another user for automation later.
```
sudo useradd user # Add a new user.  This should be the same as an initial user that must exist on your actual workstation.
sudo passwd user # Set a password, it should be the same as for the user on your workstation.
usermod -aG wheel user # Give user sudo privelidges
sudo vi /etc/ssh/sshd_config # Find the line PasswordAuthentication no, and change it to yes
sudo systemctl restart sshd.service # Restart the ssh service
ip a # Find the IP adress for this system on your network (usually 192.168.? )
```
- Ensure you can ssh into the VM with this information from your network on another machine.
```
ssh user@machine_ip # where machine_ip is the IP address found above
```
- Ensure you have sudo access
```
sudo touch ./test
sudo rm ./test
```

- If you are using an existing machine that has password access disabled, you should also enable password access in /etc/sshd_config

This login information should be entered into your encrypted secrets file in later steps, and is only temporarily used until the login is replaced with an ssh key for the deployuser (which will also be created automatically).  Once the ssh key is configured by Firehawk the password wont be usable for ssh access anymore.  Passwords are not recommend to be allowed for continued SSH access in a firehawk deployment.

## Thinkbox Usage Based Licensing
To use Deadline in AWS, instances that reside in AWS are free.  But any onsite systems that render will require a licence.  If you wish to use any other UBL licenses (eg houdini Engine) they will also 
require your Thinkbox UBL URL and UBL activation code.  These are entered in your encrypted secrets file, and are used to configure the Deadline DB upon install automatically.

## License servers
License servers should be configured on your network to issue any floating licenses for software you require.  The VPN gateway and routes configured should allow a cloud based system to access the license server at the environment variable ``TF_VAR_houdini_license_server_address`` in secrets/config.  It should also be possible to use deadline Usage Based Licenses for render nodes to use licenses on a per hour basis (eg. Houdini Engine, Mantra), but this is untested.  

- To disable the floating license server, after you have setup your configuration files, but before deployment you can follow these steps:
```
source ./update_vars.sh --dev # or with your desired env.
./scripts/ci-set-disable-license-server.sh
source ./update_vars.sh --dev # or with your desired env.
```

## Side Effects API OAuth2 keys
If you intend to use Houdini, Firehawk uses Side FX provided keys to query and download the latest daily and produciton builds from sidefx.com. It will query the current version, download it, install it and also preserve that installer in S3 cloud storage enabling you to lock infrastructure to a particular installation version if needed.

- Goto [Services](https://www.sidefx.com/services/), and accept the EULA
- Create a New App under [Manage applications authentication](https://www.sidefx.com/oauth2/applications/) to get a Client ID and secret keys.
- You will need these later to save into your decrypted secrets file and encrypt it.

## Disabling Side Effects Houdini
If you wish to use the infrastructure without Houdini and experiment with other software, you can disable these vars in config overrides.  After you have setup your configuration files, but before deployment you can follow these steps:
```
source ./update_vars.sh --dev # or with your desired env.
./scripts/ci-set-no-houdini.sh
source ./update_vars.sh --dev # or with your desired env.
```

## NFS Shared Volumes
An NFS shared volume in the location of your workstation is highly recommended, and not having one is an untested configuration if you intend to use Side FX PDG.
this is because PDG updates a lot of ephemeral data on the filesystem that all systems need access to.  Sharing SMB may also be possible with further developement and testing.
It may also be possible to avoid an onsite NFS share by only using the Cloud NFS share that would also be available on your local system.
If you wish to test without any onsite shared volume, you will need to rely on your own processes to synchronise with S3 storage, or use the cloud based NFS share.  To do this, after you have setup your configuration files, but before deployment you can follow these steps:
```
source ./update_vars.sh --dev # or with your desired env.
./scripts/ci-set-no-nfs-share.sh
source ./update_vars.sh --dev # or with your desired env.
```
This will alter the config-overrides to not use an onsite NFS Share.

IMPORTANT: If you use an onsite NAS / NFS share you wish to use, static routes must be configured on your router so that device has the means to see your cloud network ranges.  Without a static route, it is not possible to send traffic to your cloud based nodes that might read data from these volumes.

## Static Routes

Unfortunately, everyone's router onsite is different so this is one part of the setup that we can't automate for you!  We will describe the extent to which you should have to configure static routes on your network here, and you only have to do it once thankfully!  Similar routes are configured for the cloud site subnets and VPN, but that is all automated with Terraform and Ansible.

Static routes define how traffic moves, and what host any traffic has to go through.  With a VPN gateway for our network to communicate with a remote network, we need to specify the address ranges of the remote networks (subnets), and we need to say what host / IP that traffic needs to go through in order to get there.  So in our case that is a VPN tunnel.  We are interested in ensuring that any of our traffic going to address ranges are being sent through the correct VPN tunnel for that deployment resource (Blue / Green / Grey)

Any static route has two parameters defined for it to work:
- The network / subnet range of addresses that we want to set the routes for traffic destined to these locations.
- The IP address or host that any traffic going to the above address range must travel through.

If you are using only one system, and you are not using an NFS share / NAS / or any license server, you don't need to have static routes configured on your router.  Otherwise for those other mentioned scenarios, without a static route, your NAS or licesne server for example wont know how to return any information back to the host on the other network that requires it!

To set this up, you will have specified a new MAC address for the Firehawk VPN Gateway in each resource file (Blue/Green/Grey), each MAC must be unique and can be generated by scripts/random_mac_unicast.sh.  On your router, you should ensure that each of these hosts defined by the MAC addresses will have a static IP address:
- You can usually do that by specifying the MAC address of the host (defined in the secrets/resource file) on your router, and setting the ip you wish to reserve.  Some routers might require the host be up before you can set a static IP. In that case, you can reserve the static IP at the first opportunity and reload the Firehawk Gateway VM to check it actually aquired this address before you deploy any cloud resources.  If in doubt, destroy the VM and start over.  It should aquire the address correctly.

Once you can ensure that these VM's are going to have a static IP, we can specify the routes to those IP's.  In a default deployment, on the router, we would setup these routes:
- 10.1.0.0/16	sends traffic to 192.168.92.10.  It means traffic destined for the range 10.1.0.0 - 10.1.255.255 will go via 192.168.92.10 ( The /16 suffix is CIDR notation to specify a range of adresses)
- 10.2.0.0/16	sends traffic to 192.168.92.20.  It means traffic destined for the range 10.2.0.0 - 10.2.255.255 will go via 192.168.92.20
- 10.3.0.0/16	sends traffic to 192.168.92.30.  It means traffic destined for the range 10.3.0.0 - 10.3.255.255 will go via 192.168.92.30

We also have these routes in a default configuration:
- 172.17.232.0/24	sends traffic to 192.168.92.10
- 172.18.232.0/24	sends traffic to 192.168.92.20
- 172.19.232.0/24	sends traffic to 192.168.92.30

These address ranges refer to the DHCP addresses that Open VPN will automaticaly generate for its own use with the encrypted tunnel.  Each source / destination address will get one of these DHCP addreses to use for the encrypted traffic through the VPN tunnel between sites.

## FSX for Lustre

With the 0.1 release we are now using a FSx for Lustre storage solution as our default remote file system in place of SoftNAS.  FSx for Lustre has some interesting ablities:

- An S3 bucket's objects are visible through to the file system directory structure.  These objects are seamlessly streamed on demand when read.  The file system will only consume space when these objects are read or manually requested from S3.
- Anything written to the filesystem like render output or simulation can be offloaded back to S3 storage.  This is the most cost efficient means of storing data, since it does not need to be over provisioned (unlike a disk/ebs volume)
- The S3 bucket doesn't use any vendor lockin specific formatting, keeping it available for other purposes if required.
- Cluster based storage like FSx is more conducive to scaling and maintaining performance with redundancy.
- Can scale in 1.2-2.4 TB increments, scaling the throughput with size linearly.
- Persistent mode is self healing and able to replace node failures automatically (scratch is the default, self healing disabled)
- Initial tests are cost efficient.  The file system can also be disabled safely when not in use- provided objects are written back to cloud storage.
- This allows users to save on cost, and more easily persist their data even after infrastructure is destroyed.

In order for this to function on any workstations/onsite nodes, you must have the AWS lustre client installed, and you should reboot after installing any lustre packages for them to work.
https://docs.aws.amazon.com/fsx/latest/LustreGuide/install-lustre-client.html

If you have problems mounting FSx for lustre to your workstation's linux OS, it is likely that the system has not been rebooted or the packages were not installed correctly.  If this has been done, ensure the VPN is up and that you can ping another hosts private IP (like the VPN private IP or preferrably the render node instance used to build an AMI).

If you intend to directly mount cloud storage to Mac OS, you should opt to use Softnas in your variables and config in place of FSx.  It is possible for FSx for Windows to be mounted to a Mac but it this is currently untested and not provisioned automatically at this stage.

## Replicate a Firehawk clone and manage your secrets repository

- Clone this repository to your system / somewhere in your home dir.  This first deployment will be a dev test deployment.
  ```
  git clone https://github.com/firehawkvfx/firehawk-template.git firehawk-deploy-dev; cd firehawk-deploy-dev; ./firehawk-clone.sh master
  ```
The repository is built from a template.  This new repo you have made contains a secrets folder that is not part of the public repository, and a submodule that is a clone of the public repository.

- Optional: You may wish to push to another private repository which you can create on github. **Make sure this Github repository is Private** 

**WARNING: NOT MAKING THE REMOTE REPOSITORY PRIVATE IS A SECURITY RISK.**

This provides a structure for your encrypted secrets and configuration, which exist outside of the firehawk submodule.  The firehawk submodule is public, and it can exist as a fork or a clone.  This allows the code to be shared while keeping configuration and secrets seperate.

## Configuration

These steps allow us to configure a setup in the 'dev' environment to test before you can deploy in the 'prod' environment, in a seperate folder.
You will have two versions of your infrastructure, we make changes in dev branches and test them before merging and deploying to production.

- Download the right version of the AWS Deadline Installer tar.  Use the version specified in ``firehawk/config/defaults/defaults`` for the variable ``$TF_VAR_deadline_version``
- Place the .tar file in firehawk/downloads.  Do not test later versions of deadline until you have a stable deployment that is working.
- If you are on Mac OS, install homebrew and ensure you have the commands ``envsubst`` and ``ts``
  ```
  brew install gettext
  brew link --force gettext
  brew install moreutils
  ```
- We will need 4 random mac adresses, 2 for dev and 2 for production.  Keep them somewhere temporarily for us to copy into the vagrant config later.
  ```
  for i in {1..4}; do ./scripts/random_mac_unicast.sh; done
  ```
- Now we will setup our environment variables with templates. If you have already done this before, you will probably want to keep your old secrets instead of initalising the template.  Otherwise, continue with the setup script.
  ```
  cd firehawk
  ./scripts/setup.sh
  ```
- Select 'Configure Vagrant'.
- Either proceed to setup each variable step by step or use an external editor on ``firehawk-deploy-dev/secrets/vagrant``
- Continue to configure all the files EXCEPT secrets (This will be done later in the VM).
- When asked about the 4 mac adresses, copy in the 4 entries generated earlier.
- Source the environment variables from the vagrant config file for the dev environment.  --init assumes an unencrypted file is being used.  We always do this before running vagrant.
  ```
  source ./update_vars.sh --dev --init
  vagrant up
  ```
- You may be asked which adaptor to bridge to if you didn't configure this correctly during setup. Select the primary adapter for your internet connection.  This should be in the 192.168.x.x range.  You can also copy the exact text of this adaptor and place it in the /secrets/vagrant config file eg: ``TF_VAR_bridgenic=en0: Wi-Fi (AirPort)``

- Get your router to assign/reserve a static ip using this same mac address so that the address doesn't change.  if it does, then render nodes won't find the manager.

- From the vm, configure secrets.
  ```
  vagrant ssh
  ./scripts/setup.sh
  ```
- Select 'Configure Secrets'.
- You always have the option to setup each variable step by step or use an external editor on ``firehawk-deploy-dev/secrets/secrets-general``, or any other config file.  You can decrypt the secrets file for editing with ``source ./update_vars.sh --dev --decrypt``. When done do not forget to encrypt the file again ``source ./update_vars.sh --dev``.
- Later you may wish to copy and manually edit any --dev resource files (eg resource-grey ) for --prod (resource-green/ble) when the time comes to run a prod environment.

**WARNING: Never commit unencrypted secrets into a repository.** You can also [read here](https://help.github.com/en/articles/removing-sensitive-data-from-a-repository) to remove data from a repository.

- Ensure the secrets file is encrypted by sourcing the env vars.
  ```
  source ./update_vars.sh --dev
  ```
- Use ``exit`` to get out of the VM
- Take a snapshot of the vagrant vm.  This will not include anything in the shared firehawk or secrets folder.
  ```
  vagrant snapshot push
  vagrant snapshot list
  ```

- IMPORTANT: if you ever need to restore the snapshot, be sure to use the --no-delete option, otherwise the snapshot will be deleted.  Try restoring a snapshot now-
  ```
  vagrant snapshot pop --no-delete
  vagrant snapshot list
  ```
  Note that the original snapshot is still in the list.

## Deployment
Once configured and environment vars are sourced, a deployment can run with one command - ``firehawk.sh``  
For the first run though we will proceed in stages to ensure you have working configuration files.  Each stage depends on the previous being verified to function.
- Local Deployment (Local onsite resources and a cloud storage bucket are used)
- Deploy VPN ( AWS EC2 instances: 1 bastion ssh jump box, and 1 access server with Open VPN )
- Deploy all Infrastructure

- We will test configure a local deployment before we use cloud resources.  This will still create an AWS user and s3 bucket to store software installations.  If you need to ensure [houdini is not installed](#disabling-side-effects-houdini), [you don't have an NFS share](#nfs-shared-volumes), or a [houdini license server](#license-servers), you may also want to run those scripts and disable the relevent variables to ensure they are not used.
  ```
  source ./update_vars.sh --dev --init
  ./scripts/ci-set-init-local-deploy.sh # Set config overrides to prevent cloud deployment.  Only local tests run for this job.
  # Run any other custom scripts to alter funcitonality here. 
  source ./update_vars.sh --dev --init # env vars have changed, so we source again
  ./firehawk.sh
  ```
- Once the local deployment test runs successfully you may want to test destroying the [terraform resource, and destroying the VM's](#destroying-the-deployment) to get familiar with that process, though its not required.

- The next stage of the deployment we will test a vpn.
  ```
  source ./update_vars.sh --dev --init
  ./scripts/ci-set-deploy-cloud-vpn.sh
  # Run any other custom scripts to alter funcitonality here. 
  source ./update_vars.sh --dev --init # env vars have changed, so we source again
  ./firehawk.sh
  ```
  You should be able to ping the VPN from within the Firehawk VM, and from the dev workstation vm.  If not, check that you have configured [static routes](#static-routes) correctly.  Don't proceed until this is verified.  When you no longer want to use the resource you should put the resources to sleep, or if there a problem preventing this step from succeeding you will need to destroy the deployment when you are finished to not incur unwanted costs.

- Once the VPN connection works, we can test deploy all the cloud resources.  if you ran any cusotm scripts to disable functions, you should run them again after ci-set-deploy-cloud.sh
  ```
  source ./update_vars.sh --dev --init
  ./scripts/ci-set-deploy-cloud.sh # set config overrides to allow deployment
  source ./update_vars.sh --dev --init
  ./firehawk.sh --softnas-destroy-volumes true
  ```

- While your Infrastructure is up, you should be able to select the deadlineuser in the dev workstaion / VM, and login with a password. Open a terminal in the VM GUI, logged in as deadlineuser and run:
  ```
  deadlinemonitor
  ```
- IMPORTANT: After you start to render with more than 2 non AWS render nodes visible here in the monitor, those nodes will need deadline licenses.  They can be purchased from Thinkbox yearly, or you need to purchase UBL credits (hourly).  AWS nodes are free.  They aquire their free Deadline license information via a deadline role attached to the instance.
- For Deadline UBL licesnses (also can be used with other software), Firehawk will configure your UBL info to use with the deadline monitor.  See deadline docs on how to do this manually as well if required.

## Saving costs with sleep
When we deploy to cloud above, we specify if we want to keep the Storage EBS volumes or not.  Specify this to be explicit with what you want to happen to those volumes when you put the deployment to sleep.
- Once succesful, put the deployment to sleep to save costs.
  ```
  source ./update_vars.sh --dev --init
  ./firehawk.sh --sleep --softnas-destroy-volumes true
  ```
- Wake the deployment when you wish to use it again.  If the volumes exist, they will be mounted, or they will be recreated.
  ```
  source ./update_vars.sh  --init
  ./firehawk.sh --softnas-destroy-volumes true
  ```

## Diagnosing problems
Provided the Vagrant VM's are running and initialised (terraform is installed and available), when diagnosing problems it may be useful to avoid using firehawk.sh (which runs outside the vm).  Instead you can try running commmands with the ansiblecontrol vm.
- Operate within the ansiblecontrol vm with 
  ```
  source ./update_vars.sh --dev --init
  vagrant ssh
  ```
- run terraform operations after env vars are sourced with secrets.
  ```
  source ./update_vars.sh --dev # You will be asked for your password
  terraform apply --auto-approve
  ```

Note: All commands are designed to be run relative to the firehawk directory (or if in a vm, ``/deployuser``).  you should generally change to this directory, and source env vars before running any other scripts.

## Destroying the deployment
- The terraform deployment can be destroyed, leaving no resources or users in the AWS account.  You can do this when the deployment is no longer needed at all, or if you have only succesfully partially deployed.  It is important to destroy infrastructure before destroying the Vagrant VM.  If at any point a vm or config is unrecoverable, you can either try to reuse the terraform state file or you may wish to destroy and start over.  If you are unsuccesful, you may need to destroy all the resource manually to prevent unwanted costs from orphaned resources.
  ```
  source ./update_vars.sh --init
  ./firehawk.sh --destroy --softnas-destroy-volumes true
  ```
- Alternatively, you may wish to use terraform directly.
  ```
  source ./update_vars.sh --init
  vagrant ssh
  source ./update_vars.sh --dev # you will be asked for your password to your encrypted secrets file
  terraform destroy --auto-approve
  exit
  ```
- After the cloud resources are removed, you can safely destroy the vagrant VM.  do not do this unless you are sure the resources are gone.  otherwise you will have to delete all those resources manually through the console.
  ```
  source ./update_vars.sh --dev --init
  ./scripts/vagrant-destroy.sh
  ```

## Destroying resources manually
In your AWS console you should check regularly for any resources that are running that shouldn't be.  If you need to destroy resources manually here are particular area to pay attention to-
- EC2 Instances
- EBS Volumes
- S3 Buckets
- ENIs (Elastic Network Interfaces)
- VPC's

Also observe your daily cost graphs to identify any resources you may not have caught.

## Production

- Once your dev environment is functioning, you should create a dev branch to track that environment.
- You can clone your private repository to another new directory to repeat the steps for a deployment you want to use in production.  
- You should do this on another branch 'prod'
- You will need to copy the secrets/keys folder from the dev deployment into the new prod deployment since these are not stored in the repository.

## Security

Security isn't a state that you should believe you have reached, but a process that requires continuous evaluation.  It also results from effort that should be proportional to the value that you represent as risk and effort vs reward to an attacker.  An AWS account is quite a prize, because it can be used to mine crypto or perform other compute on.  An attacker could also use it to do harm by accessing client Intellectual Property or racking up a large bill for you.  So the steps taken should be proportional to the value of the work you are performing, and as much should be done as reasonably possible.  If you observe a security concern, contact andrew@firehawkvfx.com.

The hosts your VM's reside on, shouldn't be exposed to website browsing patterns from other users, or sitting exposed on the public internet (they should be behind a NAT gateway- normal for any system at home connected to the internet).  If possible, ensure those systems are on a different subnet to other devices you don't have control over on your network (Guest wifi, non work related systems).

Ideally, if you wanted to step up security further, there could be entirely seperate systems (bare metal) dedicated for the unique purpose of Firehawk provisioning and the VPN.  
When not for shared use this is a good step to take.  You can also disable SSH access to the host running Ansible on bare metal for further protection.  We have taken steps to make sure that ansible and terraform provisioning occurs on a unique vm to where the VPN and Deadline DB reside.  We could go further and put each of those (Deadline and VPN) on their own seperate metal.  Bare metal for a single purpose is more secure than a VM because if a hypervisor is compromised everything else on that system can be compromised.

We should be as difficult a target as reasonably possible, and we should have means to deactivate a vulnerability that might be actively used by an attacker.

For example:
- If you were to accidentally publicly push secrets or become aware that somehow they became publicly visible, you would change / cycle every single one and change all passwords on your AWS account.
- If an attacker were to aquire control of the user secret key used to provision resources, you would want means to be able to delete that user account (via another user or as the root AWS account), and you would probably need to be able to do that on another uncompromised system.

It's also important that your router firmware is kept up to date (consider a regular reminder). It is a significant potential vulnerability between you and AWS - your router.  Open VPN encrypts traffic before it goes through the router, but if the router is compromised, enough information to establish those credentials can be gained for a man in the middle attack.

We configure AWS to ignore all inbound communication for SSH or other ports to instances from anywhere but your own IP at the time of provisioning.  You may encounter difficulty without a static IP, although it is possible to update security groups with a change to your IP on each Terraform apply.  Your secret keys if aquired could be used by an attacker to alter resources.  Provided you have a Static IP, you can alter policies for your AWS remote access account to [deny access from anywhere but your own static IP](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_deny-ip.html).

## Pointers on cost awareness:

Initially run small tests and get an understanding of costs that never use more than say 100GB of storage, and that can be produced on light 2 core instances.  Cost managment in AWS is not without effort, and you usually should allow a day before you can see a break down of what happenned (though its possible to implement more aggressive cost analysis with developement).

- EBS volumes cost money even if not mounted.  Check for any volumes you don't need and delete them.  

- Decide if volumes need to persist with sleep. See [Saving costs with sleep](#saving-costs-with-sleep)

- Consider using an S3 bucket to synchronise data as much as possible for production.

- Review S3 cloud storage buckets and their contents to eliminate cost.

- Check that any outstanding deadline jobs are paused, and spot requests have been terminated in the spot fleet tab.  If you simply terminate an instance, but there are remaining render tasks in deadline, a spot fleet request might just replace it again.  If you see any autoscaling groups, these should also be set to 0.

- Turn off nodes (or destroy the deployment if necesary) when not using the resources.  See [Saving costs with sleep](#saving-costs-with-sleep)

- When you run commands to sleep, you should always verify through the AWS console that this actually happened, and that all nodes, and NAT gateway are off.  Check again in a day to ensure nothing wasn't caught.

- The NAT gateway is a cost visible in your AWS VPC console, usually around $5/day when infrastructure is active.  It allows your private network (systems in the private subnet) outbound access to the internet.  Security groups can lock down any internet access to the minimum adresses required for licencing - things like softnas or other software, but that is not handled currently.  Licensing configuration with most software you would use makes it possible to not need any NAT gateway but that is beyond the scope of Firehawk at this point in time.

## Remote Workstation

Work In Progress: Not currently a heavily tested feature, but a remote Teradici PCOIP workstation can be done!
You should ensure your static routes are configured correctly on your router.  Alternatively for a quick test, you can also add the routes manually to the system to intend to connect from.  Adding static routes varies between operating systems, but for example on Mac OS

- Only do this step if you haven't added static routes on your router, and the system running Teradici PCOIP cannot ping the VPN server yet.  On a Mac:
``` 
sudo route add 10.1.1.0/24 192.168.92.55 # Add a route to the private subnet via whatever IP your firehawk gateway has on your network. 
sudo route add 10.1.101.0/24 192.168.92.55 # Add a route to the public subnet
sudo route add 172.17.232.0/24 192.168.92.55 # Add a route to the DHCP range the Firehawk Gateway is using for open vpn.  This can be found also by logging into the firehawk gateway or ansible control if verified to be connected through the vpn and running ``ip route list``
```

- Make sure you can ping the remote VPN Access server through its private IP.
```
ping 10.1.101.56
PING 10.1.101.56 (10.1.101.56): 56 data bytes
64 bytes from 10.1.101.56: icmp_seq=0 ttl=63 time=31.469 ms
64 bytes from 10.1.101.56: icmp_seq=1 ttl=63 time=30.117 ms
64 bytes from 10.1.101.56: icmp_seq=2 ttl=63 time=29.702 ms
```
A 30 ms round trip here is a decent amount of latency to run Teradici PCOIP. over 45ms starts to not be great.  16-24 Mbit download rates are recommended for a good experience at acceptable resolutions.

- Enable the environment variable to deploy the workstation.
```
source ./update_vars.sh --dev --init
./scripts/ci-set-deploy-enable-remote-workstation.sh
```
- Log in to the vm and run teraforma apply
```
source ./update_vars.sh --dev --init
vagrant ssh
source ./update_vars.sh --dev
terraform apply --auto-approve
```
This will take some time to provision the remote workstation.  

- Once up, ping the workstation ip from the system you intend to run PCOIP from and you should be able to run the PCOIP application and connect to the host with the password you specified in the encrypted /secrets/secrets-general file.

## How To Create a Hosted Zone

If you want to be able to access your vpn and other resources through a domain like the vpn, eg vpn.example.com you can create a public hosted zone in Route53.  Since this will be a permanent part of your infrastructure you will need to do this manually. You can either transfer an existing domain to aws (not recommended for dev if you are using this domain in production, best to place that in the production account!) or you can purchase a new domain of some random name with a cheap extension (doesn't need to be .com, there are plenty of cheap alternatives)

## Replacing resources with Terraform - taint

If you make changes to your infrastructure that you want to recover from, a simple way to replace resources is destroying them with something like this...
- First find the resource you want to destroy:
  ```
  terraform state list
  ```
- Taint the resource you want to replace.
  ```
  terraform taint module.vpc.module.vpn.module.openvpn.aws_instance.openvpn
  ```

- Now I should also taint what is downstream if there are dependencies that aren't being picked up too, like the eip.

  ```
  terraform taint module.vpc.module.vpn.module.openvpn.aws_eip.openvpnip
  The resource aws_eip.openvpnip in the module root.vpc.vpn.openvpn has been marked as tainted!
  ```
  
- After I'm happy with this I can run terraform apply to recreate any missing resources to match the desired state.
  ```
  terraform plan -out=plan
  terraform apply plan
  ```

- When this is done, for the vpn, check the logs for the connection being initialised
    sudo cat /var/log/syslog
- You should see a line toward the end with
  ```
  openfirehawkserver ovpn-openvpn[21984]: Initialization Sequence Completed
  ```

- Validate this by pinging an existing IP in the private subnet
  ```
  ping 10.0.1.11
  ```

## S3 Bucket Cloud Storage size

You can keep tabs on an S3 bucket's size with this command, 
```
aws s3 ls s3://bucket_name --recursive  | grep -v -E "(Bucket: |Prefix: |LastWriteTime|^$|--)" | awk 'BEGIN {total=0}{total+=$3}END{print total/1024/1024" MB"}'
```

<!--stackedit_data:
eyJoaXN0b3J5IjpbLTEyNzAwNzg1NjUsMTkzMzQ5NTI3MCwxNz
ExNzUxMTEsOTU5NjMzNDQzLC0xMTU5MjY5MzYwLC0xNzMwNTc1
MzU0LC0xNTAxNTY2OTMsLTM2Njk0ODcwLDY1OTA4OTA5NCw1ND
g5ODM2OTYsLTc5NDU5MjA1LDUwODUzMDQ4MSw3MDgxNzYyOV19

-->
