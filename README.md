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
git clone --recurse-submodules https://github.com/firehawkvfx/firehawk-main.git
cd firehawk-main; ./install_packages.sh
```

- Initialise the environment variables and spin up the resources.
```
source ./update_vars.sh
```

- Initialise an S3 bucket for terraform remote state.  This only needs to be done once per account / tier (main/dev/green/blue)
```
./init_backend
```

- Initialise the cloud9 host & Vault back end. This will also initialise an IAM profile for packer builds to access S3.  You will need to do this each time you create a new cloud 9 host.  This will ensure you have an RSA key and configure it to ssh into hosts for testing.  It also ensures your S3 backed is functioning correctly.
```
./init_host
```

- Create TLS Certificates for your Vault images
```
cd modules/terraform-aws-vault/modules/private-tls-cert
terraform plan -out=tfplan
terraform apply tfplan
```

- Install Consul and Vault client
```
cd modules/vault
./install-consul-vault-client --vault-module-version v0.13.11  --vault-version 1.5.5 --consul-module-version v0.8.0 --consul-version 1.8.4 --build amazonlinux2 --cert-file-path /home/ec2-user/.ssh/tls/ca.crt.pem
```

## Build images for Vault and Consul

- Build Vault and Consul Images
```
cd $TF_VAR_firehawk_path
./build.sh
```

While this is occuring, in another terminal you can also build images for the vault clients and continue with the next step...

## Build images for the bastion, internal vault client, and vpn server

For each client instance we build a base AMI to run os updates (you only need to do this infrequently).  Then we build the complete AMI from the base AMI to speed up subsequent builds (and provide a better foundation from ever changing software updates).

- Run this script to automate all subsequent builds for teh vault and consul clients.
```
scripts/build_vault_clients.sh
```

- Check that you have images for the bastion, vault client, and vpn server in you AWS Management Console | Ami's.  If any are missing you may wish to try running the contents of the script manually.

Note: The images here are built without a valt cluster, but there will be no verification of Consul DNS resolution. If you wish to test DNS during the image build and your vault cluster is running, run these steps after vault is up and run:
```
export PKR_VAR_test_consul=true
```

## Policies and Vault Deployment

- Create a policy enabling Packer to build images with vault access.  You only need to ensure these policies exist once per resourcetier (dev/green/blue/prod). These policies are not required to build images in the main account, but may be used to build images for rendering.
```
cd modules/terraform-aws-iam-profile-provisioner
./generate-plan
terraform apply tfplan
```

- Create KMS Keys to auto unseal the vault
```
cd modules/terraform-aws-kms-key
./generate-plan
terraform apply tfplan
```

- Create a VPC for Vault
```
cd modules/vpc
./generate-plan
terraform apply tfplan
```

- Enable peering between vault vpc and current Cloud 9 vpc
```
cd modules/terraform-aws-vpc-main-cloud9-peering
./generate-plan
terraform apply tfplan
```

- Deploy Vault
```
cd $TF_VAR_firehawk_path
./wake
```

- Initialise the vault:
```
ssh ubuntu@(Vault Private IP)
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
- Now you can create an admin token
```
vault token create -policy=admins
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

## You should be able to continue to deploy tthe rest of the main account with the wake command
```
source ./update_vars.sh
./wake
```

## Aquire SSH certificates

- Add known hosts certificate, sign your cloud9 host Key, and sign your host as an SSH Client to other hosts.
```
./modules/vault-configuration/modules/sign-ssh-key/sign_ssh_key.sh 
./modules/vault-configuration/modules/sign-host-key/sign_host_key.sh
./modules/vault-configuration/modules/sign-host-key/known_hosts.sh
```

The remote host you intend to run the vpn on will need to do the same.
- In the cloud9 file browser, click the cog to show the home dir.
- Create a new folder in /home/ec2-user/.ssh named something like 'remote_host' or the machine name.
- In a file browser on the remote host, ensure you have generated an rsa public key, and drag the public key into this folder in the web browser.

- From cloud9, sign the public key.  eg:

```
./modules/vault-configuration/modules/sign-ssh-key/sign_ssh_key.sh --public-key ~/.ssh/remote_host/id_rsa.pub
```
In the file browser at ~/.ssh/remote_host/ you should now see id_rsa-cert.pub and trusted-user-ca-keys.pem
- Right click on these files to download them

- If they are on your Mac or Linux desktop you can configure the downloaded files for use with with
```
modules/vault-configuration/modules/sign-ssh-key/sign_ssh_key.sh --trusted-ca ~/Downloads/trusted-user-ca-keys.pem --cert ~/Downloads/id_rsa-cert.pub
```

All hosts now have the capability for authenticated SSH with certificates!  The default time to live (TTL) on SSH client certificates is one month, at which point you can just run this step again.

