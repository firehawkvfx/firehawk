
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script
cd $SCRIPTDIR

sudo yum install -y git
sudo yum install -y python python3.7 python3-pip
python3 -m pip install --user --upgrade pip # Do not run pip as sudo. Do this instead.
python3 -m pip install ansible boto3

sudo yum install -y jq
mkdir -p $SCRIPTDIR/tmp

wget https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip -P /tmp/ # Get terraform
sudo unzip /tmp/terraform_0.13.5_linux_amd64.zip -d /tmp/
sudo mv /tmp/terraform /usr/local/bin/.

wget https://releases.hashicorp.com/packer/1.6.4/packer_1.6.4_linux_amd64.zip -P /tmp/ # Get Packer
sudo unzip /tmp/packer_1.6.4_linux_amd64.zip -d /tmp/
sudo mv /tmp/packer /usr/local/bin/.

wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.28.16/terragrunt_linux_386 -P /tmp/ # Get Terragrunt
sudo mv /tmp/terragrunt_linux_386 /usr/local/bin/terragrunt

mkdir -p "$HOME/.ssh/tls" # The directory to store TLS certificates in.
