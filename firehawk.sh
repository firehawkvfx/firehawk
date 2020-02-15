#!/bin/bash
# echo "Enter Secrets Decryption Password..."
unset HISTFILE

echo -n Password: 
read -s password

printf "\nRunning ansiblecontrol with $1...\n"

vagrant up

hostname=$(vagrant ssh-config ansiblecontrol | grep -Po '.*HostName\ \K(\d*.\d*.\d*.\d*)')
port=$(vagrant ssh-config ansiblecontrol | grep -Po '.*Port\ \K(\d*)')

# use expect to pipe through the password aquired initially.
./scripts/expect-firehawk.sh $hostname $port $1 $password
