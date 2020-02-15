#!/bin/bash
echo "hostname $1"
echo "port $2"
echo "tier $3"
ssh deployuser@$1 -p $2 -i .vagrant/machines/ansiblecontrol/virtualbox/private_key -t "/deployuser/scripts/init-firehawk.sh $3"