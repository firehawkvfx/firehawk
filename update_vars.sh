#!/bin/bash

vpcname="vaultvpc"
projectname="firehawk-main" # A tag to recognise resources created in this project

to_abs_path() {
  python3 -c "import os; print(os.path.abspath('$1'))"
}

function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local -r message="$1"
  log "INFO" "$message"
}

function log_warn {
  local -r message="$1"
  log "WARN" "$message"
}

function log_error {
  local -r message="$1"
  log "ERROR" "$message"
}

function error_if_empty {
  if [[ -z "$2" ]]; then
    log_error "$1"
  fi
  return
}

# Query AMI's by role tag and commit

function retrieve_ami {
  local -r latest_ami="$1"
  local -r ami_role="$2"
  local -r ami_commit_hash="$3"
  local ami_result="null"
  if [[ "$latest_ami" == true ]]; then
    ami_filters="Name=tag:ami_role,Values=$ami_role"
    # printf "\n...Query latest AMI"
  else
    ami_filters="Name=tag:ami_role,Values=$ami_role Name=tag:commit_hash,Values=$ami_commit_hash"
    # printf "\n...Query AMI with commit: $ami_commit_hash"
  fi
  # this query by aws will return null presently if invalid
  ami_result=$(aws ec2 describe-images --filters $ami_filters --owners self --region $AWS_DEFAULT_REGION --query 'sort_by(Images, &CreationDate)[].ImageId' --output json | jq '.[-1]' --raw-output)

  echo "$ami_result"
}

function warn_if_invalid {
  local -r ami_role=$1
  local -r ami_result=$2
  local -r var_name=$3

  if [[ -z "$ami_result" || "$ami_result" == "null" ]]; then
    log_warn "Images required for deployment are not present.  You will need to build them before continuing."
  else
    printf "$var_name"
    printf "\n  Found role $ami_role result:"
    printf "\n  $ami_result\n\n"
  fi
}

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script

# Region is required for AWS CLI
export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
# Get the resourcetier from the instance tag.
export TF_VAR_instance_id_main_cloud9=$(curl http://169.254.169.254/latest/meta-data/instance-id)
export TF_VAR_resourcetier="$(aws ec2 describe-tags --filters Name=resource-id,Values=$TF_VAR_instance_id_main_cloud9 --out=json|jq '.Tags[]| select(.Key == "resourcetier")|.Value' --raw-output)" # Can be dev,green,blue,main.  it is pulled from this instance's tags by default
export TF_VAR_resourcetier_vault="$TF_VAR_resourcetier" # WARNING: if vault is deployed in a seperate tier for use, then this will probably need to become an SSM driven parameter from the template
export TF_VAR_vpcname="${TF_VAR_resourcetier}${vpcname}" # Why no underscores? Because the vpc name is used to label terraform state S3 buckets
export TF_VAR_vpcname_vault="${TF_VAR_resourcetier}vaultvpc" # WARNING: if vault is deployed in a seperate tier for use, then this will probably need to become an SSM driven parameter from the template
export TF_VAR_projectname="$projectname"

# Instance and vpc data
export TF_VAR_deployer_ip_cidr="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)/32" # Initially there will be no remote ip onsite, so we use the cloud 9 ip.
export TF_VAR_remote_cloud_public_ip_cidr="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)/32" # The cloud 9 IP to provision with.
export TF_VAR_remote_cloud_private_ip_cidr="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)/32"
macid=$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
export TF_VAR_vpc_id_main_cloud9=$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${macid}/vpc-id) # Aquire the cloud 9 instance's VPC ID to peer with Main VPC
export TF_VAR_cloud9_instance_name="$(aws ec2 describe-tags --filters Name=resource-id,Values=$TF_VAR_instance_id_main_cloud9 --out=json|jq '.Tags[]| select(.Key == "Name")|.Value' --raw-output)"
export TF_VAR_account_id=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '(?<="accountId" : ")[^"]*(?=")')
export TF_VAR_owner="$(aws s3api list-buckets --query Owner.DisplayName --output text)"
# region specific vars
export PKR_VAR_aws_region="$AWS_DEFAULT_REGION"
export TF_VAR_aws_internal_domain=$AWS_DEFAULT_REGION.compute.internal # used for FQDN resolution
export PKR_VAR_aws_internal_domain=$AWS_DEFAULT_REGION.compute.internal # used for FQDN resolution
export TF_VAR_aws_external_domain=$AWS_DEFAULT_REGION.compute.amazonaws.com

if [[ -z "$TF_VAR_resourcetier" ]]; then
  log_error "Could not read resourcetier tag from this instance.  Ensure you have set a tag with resourcetier."
  return
fi
export PKR_VAR_resourcetier="$TF_VAR_resourcetier"
export TF_VAR_pipelineid="0" # Uniquely name and tag the resources produced by a CI pipeline
export TF_VAR_conflictkey="${TF_VAR_resourcetier}${TF_VAR_pipelineid}" # The conflict key is a unique identifier for a deployment.
if [[ "$TF_VAR_resourcetier"=="dev" ]]; then
  export TF_VAR_environment="dev"
else
  export TF_VAR_environment="prod"
fi
export TF_VAR_firehawk_path=$SCRIPTDIR

# Packer Vars

export PACKER_LOG=1
export PACKER_LOG_PATH="packerlog.log"
export TF_VAR_provisioner_iam_profile_name="provisioner_instance_role_$TF_VAR_conflictkey"
export PKR_VAR_provisioner_iam_profile_name="provisioner_instance_role_$TF_VAR_conflictkey"
export TF_VAR_packer_iam_profile_name="packer_instance_role_$TF_VAR_conflictkey"
export PKR_VAR_packer_iam_profile_name="packer_instance_role_$TF_VAR_conflictkey"

### Query existance of images required for deployment of instances.  Some parts of infrastructure can be deployed without images

latest_ami=true # If using latest, this should only be allowed in a dev environment.  Otherwise, all images must be built from the same template
if [[ "$PKR_VAR_resourcetier" != "dev" ]]; then
  latest_ami=false
fi
# AMI query by commit - Vault and Consul Servers
export TF_VAR_ami_commit_hash="$(cd $TF_VAR_firehawk_path/../packer-firehawk-amis/modules/firehawk-ami; git rev-parse HEAD)" 

# AMI query by commit - Vault and Consul Server
ami_role="firehawk_ubuntu18_vault_consul_server_ami"
export TF_VAR_vault_consul_ami_id=$(retrieve_ami $latest_ami $ami_role $TF_VAR_ami_commit_hash)
warn_if_invalid "$ami_role" "$TF_VAR_vault_consul_ami_id" "TF_VAR_vault_consul_ami_id"
# AMI query by commit - Vault and Consul Client
ami_role="firehawk_centos7_ami"
export TF_VAR_vault_client_ami_id=$(retrieve_ami $latest_ami $ami_role $TF_VAR_ami_commit_hash)
warn_if_invalid "$ami_role" "$TF_VAR_vault_client_ami_id" "TF_VAR_vault_client_ami_id"
# AMI query by commit - Bastion Host
ami_role="firehawk_centos7_ami"
export TF_VAR_bastion_ami_id=$(retrieve_ami $latest_ami $ami_role $TF_VAR_ami_commit_hash)
warn_if_invalid "$ami_role" "$TF_VAR_bastion_ami_id" "TF_VAR_bastion_ami_id"
# AMI query by commit - Open VPN Server
ami_role="firehawk_openvpn_server_ami"
export TF_VAR_openvpn_server_ami=$(retrieve_ami $latest_ami $ami_role $TF_VAR_ami_commit_hash)
warn_if_invalid "$ami_role" "$TF_VAR_openvpn_server_ami" "TF_VAR_openvpn_server_ami"
# AMI query by commit - Deadline DB
ami_role="firehawk_deadlinedb_ami"
export TF_VAR_deadline_db_ami_id=$(retrieve_ami $latest_ami $ami_role $TF_VAR_ami_commit_hash)
warn_if_invalid "$ami_role" "$TF_VAR_deadline_db_ami_id" "TF_VAR_deadline_db_ami_id"
# AMI query by commit - Render node
ami_role="firehawk_centos7_rendernode_ami"
export TF_VAR_centos7_rendernode_ami=$(retrieve_ami $latest_ami $ami_role $TF_VAR_ami_commit_hash)
warn_if_invalid "$ami_role" "$TF_VAR_centos7_rendernode_ami" "TF_VAR_centos7_rendernode_ami"
# Terraform Vars
export TF_VAR_general_use_ssh_key="$HOME/.ssh/id_rsa" # For debugging deployment of most resources- not for production use.
export TF_VAR_aws_private_key_path="$TF_VAR_general_use_ssh_key"

# SSH Public Key is used for debugging instances only.  Not for general use.  Use SSH Certificates instead.
export TF_VAR_aws_key_name="cloud9_$TF_VAR_cloud9_instance_name"
# export TF_VAR_aws_key_name="deployer-key-$TF_VAR_resourcetier"
public_key_path="$HOME/.ssh/id_rsa.pub"
if [[ ! -f $public_key_path ]] ; then
    echo "File $public_key_path is not there, aborting. Ensure you have initialised a keypair with ssh-keygen"
    # ssh-keygen -t rsa -C "my-key" -f ~/.ssh/my-key
    return
fi
export TF_VAR_vault_public_key=$(cat $public_key_path)

export TF_VAR_log_dir="$SCRIPTDIR/tmp/log"; mkdir -p $TF_VAR_log_dir

export VAULT_ADDR=https://vault.service.consul:8200 # verify dns before login with: dig vault.service.consul
export consul_cluster_tag_key="consul-servers" # These tags are used when new hosts join a consul cluster. 
export consul_cluster_tag_value="consul-$TF_VAR_resourcetier"
export TF_VAR_consul_cluster_tag_key="$consul_cluster_tag_key"
export PKR_VAR_consul_cluster_tag_key="$consul_cluster_tag_key"
export TF_VAR_consul_cluster_name="$consul_cluster_tag_value"
export PKR_VAR_consul_cluster_tag_value="$consul_cluster_tag_value"

# Retrieve SSM parameters set by cloudformation
get_parameters=$( aws ssm get-parameters --names \
    "/firehawk/resourcetier/${TF_VAR_resourcetier}/onsite_public_ip" \
    "/firehawk/resourcetier/${TF_VAR_resourcetier}/onsite_private_subnet_cidr" \
    "/firehawk/resourcetier/${TF_VAR_resourcetier}/global_bucket_extension" \
    "/firehawk/resourcetier/${TF_VAR_resourcetier}/combined_vpcs_cidr" \
    "/firehawk/resourcetier/${TF_VAR_resourcetier}/vpn_cidr" \
    "/firehawk/resourcetier/${TF_VAR_resourcetier}/houdini_license_server_address" \
    "/firehawk/resourcetier/${TF_VAR_resourcetier}/sesi_client_id" )

num_invalid=$(echo $get_parameters | jq '.InvalidParameters| length')
if [[ $num_invalid -eq 0 ]]; then
  export TF_VAR_onsite_public_ip=$(echo $get_parameters | jq ".Parameters[]| select(.Name == \"/firehawk/resourcetier/${TF_VAR_resourcetier}/onsite_public_ip\")|.Value" --raw-output)
  error_if_empty "SSM Parameter missing: onsite_public_ip" "$TF_VAR_onsite_public_ip"
  export TF_VAR_onsite_private_subnet_cidr=$(echo $get_parameters | jq ".Parameters[]| select(.Name == \"/firehawk/resourcetier/${TF_VAR_resourcetier}/onsite_private_subnet_cidr\")|.Value" --raw-output)
  error_if_empty "SSM Parameter missing: onsite_private_subnet_cidr" "$TF_VAR_onsite_private_subnet_cidr"
  export TF_VAR_global_bucket_extension=$(echo $get_parameters | jq ".Parameters[]| select(.Name == \"/firehawk/resourcetier/${TF_VAR_resourcetier}/global_bucket_extension\")|.Value" --raw-output)
  error_if_empty "SSM Parameter missing: global_bucket_extension" "$TF_VAR_global_bucket_extension"
  export TF_VAR_combined_vpcs_cidr=$(echo $get_parameters | jq ".Parameters[]| select(.Name == \"/firehawk/resourcetier/${TF_VAR_resourcetier}/combined_vpcs_cidr\")|.Value" --raw-output)
  error_if_empty "SSM Parameter missing: combined_vpcs_cidr" "$TF_VAR_combined_vpcs_cidr"
  export TF_VAR_vpn_cidr=$(echo $get_parameters | jq ".Parameters[]| select(.Name == \"/firehawk/resourcetier/${TF_VAR_resourcetier}/vpn_cidr\")|.Value" --raw-output)
  error_if_empty "SSM Parameter missing: vpn_cidr" "$TF_VAR_vpn_cidr"

  export TF_VAR_houdini_license_server_address=$(echo $get_parameters | jq ".Parameters[]| select(.Name == \"/firehawk/resourcetier/${TF_VAR_resourcetier}/houdini_license_server_address\")|.Value" --raw-output)
  export PKR_VAR_houdini_license_server_address="$TF_VAR_houdini_license_server_address"
  error_if_empty "SSM Parameter missing: houdini_license_server_address" "$TF_VAR_houdini_license_server_address"
  export TF_VAR_sesi_client_id=$(echo $get_parameters | jq ".Parameters[]| select(.Name == \"/firehawk/resourcetier/${TF_VAR_resourcetier}/sesi_client_id\")|.Value" --raw-output)
  export PKR_VAR_sesi_client_id="$TF_VAR_sesi_client_id"
  error_if_empty "SSM Parameter missing: sesi_client_id" "$TF_VAR_sesi_client_id"
  
  export TF_VAR_bucket_extension="$TF_VAR_resourcetier.$TF_VAR_global_bucket_extension"
  export TF_VAR_installers_bucket="software.$TF_VAR_resourcetier.$TF_VAR_global_bucket_extension" # All installers should be kept in the same bucket.  If a main account is present, packer builds should trigger from the main account.
  export TF_VAR_bucket_extension_vault="$TF_VAR_resourcetier.$TF_VAR_global_bucket_extension" # WARNING: if vault is deployed in a seperate tier for use, then this will probably need to become an SSM driven parameter from the template 
  # export PKR_VAR_installers_bucket="$TF_VAR_installers_bucket"
else
  log_error "SSM parameters are not yet initialised.  You can init SSM parameters with the cloudformation template modules/cloudformation-cloud9-vault-iam/cloudformation_ssm_parameters_firehawk.yaml"
  return
fi

common_tags_path="$SCRIPTDIR/common_tags.json"
echo "read: $common_tags_path"
export TF_VAR_common_tags=$(jq -n -f "$common_tags_path" \
  --arg environment "$TF_VAR_environment" \
  --arg resourcetier "$TF_VAR_resourcetier" \
  --arg conflictkey "$TF_VAR_conflictkey" \
  --arg pipelineid "$TF_VAR_pipelineid" \
  --arg region "$AWS_DEFAULT_REGION" \
  --arg vpcname "$TF_VAR_vpcname" \
  --arg projectname "$TF_VAR_projectname" \
  --arg accountid "$TF_VAR_account_id" \
  --arg owner "$TF_VAR_owner" )

echo "TF_VAR_common_tags: $TF_VAR_common_tags"

log_info "Done sourcing vars."