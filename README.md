# Firehawk

Firehawk is a work in progress for VFX rendering infrastructure, using multi-cloud capable and open source tooling where possible.

It uses AWS Cloud 9 as a seed instance to simplify launching the infrastructure.  The scheduler implemented presently is Deadline - it provides Usage Based Licenses for many types of software to provide access for artists at low cost and free to use the scheduler on AWS instances.  It is possible to build images to support other schedulers.

The primary reason for this project's creation is to provide low cost high powered cloud capability for Side FX Houdini users, and to provde a pathway for artists to roll their own cloud with any software they choose.

Firehawk uses these multi cloud capable techologies:  
Hashicorp Vault - for dynamic secrets management, and authentication.  
Hashicorp Terraform - for orchestration.  
Hashicorp Consul - for DNS / service discovery.  
Hashicorp Vagrant - for client side Open VPN deployment.  
OpenVPN - for a private gateway between the client network and cloud.  
Redhat Ansible - For consistent provisioning in some packer templates.  
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

- Ensure the instance type is at least m5.large (under other instance types)

- Select `Amazon Linux 2` platform.

- Ensure you add tags:
```
resourcetier=main
```
The tag will define the environment in the shell.

- Once up, in AWS Management Console | EC2 : Select the instance, and change the instance profile to your `Cloud9CustomAdminRoleFirehawk`

- Connect to the session through AWS Management Console | Cloud9.

- When connected, disable "AWS Managed Temporary Credentials" ( Select the Cloud9 Icon in the top left | AWS Settings )
Your instance should now have permission to create and destroy any resource with Terraform.

## Create the Hashicorp Vault deployment

- Clone the repo, and install required binaries and packages.
```
git clone --recurse https://github.com/firehawkvfx/firehawk-main.git
cd firehawk; ./install-packages
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
- Ensure you reboot the instance after this point, or DNS for consul will not function properly (dnsmasq requires this).

- If you have Deadline Certificates (required for third party / Houdini UBL) you should go to the ublcerts bucket just created and ensure the zip file containing the certs exists at `ublcertszip/certs.zip` in the S3 Bucket.  The Deadline DB / License forwarder has access to this bucket to install the certificates on deployment.
## Build Images

For each client instance we build a base AMI to run OS updates (you only need to do this infrequently).  Then we build the complete AMI from the base AMI to speed up subsequent builds (the base AMI provides better reproducible results from ever changing software updates).

- Build Base AMI's
```
source ./update_vars.sh
cd deploy/packer-firehawk-amis/modules/firehawk-base-ami
./build.sh
```

- When this is complete you can build the final AMI's which will use the base AMI's
```
cd deploy/packer-firehawk-amis/modules/firehawk-ami
./build.sh
```

- Check that you have images for the bastion, vault client, and vpn server in AWS Management Console | Ami's.  If any are missing you may wish to try running the contents of the script manually.

## First time Vault deployment

The first time you launch Vault, it will not have any config stored in the S3 backend yet.  Once you have completed these steps you wont have to run them again.

- Source environment variables to pickup the AMI ID's. They should be listed as they are found:
```
source ./update_vars.sh
```

- Deploy Vault.
```
cd vault-init
./init
```

- After around 10 minutes, we should see this in the log:
```
Initializing vault...
Recovery Key 1: 23l4jh13l5jh23ltjh25=

Initial Root Token: s.lk235lj235k23j525jn

Success! Vault is initialized
```
During init, it also created an admin token, and logged in with that token.  You can check this with:
```
vault token lookup
```

- Store the root token, admin token, and recovery key in an encrypted password manager.  If you have problems with any steps in vault-init, and you wish to start from scratch, you can use the ./destroy script to start over. You may also delete the contents of the S3 bucket storing the vault data for a clean install.


- Next we can use terraform to configure vault...  You can use a shell script to aid this:
```
./configure
```

- After this step you should now be using an admin token


- Store all the above mentioned sensitive output (The recovery key, root token, and admin) in an encrypted password manager for later use.

- Ensure you are joined to the consul cluster:
```
sudo /opt/consul/bin/run-consul --client --cluster-tag-key "${consul_cluster_tag_key}" --cluster-tag-value "${consul_cluster_tag_value}"
consul catalog services
```
This should show 2 services: consul and vault.

- Now ensure updates to the vault config will work with your admin token. 
```
TF_VAR_configure_vault=true terragrunt run-all apply
```

Congratulations!  You now have a fully configured vault.

## Continue to deploy the rest of the resources from deploy/
```
cd ../deploy
terragrunt run-all apply
```

## Acquire SSH Certificates (Automated)

This workflow is currently tested on MacOS is also supported on Linux.

When the vault-ssh module is applied by Terraform, it automatically signs the Cloud9 user's SSH key.  It also retrieves your remote onsite user's public key from an SSM parameter which you will have already set on the cloudformation parameter template.  It signs it and stores the public certificate as an SSM parameter value.  This can be retrieved with AWS credentials and configure for your onsite host.

- Generate a set of AWS credentials with vault on the cloud9 host:
```
vault read aws/creds/aws-creds-deadline-cert
```

- With the CLI installed on your onsite host, ensure you have installed the AWS CLI, and configure these credentials, along with your region:
```
aws configure 
```
- You will now be able to read parameters, for example:
```
aws ssm get-parameters --names /firehawk/resourcetier/dev/trusted_ca
```

## Acquire SSH Certificates (Manual)

- In cloud 9, Add known hosts certificate, sign your cloud9 host Key, and sign your private key as with a valid SSH client certificate for other hosts.  This was already done during init, but its fine to get familiar with how to automate signing an SSH cert.
```
firehawk-main/modules/vault-ssh/modules/firehawk-auth-scripts/sign-ssh-key # This signs your cloud9 private key, enabling it to be used to SSH to other hosts.
firehawk-main/modules/vault-ssh/modules/firehawk-auth-scripts/sign-host-key # This signs a host key, so that it is recognised as part of the infra that other systems can SSH to.  If a host key is not signed, then we have a way of knowing if a host is not part of our infra.
firehawk-main/modules/vault-ssh/modules/firehawk-auth-scripts/known-hosts # This provides the public CA (Certificate Authority) cert to your host, allowing you to recognise what hosts you can SSH to safely.
```


The remote host you intend to run the vpn on remotely will need to do the same.
- In a terminal on your remote host that you wish to enable for SSH access, get your public key contents and copy it to the clipboard:
```
cat ~/.ssh/id_rsa.pub
```

- From cloud9, sign the public key, and provide a path to output the resulting certificates to.  eg:
```
firehawk-main/modules/vault-ssh/modules/firehawk-auth-scripts/sign-ssh-key --public-key ~/.ssh/remote_host/id_rsa.pub
```
This will read the public key from the provided path if it exists, and if it doesn't you are prompted to paste in your public key contents.

In the file browser at ~/.ssh/remote_host/ you should now see id_rsa-cert.pub, trusted-user-ca-keys.pem, and ssh_known_hosts_fragment (in the directory above)
- Right click on each of these files to download them, ensure they do not get renamed by your browser when you download.

- If they are on your Mac or Linux desktop you can configure the downloaded files enabling your host as an SSH client with:
```
firehawk-main/modules/vault-ssh/modules/firehawk-auth-scripts/sign-ssh-key --trusted-ca ~/Downloads/trusted-user-ca-keys.pem --cert ~/Downloads/id_rsa-cert.pub
```
- You will also need to configure the known hosts certificate.  This provides better protection against Man In The Middle (MITM) attacks:
```
firehawk-main/modules/vault-ssh/modules/firehawk-auth-scripts/known-hosts --external-domain ap-southeast-2.compute.amazonaws.com --trusted-ca ~/Downloads/trusted-user-ca-keys.pem --ssh-known-hosts ~/Downloads/ssh_known_hosts_fragment
```
- Now you should be able to ssh into a private host, via public the bastion host, with the command provided at the end of running this in `deploy/`: `terragrunt run-all apply`  eg:
```
ssh -J centos@ec2-3-24-240-130.ap-southeast-2.compute.amazonaws.com centos@i-0d10804bc2b694690.node.consul -L 8200:vault.service.consul:8200
```
This command will also forward the vault web interface which is found at: https://127.0.0.1:8200/ui/
You will get SSL certificate warnings in your web browser, which for now will have to be ignored, but these can be resolved.

If this doesn't work, test logging into your bastion host, providing your new cert, and private key.  There should be no warnings or errors, otherwise you may have a problem configuring the CA on your system:
```
ssh -i ~/.ssh/id_rsa-cert.pub -i ~/.ssh/id_rsa centos@< Bastion Public DNS Name >
```

- You shouldn't use a long lived admin token outside of the cloud 9 environment.  Create another token with a more reasonable period to login via the cloud9 terminal in your browser:
```
vault token create -policy=admins -explicit-max-ttl=18h
```

- Use the returned toke to login and explore the UI.

All hosts now have the capability for authenticated SSH with certificates!  The default time to live (TTL) on SSH client certificates is one month, at which point you can just run this step again to authenticate a new public key.  It is best practice to generate a new private/public key pair before requesting another certificate.

### Diagnosing SSH problems:

Usually a lot can be determined by looking at the user data logs to determine if SSH Certs, Vault, and Consul are all behaving.
The Cloud 9 host can ssh in to any private IP, but you will have to ignore host key checking if there are problems with certificates.  Be mindful of this, it is why we should really only do it on a private network, and to resolve issues in a dev environment.
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

- Ensure SSH forwarding is functional and you can use the Vault UI explained in the previous steps:

- From Cloud 9, create a token you can use to automatically retrieve your vpn config using the vpn_read_config_policy
You must provide a vault token, which should based on a policy of least privilege.  This token will have a short ttl, enough time for our automation script to acquire the VPN config.  We can also define a reasonable use limit, preventing the secret from being useful once we are done with it!  in This case we need to use it twice, once to login, and another when we request the vpn config file.
```
vault token create -policy=vpn_read_config -policy=deadline_client -explicit-max-ttl=5m -ttl=5m -use-limit=4
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

