#!/bin/bash
file=$1
lastchar=$(tail -c1 $file)
if [[ $lastchar ]] ; then
    if [ -f "$file" ]; then
        echo 'ensure single blank line at EOF'
        echo ''>>$file
    fi
fi
lastchar2=$(tail -c2 $file)
if [[ $lastchar2 ]] ; then
    if [ -f "$file" ]; then
        echo 'ensure 2nd single blank line at EOF'
        echo ''>>$file
    fi
fi
#[[ $(tail -c1 $file) && -f $file ]]&&echo ''>>$file