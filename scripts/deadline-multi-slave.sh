#!/bin/bash

# This shell script removes all existing claves based on the files in path /var/lib/Thinkbox/Deadline10/slaves.
# after removing all slaves, if executes a new deadline slave instance for every 4 cores present on the system.  it should execute on boot

argument="$1"

echo ""
ARGS=''
remove=false
delaytime=2
configfiledelay=2

if [[ -z $argument ]] ; then
  echo "Starting one slave per core."
else
  case $argument in
    -s|--shutdown)
      ARGS='-shutdown'
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
  local file=/var/lib/Thinkbox/Deadline10/slaves/i-"$digit".ini

  # test digit was provided, else an invalid name may be produced.
  re='^[0-9]+$'
  
  if ! [[ $digit =~ $re ]] ; then
    echo "error: Not a number $digit" >&2; exit 1
  fi

  local name="i-$digit"
  echo "Launch Slave Instance $name"
  su --login -s /bin/bash -c "/opt/Thinkbox/Deadline10/bin/deadlineslave -name $name -nogui;" deadlineuser

  sleep $configfiledelay
}

stopslave () {
  local digit=$1
  local file=$2
  local remove=$3
  #local file=/var/lib/Thinkbox/Deadline10/slaves/i-"$digit".ini
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

  if $remove ; then
    echo 'remove '$file
    rm -fv "$file"
  fi
  # su deadlineuser -c 'disown'
}
echo ""
echo "### ALL PRIOR SLAVES REMOVED ###"
echo ""
# remove all slaves based on the contents of path
existingFiles=/var/lib/Thinkbox/Deadline10/slaves/i-*.ini
for file in $existingFiles
do
  echo "Processing $file file for removal of existing slaves..."
  basename=$(basename $file)

  digit=$(echo $basename | sed -e 's/[^(0-9|)]//g' | sed -e 's/|/,/g')
  
  re='^[0-9]+$'
  if [[ $digit =~ $re ]] ; then
    echo $digit
    stopslave "$digit" "$file" "true" &
    sleep $delaytime
  fi
done

# normal behaviour is to relaunch.  unless -s is specified then nothing will be done.
for i in $(seq $SLAVECOUNT $END); do 
    digit=$(printf "%02d" $i);
    name="i-$digit";
    file=/var/lib/Thinkbox/Deadline10/slaves/i-"$digit".ini
    
    if ! [[ $ARGS = "-shutdown" ]] ; then
        echo "start deadlineslave -name $name";
        startslave "$digit" &
        # delay to not overload db with requests.
        sleep $delaytime

        while [ ! -f $file ]
        do
          sleep 2
        done

        # Ensure slave launch at startup is false.  if 96 cores become 16 after between launches, we don't want extra slaves being launched.
        # grep -q "^LaunchSlaveAtStartup=" $file && sed "s/^LaunchSlaveAtStartup=.*/LaunchSlaveAtStartup=False/" -i $file || sed "$ a\LaunchSlaveAtStartup=False" -i $file
        
    fi
done