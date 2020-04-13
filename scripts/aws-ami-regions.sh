#!/bin/bash
# Takes a filter in the form "Name=description,Values=SoftNAS Cloud Platinum - Consumption - 4.3.0" and provides the AMI ID's for all regions.
# 2nd argument defines the owner id which is important to not pickup community based images.
# 3rd argument defines the map name, or the variable name for terraform

# You can use the output to define an ami map for terrform in json format.
# softnas high
# ./scripts/aws-ami-regions.sh "Name=description,Values=SoftNAS Cloud Platinum - Consumption - 4.3.0" 679593333241 "softnas_platinum_consumption_v4_3_0" 2>&1 | tee /deployuser/modules/softnas/ami_softnas_platinum_consumption_v4_3_0.auto.tfvars.json
# softnas low
# ./scripts/aws-ami-regions.sh "Name=description,Values=SoftNAS Cloud Platinum - Consumption (For Lower Compute Requirements) - 4.3.0" "679593333241" "softnas_platinum_consumption_lower_v4_3_0" 2>&1 | tee /deployuser/modules/softnas/ami_softnas_platinum_consumption_lower_v4_3_0.auto.tfvars.json
# open vpn - check the ami is correct here.
# ./scripts/aws-ami-regions.sh "Name=name,Values=OpenVPN Access Server 2.7.5-fe8020db-5343-4c43-9e65-5ed4a825c931*" 679593333241 "openvpn_v2_7_5" 2>&1 | tee /deployuser/modules/vpn/ami_openvpn_access_server_v2_7_5.auto.tfvars.json
# centos 7
# render node
# ./scripts/aws-ami-regions.sh "Name=name,Values=CentOS Linux 7 x86_64 HVM EBS ENA 1901_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e*" 679593333241 "centos_v7" 2>&1 | tee /deployuser/modules/node_centos/ami_centos_v7.auto.tfvars.json
# bastion
# ./scripts/aws-ami-regions.sh "Name=name,Values=CentOS Linux 7 x86_64 HVM EBS ENA 1901_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e*" 679593333241 "centos_v7" 2>&1 | tee /deployuser/modules/bastion/ami_centos_v7.auto.tfvars.json
# ./scripts/aws-ami-regions.sh "Name=tag:base_ami,Values=ami-051ec062f31c60ee4" self "restore_softnas_ami"
# aws ec2 describe-images --owners self --filters "Name=tag:base_ami,Values=ami-051ec062f31c60ee4" --query 'Images[*].{ID:ImageId}'


if [ -z "$1" ] ; then
    1>&2 echo '"Provide a filter as a second argument, eg "Name=description,Values=SoftNAS Cloud Platinum - Consumption - 4.3.0"'
    exit 1
fi

optspec=":hv-:"

parse_opts () {
    local OPTIND
    OPTIND=0
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    filters)
                        filters="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    filters=*)
                        filters=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        ;;
                    owners)
                        owners="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    owners=*)
                        owners=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        ;;
                    map_name)
                        map_name="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    map_name=*)
                        map_name=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        ;;
                    regions)
                        declare -a regions="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        ;;
                    regions=*)
                        declare -a regions=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        ;;
                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            echo "Unknown option --${OPTARG}" >&2
                        fi
                        ;;
                esac;;
            v) # verbosity is handled prior since its a dependency for this block
                ;;
            h)
                help
                ;;
            *)
                if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                    echo "Non-option argument: '-${OPTARG}'" >&2
                fi
                ;;
        esac
    done
}
parse_opts "$@"

# filters="$1"
# owners="$2"
# map_name="$3"
# if [ -z "$regions" ] ; then
if [ ${#regions[@]} -eq 0 ]; then
    echo 'searching all regions'
    declare -a regions=($(aws ec2 describe-regions --output json | jq '.Regions[].RegionName' | tr "\\n" " " | sed 's/"//g'))
fi
printf '{\n'
printf "    \"$map_name\": {\n"
first=true
for region in "${regions[@]}" ; do
    ami=$(aws ec2 describe-images --filters "${filters}" --region ${region} --query 'Images[*].[ImageId]' --output json | jq '.[0][0]')
    if [ $first == true ]; then
        printf "        \"${region}\": ${ami}"
    else
        printf ",\n"
        printf "        \"${region}\": ${ami}"
    fi
    first=false
done
printf '\n    }\n'
printf '}\n'