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

startslave () {
  local digit=$1
  echo 'Launch Slave Instance "i-$digit"'
  su deadlineuser -c '/opt/Thinkbox/Deadline10/bin/deadlineslave -name "i-$digit" -nogui'
  # su deadlineuser -c 'disown'
}

stopslave () {
  local digit=$1
  echo 'shutdown Slave Instance i-'$digit
  su deadlineuser -c '/opt/Thinkbox/Deadline10/bin/deadlineslave -name "i-$digit" -nogui -shutdown;'
  #disown
  echo 'end i-'$digit
  file=/var/lib/Thinkbox/Deadline10/slaves/i-"$digit".ini
  if $remove ; then
    echo 'remove '$file
    rm -fv "$file"
  fi
  # su deadlineuser -c 'disown'
}

for i in $(seq 2 $END); do 
    digit=$(printf "%02d" $i);
    echo 'deadlineslave -name "i-'$digit'"';
    if [[ $ARGS = "-shutdown" ]]
    then
        # {
        #   echo 'Shut down sequentially i-$digit'
        #   su deadlineuser -c '/opt/Thinkbox/Deadline10/bin/deadlineslave -name "i-$digit" -nogui $ARGS;'
        #   disown
        # }&
        stopslave "$digit" &
    else
        # {
        #   echo 'Launch parallel i-$digit'
        #   su deadlineuser -c '/opt/Thinkbox/Deadline10/bin/deadlineslave -name "i-$digit" -nogui $ARGS'
        #   disown
        #   #FILE=/var/lib/Thinkbox/Deadline10/slaves/i-$digit.ini
        #   #grep -q '^LaunchSlaveAtStartup' FILE && sed -i 's/^LaunchSlaveAtStartup.*/LaunchSlaveAtStartup=False/' FILE || echo 'LaunchSlaveAtStartup=False' >> FILE
        # }&
        startslave "$digit" &
    fi
done

# if $remove ; then
#   echo 'removing all slave .ini files from /var/lib/Thinkbox/Deadline10/slaves/'
#   for i in /var/lib/Thinkbox/Deadline10/slaves/*; do
#     file="$i"
#     echo 'remove '$i
#     rm -fv "$file"
#   done
#   #/usr/bin/rm -f "/var/lib/Thinkbox/Deadline10/slaves/*.ini"
# fi