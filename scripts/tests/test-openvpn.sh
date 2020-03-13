#!/bin/bash

RED='\033[0;31m' # Red Text
GREEN='\033[0;32m' # Green Text
BLUE='\033[0;34m' # Blue Text
NC='\033[0m' # No Color

optspec=":hv-:t:"

parse_opts () {
    local OPTIND
    OPTIND=0
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    ip)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        vpn_private_ip="${OPTARG}"
                        ;;
                    ip=*)
                        val=${OPTARG#*=}
                        vpn_private_ip=${OPTARG%=$val}
                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            echo "Unknown option --${OPTARG}" >&2
                        fi
                        ;;
                esac;;
            *)
                if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                    echo "Non-option argument: '-${OPTARG}'" >&2
                fi
                ;;
        esac
    done
}
parse_opts "$@"

if [[ -z "$vpn_private_ip" ]]; then
  # return the first ip output for the vpn address.
  vpn_private_ip=$(terraform output vpn_private_ip | head -n 1)
fi

# blackhole test, ipv4
fping -c1 -t30000 $vpn_private_ip &> /dev/null && pass=true || pass=false

if [ $pass == true ]
then
  printf "\n${GREEN}The VPN private IP was reachable.${NC}\n\n"
  exit 0
else
  printf "\n${RED}The VPN private IP could not be reached.  Ensure you can login to the vpn manually, and restart the VM with 'vagrant firehawkgateway reload' before continuing.${NC}\n" >&2
  ip a
  exit 1
fi