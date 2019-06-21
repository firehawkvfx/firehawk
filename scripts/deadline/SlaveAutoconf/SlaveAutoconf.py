'''
    Stolen from Gavin's great example on this forum thread:
    https://forums.thinkboxsoftware.com/viewtopic.php?f=11&t=13396#p59978
'''

from System.Diagnostics import *
from System.IO import *
from System import TimeSpan

from Deadline.Events import *
from Deadline.Scripting import *

import re
import sys
import os
import subprocess
import traceback
import shlex

SLAVE_NAME_PREFIX_CLOUD = "ip-"
POOLS_CLOUD = ["one", "two", "three"] # Example: ["one", "two", "three"]
GROUPS_CLOUD = ["cloud"]

SLAVE_NAME_PREFIX_CLOUD_WORKSTATION = "cloud_workstation"
POOLS_CLOUD_WORKSTATION = ["one", "two", "three"] # Example: ["one", "two", "three"]
GROUPS_CLOUD_WORKSTATION = ["cloud_workstation"]

SLAVE_NAME_PREFIX_LOCAL = "workstation"
POOLS_LOCAL = ["one", "two", "three"] # Example: ["one", "two", "three"]
GROUPS_LOCAL = ["local"]

LISTENING_PORT=None # or 27100


def GetDeadlineEventListener():
    return ConfigSlaveEventListener()


def CleanupDeadlineEventListener(eventListener):
    eventListener.Cleanup()


class ConfigSlaveEventListener (DeadlineEventListener):
    def __init__(self):
        self.OnSlaveStartedCallback += self.OnSlaveStarted

    def Cleanup(self):
        del self.OnSlaveStartedCallback

    # This is called every time the Slave starts
    def OnSlaveStarted(self, slavename):
        # Load slave settings for when we needed
        slave = RepositoryUtils.GetSlaveSettings(slavename, True)

        # Skip over Slaves that don't match the prefix
        if slavename.lower().startswith(SLAVE_NAME_PREFIX_CLOUD.lower()):
            print("Slave automatic configuration CLOUD for {0}".format(slavename))
            newPools = POOLS_CLOUD
            newGroups = GROUPS_CLOUD
        elif slavename.lower().startswith(SLAVE_NAME_PREFIX_CLOUD_WORKSTATION.lower()):
            print("Slave automatic configuration CLOUD_WORKSTATION for {0}".format(slavename))
            newPools = POOLS_CLOUD_WORKSTATION
            newGroups = GROUPS_CLOUD_WORKSTATION
        elif slavename.lower().startswith(SLAVE_NAME_PREFIX_LOCAL.lower()):
            print("Slave automatic configuration LOCAL for {0}".format(slavename))
            newPools = POOLS_LOCAL
            newGroups = GROUPS_LOCAL
        else:
            return
        # if didn't exit, then continue to setup pools and groups
        for x in slave.Pools:
            if x not in newPools:
                newPools.append(x)
        
        slave.Pools = newPools 
        print("Updated slave pools to be '%s'" % ",".join(newPools))
        
        for x in slave.Groups:
            if x not in newGroups:
                newGroups.append(x)
        
        slave.Groups = newGroups 
        print("Updated slave groups to be '%s'" % ",".join(newGroups))
        
        # Set up the listening port
        if LISTENING_PORT:
            print("   Configuring Slave to listen on port {0}".format(LISTENING_PORT))
            slave.SlaveListeningPort = LISTENING_PORT
            slave.SlaveOverrideListeningPort = True
        else:
            print("   Configuring Slave to use random listening port".format(LISTENING_PORT))
            slave.SlaveOverrideListeningPort = False

        # Save any changes we've made back to the database
        RepositoryUtils.SaveSlaveSettings(slave)