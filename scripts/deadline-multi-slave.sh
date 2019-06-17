#!/bin/bash

# This shell script executes a new deadline slave instance for every core present on the system.  run it once.  
# slaves should auto start on next reboot if the daemon is configured correctly.

argument="$1"

echo ""
ARGS=''
if [[ -z $argument ]] ; then
  echo "Starting one slave per core."
else
  case $argument in
    -s|--shutdown)
      ARGS='-shutdown'
      ;;
    -r|--remove)
      REMOVE=True
      ;;
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

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
    /opt/Thinkbox/Deadline10/bin/deadlineslave -name "i-$digit" -nogui $ARGS &
done