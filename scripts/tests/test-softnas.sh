#!/bin/bash

RED='\033[0;31m' # Red Text
GREEN='\033[0;32m' # Green Text
BLUE='\033[0;34m' # Blue Text
NC='\033[0m' # No Color

# return the first ip output for the vpn address.
softnas_private_ip=$TF_VAR_softnas1_private_ip1
# blackhole test, ipv4 range 240.0.0.0/4 reserved for future use
ping -c1 $softnas_private_ip &> /dev/null && pass=true || pass=false

if [ $pass == true ]
then
  printf "\n${GREEN}The softnas private IP was reachable.${NC}\n\n"
  exit 0
else
  printf "\n${RED}The softnas private IP could not be reached.  Ensure the softnas instance exists and is running. Also ensure you can login to the VPN manually, and restart the VM with 'vagrant reload' before continuing.${NC}\n\n" >&2
  exit 1
fi