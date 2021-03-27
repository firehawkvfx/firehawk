# Firehawk

Firehawk is a work in progress for VFX rendering infrastructure, using multi-cloud capable and open source tooling where possible.

It uses AWS Cloud 9 as a seed instance to simplify launching the infrastructure.  The scheduler implemented presently is Deadline - it provides Usage Based Licenses for many types of software to provide access for artists at low cost and free to use the scheduler on AWS instances.  It is possible to build images to support other schedulers.

The primary reason for this project's creation is to provide low cost high powered cloud capability for Side FX Houdini users, and to provde a pathway for artists to roll their own cloud with any software they choose.

Firehawk uses these multi cloud capable techologies:
Hashicorp Vault - for dynamic secrets management, and authentication
Hashicorp Terraform - for orchestration
Hashicorp Consul - for DNS / service discovery
Hashicorp Vagrant - for client side Open VPN deployment
OpenVPN - for a private gateway between the client network and cloud.
Redhat Ansible - For consistent provisioning in some packer templates (Multi cloud capable)
Redhat Centos
Canonical Ubuntu

Current implementation uses AWS.

# Backers
Please see [BACKERS.md](https://github.com/firehawkvfx/firehawk/blob/main/BACKERS.md) for a list of generous backers that have made this project possible!

I want to extend my deep gratitude to the support provided by:
- Side FX for providing licenses enabling this project
- AWS for contributing cloud resources.

I also want to take a moment to thank Andrew Paxson who has contributed his knowledge to the project.

And especially to the other companies providing the open source technologies that make this project possible:
Hashicorp, OpenVPN, Redhat, Canonical

# Firehawk-Main
The Firehawk Main VPC (WIP) deploys Hashicorp Vault into a private VPC with auto unsealing.

This deployment uses Cloud 9 to simplify management of AWS Secret Keys.  You will need to create a custom profile to allow the cloud 9 instance permission to create these resources with Terraform.  

## Policies

- In cloudformation run these templates to init policies and defaults:
  - modules/cloudformation-cloud9-vault-iam/cloudformation_devadmin_policies.yaml
  - modules/cloudformation-cloud9-vault-iam/cloudformation_cloud9_policies.yaml
  - modules/cloudformation-cloud9-vault-iam/cloudformation_ssm_parameters_firehawk.yaml

## Creating The Cloud9 Environment

- In AWS Management Console | Cloud9: Select Create Environment

- Ensure you have selected:
`Create a new no-ingress EC2 instance for environment (access via Systems Manager)`
This will create a Cloud 9 instance with no inbound access.

- Ensure the EBS volume size is 20GB.  If you need to expand the volume more later you can use firehawk-main/scripts/resize.sh

- Ensure the instance type is the recommended type for production (m5.large)

- Ensure you add tags:
```
resourcetier=main
```
The tag will define the environment in the shell.

- Once up, in AWS Management Console | EC2 : Select the instance, and change the instance profile to your `Cloud9CustomAdminRoleFirehawk`

- Ensure you can connect to the IDE through AWS Management Console | Cloud9.

- Once connected, disable "AWS Managed Temporary Credentials" ( Select the Cloud9 Icon in the top left | AWS Settings )
Your instance should now have permission to create and destroy any resource with Terraform.

## Create the Hashicorp Vault deployment

- Clone the repo, and install required binaries and packages.
```
git clone --recurse-submodules -j 8 https://github.com/firehawkvfx/firehawk-main.git
cd firehawk-main; ./install_packages.sh
```

- Initialise the environment variables to spin up the resources.
```
source ./update_vars.sh
```

- Initialise required SSH Keys, KMS Keys, certificates and S3 Buckets. Note: it is important you are mindful if you run destroy in init/ as this will destroy the SSL Certificates used in images required to establish connections with Vault and Consul.
```
cd init
terragrunt run-all apply
```

- Install Consul and Vault client
```
cd modules/vault
./install-consul-vault-client --vault-module-version v0.13.11  --vault-version 1.5.5 --consul-module-version v0.8.0 --consul-version 1.8.4 --build amazonlinux2 --cert-file-path /home/ec2-user/.ssh/tls/ca.crt.pem
```

## Build images

For each client instance we build a base AMI to run os updates (you only need to do this infrequently).  Then we build the complete AMI from the base AMI to speed up subsequent builds (and provide a better foundation from ever changing software updates).

- Build Base AMI's
```
source ./update_vars.sh
cd deploy/packer-firehawk-amis
source ./packer_vars.sh
cd modules/firehawk-base-ami
./build.sh
```

- When this is complete you can build the final AMI's which will use the base AMI's
```
cd modules/firehawk-ami
./build.sh
```

- Check that you have images for the bastion, vault client, and vpn server in you AWS Management Console | Ami's.  If any are missing you may wish to try running the contents of the script manually.

Note: The images here are built without a vault cluster, but there will be no verification of Consul DNS resolution. If you wish to test DNS during the image build and your vault cluster is already running, run these steps after vault is up and run:
```
export PKR_VAR_test_consul=true
```

## Vault Deployment


- Source vars again to pickup the AMI ID's
```
source ./update_vars.sh
```

- Deploy Vault
```
cd $TF_VAR_firehawk_path
terragrunt run-all apply
```

- Initialise the vault:
```
ssh ubuntu@(Vault Private IP)
export VAULT_ADDR=https://127.0.0.1:8200
vault operator init -recovery-shares=1 -recovery-threshold=1
vault login (Root Token)
```

- Store all sensitive output in an encrypted password manager for later use.

- exit the vault instance, and ensure you are joined to the consul cluster in the cloud9 instance.
```
sudo /opt/consul/bin/run-consul --client --cluster-tag-key "$${consul_cluster_tag_key}" --cluster-tag-value "$${consul_cluster_tag_value}"
consul catalog services
```
This should show 2 services: consul and vault.

- login to vault on your current instance (using the root token when prompted).  This is the first and only time you will use your root token:
```
vault login
```

- Configure vault with firehawk defaults.
```
cd modules/vault-configuration
./generate-plan-init
terraform apply "tfplan"
```
- Now you can create an admin token.  include any other policies you may need to create tokens for.
```
vault token create -policy=admins -policy=vpn_read_config -explicit-max-ttl=720h
```

- And login with the new admin token.
```
vault login
```

- Now ensure updates to the vault config will work with your admin token. 
```
terraform apply "tfplan"
./generate-plan
terraform apply "tfplan"
```

Congratulations!  You now have a fully configured vault.

## You should be able to continue to deploy the rest of the main account with the wake command
```
source ./update_vars.sh
./wake
```

## Aquire SSH certificates

- in cloud 9, Add known hosts certificate, sign your cloud9 host Key, and sign your private key as with a valid SSH client certificate for other hosts.
```
./modules/vault-configuration/modules/sign-ssh-key/sign_ssh_key.sh 
./modules/vault-configuration/modules/sign-host-key/sign_host_key.sh
./modules/vault-configuration/modules/known-hosts/known_hosts.sh
```

The remote host you intend to run the vpn on will need to do the same.
- In a terminal on your remote host that you wish to enable for SSH access, get your public key contents and copy it to the clipboard:
```
cat ~/.ssh/id_rsa.pub
```

- From cloud9, sign the public key, and provide a path to output the resulting certificates to.  eg:
```
./modules/vault-configuration/modules/sign-ssh-key/sign_ssh_key.sh --public-key ~/.ssh/remote_host/id_rsa.pub
```
This would read the public key from the provided path if it exists, and if it doesn't you are prompted to paste in your public key contents.

In the file browser at ~/.ssh/remote_host/ you should now see id_rsa-cert.pub, ssh_known_hosts, and trusted-user-ca-keys.pem
- Right click on these files to download them

- If they are on your Mac or Linux desktop you can configure the downloaded files enabling your host as an SSH client with:
```
./modules/vault-configuration/modules/sign-ssh-key/sign_ssh_key.sh --trusted-ca ~/Downloads/trusted-user-ca-keys.pem --cert ~/Downloads/id_rsa-cert.pub
```
- You will also need to configure the known hosts certificate.  This provides protection against Man In The Middle attacks:
```
./modules/vault-configuration/modules/known-hosts/known_hosts.sh --external-domain ap-southeast-2.compute.amazonaws.com --trusted-ca ~/Downloads/trusted-user-ca-keys.pem --ssh-known-hosts ~/Downloads/ssh_known_hosts_fragment
```
- Test logging into your bastion host, providing your new cert, and private key.  There should be no warnings or errors:
```
ssh -i ~/.ssh/id_rsa-cert.pub -i ~/.ssh/id_rsa centos@< Bastion Public DNS Name >
```
- Now you should be able to ssh into a private host, via public the bastion host, with the command provided at the end of running: `./wake`  eg:
```
ssh -J centos@ec2-3-24-240-130.ap-southeast-2.compute.amazonaws.com centos@i-0d10804bc2b694690.node.consul -L 8200:vault.service.consul:8200
```
This command will also forward the vault web interface which is found at: https://127.0.0.1:8200/ui/
You will get SSL certificate warnings in your web browser, which for now will have to be ignored, but these can be resolved.


All hosts now have the capability for authenticated SSH with certificates!  The default time to live (TTL) on SSH client certificates is one month, at which point you can just run this step again to authenticate a new public key.  It is best practice to generate a new private/public key pair before requesting another certificate.

### Diagnosing SSH problems:

Usually a lot can be determined by looking at the user data logs.
The cloud 9 host can ssh in to any private IP, but you will have to ignore host key checking.  Be mindful of this, it is why we should really only do it on a private network, and to resolve issues in a dev environment.
The user data log is available at:
```
/var/log/user-data.log 
```

### Configuring the VPN from your remote client (WIP)

Provided web forwarding is established and you have the vault UI running, you should be able to automate a VPN gateway.
It is required that the SSH connection is established automatically because you have SSH certificates configured.
It is important you do not take this step in an unsecured network.  The purpose of the VPN gateway is to unify two networks.  The only limiting factors for communication protocols will be security groups.

- Configure the vpn hosts json file with an ip address valid for your onsite network.  If possible, onl your router, assign the mac addresses to have the IP addresses from the json file in `firehawk-main/modules/terraform-aws-vpn/modules/openvpn-vagrant-client/ip_addresses.json`

- There are steps that must also be taken to configure your router to allow access to your cloud private subnet by configuring the VPN static routes.

- TODO: describe how to configure static routes.

- Ensure SSH forwarding is functional with the result command given to you by `./wake`:
```
ssh -J centos@ec2-13-211-132-68.ap-southeast-2.compute.amazonaws.com centos@i-0330138643ba03b32.node.consul -L 8200:vault.service.consul:8200
```
- From Cloud 9, create a token you can use to automatically retrieve your vpn config using the vpn_read_config_policy
You must provide a vault token, which should based on a policy of least privilege.  This token will have a short ttl, enough time for our automation script to acquire the VPN config.  We can also define a reasonable use limit, preventing the secret from being useful once we are done with it!  in This case we need to use it twice, once to login, and another when we request the vpn config file.
```
vault token create -policy=vpn_read_config -explicit-max-ttl=5m -ttl=5m -use-limit=2
```

- Run the vagrant wake script 
./modules/terraform-aws-vpn/modules/openvpn-vagrant-client/wake {resourcetier} {public host} {private host} 
eg:
```
./modules/terraform-aws-vpn/modules/openvpn-vagrant-client/wake dev centos@ec2-13-211-132-68.ap-southeast-2.compute.amazonaws.com centos@i-0330138643ba03b32.node.consul
```

- You can acquire the dynamic open vpn password in vault under `/dev/network/openvpn_admin_pw`

# Terminology

Some terminology will be covered here.

- resourcetier
Synonymous with environment or tier. Environment and tier are commonly used in many projects, resourcetier is defined to be abe to uniquely identify what this means in this project.  It is the name that defines an isolated deployment environment: dev / blue / green / main

- resourcetier: main
The Main VPC or Main account is intended to optionally function as a persistent VPC resource spanning multiple deployments in other environments.  It can provide resources and parameters to the other environments that they would require for thei creation, and can persist beyond their destruction.  It is also possible to dynamically create a main VPC in any other resourcetier for testing purposes or to accelerate a turnkey deployment solution, since requiring users to have multiple AWS accounts configured can add considerable overhead.

- resourcetier: blue / green
The Blue and Green resourcetier are the production environments.  They allow slow rollover from one deployment version to the next.  They should both be able to operate in parallel during transition, and instances able to be turned off / on at any point safely to save cost.

- resourcetier: dev
The Dev environment intended for all code commits and testing.  No new committed code should go directly to the other tiers.  It should be tested and deployed in dev first.  It is also possible (though untested) to isolate multiple dev deployments by the conflict key, a string made of the resource tier (dev) and pipeline id (the iteration of the deployment) producing a string like dev234 for the conflict key.  The purpose of this is to allow multiple deployments tests to run at once via users or a Continuous Integration pipeline.

