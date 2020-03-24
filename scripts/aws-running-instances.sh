# isntance id's
#aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --filters Name=instance-state-name,Values=running --output text
# private ip's
aws ec2 describe-instances --filter "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*][Tags[?Key=='Name'].Value[],NetworkInterfaces[0].PrivateIpAddresses[0].PrivateIpAddress]" --output text