#!/bin/bash
# observe latest log file
tail -f $(ls -t /var/log/Thinkbox/Deadline10/deadlinepulse* | head -1)