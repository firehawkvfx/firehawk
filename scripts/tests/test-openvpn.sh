#!/bin/bash

RED='\033[0;31m' # Red Text
GREEN='\033[0;32m' # Green Text
BLUE='\033[0;34m' # Blue Text
NC='\033[0m' # No Color

# return the first ip output for the vpn address.
vpn_private_ip=$(terraform output vpn_private_ip | head -n 1)
# blackhole test, ipv4 range 240.0.0.0/4 reserved for future use
ping -c1 $vpn_private_ip &> /dev/null && pass=true || pass=false

if [ $pass == true ]
then
  printf "${GREEN}The VPN private IP was reachable.${NC}\n\n"
  exit 0
else
  printf "${RED}The VPN private IP could not be reached.  Ensure you can login to the vpn manually, and restart the VM with 'vagrant reload' before continuing.${NC}\n" >&2
  exit 1
fi