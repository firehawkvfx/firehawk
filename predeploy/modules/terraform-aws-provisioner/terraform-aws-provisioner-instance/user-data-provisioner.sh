#!/bin/bash

# log userdata
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Configure max revisions for codedeploy-agent..."

cat /etc/codedeploy-agent/conf/codedeployagent.yml

sed '$ d' /etc/codedeploy-agent/conf/codedeployagent.yml > /etc/codedeploy-agent/conf/temp.yml
echo ':max_revisions: 2' >> /etc/codedeploy-agent/conf/temp.yml
rm -f /etc/codedeploy-agent/conf/codedeployagent.yml
mv /etc/codedeploy-agent/conf/temp.yml /etc/codedeploy-agent/conf/codedeployagent.yml

cat /etc/codedeploy-agent/conf/codedeployagent.yml

service codedeploy-agent restart