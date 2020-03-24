#!/bin/bash
# observe latest log file
tail -f $(ls -t /var/log/Thinkbox/Deadline10/deadlinercs* | head -1)