
### finally this deadline install command worked, but didn't start service immeditaly


sudo /var/tmp/DeadlineClient-10.0.23.4-linux-x64-installer.run --mode unattended --debuglevel 2 --prefix /opt/Thinkbox/Deadline10 --connectiontype Remote --noguimode true --licensemode UsageBased --launcherstartup true --slavestartup 1 --daemonuser deadlineuser --enabletls true --tlsport 4433 --httpport 8080 --proxyrootdir 192.169.0.14:4433 --proxycertificate /opt/Thinkbox/certs/Deadline10RemoteClient.pfx --proxycertificatepassword @WhatTime