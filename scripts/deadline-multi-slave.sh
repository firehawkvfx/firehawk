#!/bin/bash

# This shell script executes a new deadline slave instance for every core present on the system.  run it once.  
# slaves should auto start on next reboot if the daemon is configured correctly.

#. /home/usr/.bashrc 
#. /home/usr/.profile

argument="$1"

echo ""
ARGS=''
remove=false

if [[ -z $argument ]] ; then
  echo "Starting one slave per core."
else
  case $argument in
    -s|--shutdown)
      ARGS='-shutdown'
      ;;
    -r|--remove)
      ARGS='-shutdown'
      remove=true
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
    digit=$(printf "%02d" $i);
    echo 'deadlineslave -name "i-'$digit'"';
    if [[ $ARGS = "-shutdown" ]]
    then
        echo 'Shut down sequentially'
        /opt/Thinkbox/Deadline10/bin/deadlineslave -name "i-$digit" -nogui $ARGS;
    else
        echo 'Launch parallel'
        /opt/Thinkbox/Deadline10/bin/deadlineslave -name "i-$digit" -nogui $ARGS &
    fi
    
done

if $remove ; then
  echo 'removing all slave .ini files from /var/lib/Thinkbox/Deadline10/slaves/'
  for i in /var/lib/Thinkbox/Deadline10/slaves/*; do
    file="$i"
    echo 'remove '$i
    rm -fv "$file"
  done
  #/usr/bin/rm -f "/var/lib/Thinkbox/Deadline10/slaves/*.ini"
fi