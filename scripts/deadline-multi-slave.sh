#!/bin/bash

# This shell script executes a new deadline slave instance for every core present on the system

unset CPUCORES
unset SLAVECOUNT

declare $( cat /proc/cpuinfo | grep "cpu cores" | awk -F: '{ num+=1 } END{ 
    print "CPUCORES="num
    print "SLAVECOUNT="num-1
    }' )

echo "CPUCORES=$CPUCORES"
echo "SLAVECOUNT=$SLAVECOUNT"

for i in $(seq $SLAVECOUNT $END); do 
    digit=$(printf "%02d" $i)
    echo 'deadlineslave -name "i-'$digit'"'
    /opt/Thinkbox/Deadline10/bin/deadlineslave -name "i-$digit" -nogui &
done