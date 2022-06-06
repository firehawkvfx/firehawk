#!/bin/bash

set -e
exec > >(tee -a /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Register the service with consul.  not that it may not be necesary to set the hostname in the beggining of this user data script, especially if we create a cluster in the future.
echo "...Registering service with consul"
service_name="${consul_service}"
consul services register -name=$service_name
sleep 5
consul catalog services
dig $service_name.service.consul
result=$(dig +short $service_name.service.consul) && exit_status=0 || exit_status=$?
if [[ ! $exit_status -eq 0 ]]; then echo "No DNS entry found for $service_name.service.consul"; exit 1; fi
