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
    print "SLAVECOUNT="(num/4)-1
    }' )

echo "CPUCORES=$CPUCORES"
echo "SLAVECOUNT=$SLAVECOUNT"

startslave () {
  local digit=$1

  # test digit was provided, else an invalid name may be produced.
  re='^[0-9]+$'
  
  if ! [[ $digit =~ $re ]] ; then
    echo "error: Not a number $digit" >&2; exit 1
  fi

  local name="i-$digit"
  echo "Launch Slave Instance $name"
  su --login -s /bin/bash -c "/opt/Thinkbox/Deadline10/bin/deadlineslave -name $name -nogui;" deadlineuser
}

stopslave () {
  local digit=$1
  
  # test digit was provided, else an invalid name may be produced.
  re='^[0-9]+$'
  
  if ! [[ $digit =~ $re ]] ; then
    echo "error: Not a number $digit" >&2; exit 1
  fi
  
  local name="i-$digit"
  echo "shutdown Slave Instance $name"
  su --login -s /bin/bash -c "/opt/Thinkbox/Deadline10/bin/deadlineslave -name $name -nogui -shutdown;" deadlineuser
  #disown
  echo 'end i-'$digit

  file=/var/lib/Thinkbox/Deadline10/slaves/i-"$digit".ini
  if $remove ; then
    echo 'remove '$file
    rm -fv "$file"
  fi
  # su deadlineuser -c 'disown'
}

for i in $(seq $SLAVECOUNT $END); do 
    digit=$(printf "%02d" $i);
    name="i-$digit";

    echo "deadlineslave -name $name";
    if [[ $ARGS = "-shutdown" ]]
    then
        stopslave "$digit" &
        sleep 1
    else
        startslave "$digit" &
        sleep 1
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