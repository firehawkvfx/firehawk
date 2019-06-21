#!/bin/bash
argument="$1"

DATE=`date '+%Y-%m-%d %H:%M:%S'`
echo "Example service started at ${DATE}" | systemd-cat -p info
echo "Argument $1"

echo ""
ARGS=''
remove=false
delaytime=2
configfiledelay=2

if [[ -z $argument ]] ; then
  echo "Starting multiple slave instances."

  deadlinestatus=$(sudo service deadline10launcher status)
  echo "deadline status: $deadlinestatus"

  sudo service deadline10launcher start

  deadlinestatus=$(sudo service deadline10launcher status)
  echo "deadline status: $deadlinestatus"

  /usr/bin/dlmultislave.sh

  echo "Running...";
  while :
  do
  sleep 30;
  done

else
  case $argument in
    -s|--shutdown)
      ARGS='-shutdown'

      /usr/bin/dlmultislave.sh -s
      
      ;;
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

# https://www.linode.com/docs/quick-answers/linux/start-service-at-boot/

