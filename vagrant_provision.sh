#!/bin/bash

# provision the vms in parallel

vagrant status | \
awk '
BEGIN{ tog=0; }
/^$/{ tog=!tog; }
/./ { if(tog){print $1} }
' | \
xargs -P2 -I {} vagrant up --provision {}

vagrant snapshot push