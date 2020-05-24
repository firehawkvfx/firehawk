#!/bin/bash
echo "...Will detect if interrupt file is found"
FILE=$TF_VAR_firehawk_path/interrupt
inotifywait -e create $FILE & wait_pid=$!
if [[ -f $FILE ]]; then
    kill $wait_pid
else
    wait $wait_pid
fi
echo "...Interrupt file exists, continuing"