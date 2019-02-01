
Can't yet achieve functioning settings via the command line installer.  this is what we are currently testing.

sudo /var/tmp/DeadlineClient-10.0.23.4-linux-x64-installer.run --mode unattended --debuglevel 2 --prefix /opt/Thinkbox/Deadline10 --connectiontype Remote --dbsslcertificate /opt/Thinkbox/DeadlineDatabase10/certs/Deadline10Client.pfx --dbsslpassword @WhatTime --noguimode false --licensemode UsageBased --launcherstartup true --slavestartup true --daemonuser deadlineuser --enabletls true --tlsport 4433 --httpport 8080 --servercert /opt/Thinkbox/certs/deadlinedb.firehawkvfx.com.pfx --cacert /opt/Thinkbox/certs/ca.crt --proxyrootdir 192.169.0.14:4433 --proxycertificate /opt/Thinkbox/certs/Deadline10RemoteClient.pfx --proxycertificatepassword @WhatTime

Below is an example deadline.ini file after install located in /var/lib/Thinkbox/Deadline10/deadline.ini
This was functioning.

[Deadline]
HttpListenPort=8080
TlsListenPort=4433
TlsServerCert=/opt/Thinkbox/certs/deadlinedb.firehawkvfx.com.pfx
TlsCaCert=/opt/Thinkbox/certs/ca.crt
TlsAuth=True
LicenseMode=UsageBased
LicenseServer=
Region=
LauncherListeningPort=17000
LauncherServiceStartupDelay=60
AutoConfigurationPort=17001
SlaveStartupPort=17003
SlaveDataRoot=
RestartStalledSlave=false
NoGuiMode=false
LaunchSlaveAtStartup=0
AutoUpdateOverride=
IncludeProxyServerInLauncherMenu=true
IncludeRCSInLauncherMenu=true
ConnectionType=Repository
NetworkRoot=/opt/Thinkbox/DeadlineRepository10
DbSSLCertificate=/opt/Thinkbox/DeadlineDatabase10/certs/Deadline10Client.pfx
NetworkRoot0=/opt/Thinkbox/DeadlineRepository10;/opt/Thinkbox/DeadlineDatabase10/certs/Deadline10Client.pfx



##### this is another attempt after full reinstall

sudo /var/tmp/DeadlineClient-10.0.23.4-linux-x64-installer.run --mode unattended --debuglevel 2 --prefix /opt/Thinkbox/Deadline10 --connectiontype Remote --dbsslcertificate /opt/Thinkbox/DeadlineDatabase10/certs/Deadline10Client.pfx --dbsslpassword @WhatTime --noguimode false --licensemode UsageBased --launcherstartup true --slavestartup true --daemonuser deadlineuser --enabletls true --tlsport 4433 --httpport 8080 --servercert /opt/Thinkbox/certs/deadlinedb.firehawkvfx.com.pfx --cacert /opt/Thinkbox/certs/ca.crt --proxyrootdir 192.169.0.14:4433 --proxycertificate /opt/Thinkbox/certs/Deadline10RemoteClient.pfx --proxycertificatepassword @WhatTime

LicenseMode=UsageBased
LicenseServer=
Region=
LauncherListeningPort=17000
LauncherServiceStartupDelay=60
AutoConfigurationPort=17001
SlaveStartupPort=17003
SlaveDataRoot=
RestartStalledSlave=false
NoGuiMode=false
LaunchSlaveAtStartup=1
AutoUpdateOverride=
ConnectionType=Remote
ProxyRoot=192.169.0.14:4433
ProxyUseSSL=True
ProxySSLCertificate=/opt/Thinkbox/certs/Deadline10RemoteClient.pfx
ProxyRoot0=192.169.0.14:4433;/opt/Thinkbox/certs/Deadline10RemoteClient.pfx

#### another attempt, only matching what was sepcified during install without unnattended mode.  these settings work immediately and the service starts.
# however, note that noguimode is false, even though this is installed on a headless node.

LicenseMode=UsageBased
LicenseServer=
Region=
LauncherListeningPort=17000
LauncherServiceStartupDelay=60
AutoConfigurationPort=17001
SlaveStartupPort=17003
SlaveDataRoot=
RestartStalledSlave=false
NoGuiMode=false
LaunchSlaveAtStartup=1
AutoUpdateOverride=
ConnectionType=Remote
ProxyRoot=192.169.0.14:4433
ProxyUseSSL=True
ProxySSLCertificate=/opt/Thinkbox/certs/Deadline10RemoteClient.pfx
ProxyRoot0=192.169.0.14:4433;/opt/Thinkbox/certs/Deadline10RemoteClient.pfx

### Below are my attempts at getting equivalent settings, but the service doesn't start automatically, and there are no logs.  

sudo /var/tmp/DeadlineClient-10.0.23.4-linux-x64-installer.run --mode unattended --debuglevel 2 --prefix /opt/Thinkbox/Deadline10 --connectiontype Remote --noguimode false --licensemode UsageBased --launcherstartup true --slavestartup 1 --daemonuser deadlineuser --enabletls true --tlsport 4433 --httpport 8080 --proxyrootdir 192.169.0.14:4433 --proxycertificate /opt/Thinkbox/certs/Deadline10RemoteClient.pfx --proxycertificatepassword @WhatTime


LicenseMode=UsageBased
LicenseServer=
Region=
LauncherListeningPort=17000
LauncherServiceStartupDelay=60
AutoConfigurationPort=17001
SlaveStartupPort=17003
SlaveDataRoot=
RestartStalledSlave=false
NoGuiMode=false
LaunchSlaveAtStartup=1
AutoUpdateOverride=
ConnectionType=Remote
ProxyRoot=192.169.0.14:4433
ProxyUseSSL=True
ProxySSLCertificate=/opt/Thinkbox/certs/Deadline10RemoteClient.pfx
ProxyRoot0=192.169.0.14:4433;/opt/Thinkbox/certs/Deadline10RemoteClient.pfx

#### if I manually execute deadline launcher, I get these errors, seemingly related to trying to find a display.  if this is because noguimode=false, it doesn't make sense, since the deadline.ini file from the functional attended install had this setting originally.

[deadlineuser@ip-10-0-1-74 Deadline10]$ /opt/Thinkbox/Deadline10/bin/deadlinelauncher
Auto Configuration: Picking configuration based on: ip-10-0-1-74.ap-southeast-2.compute.internal / 10.0.1.74
Auto Configuration: No auto configuration could be detected, using local configuration
Launcher Thread - Launcher thread initializing...
creating local listening socket on an available port...
updating local listening port in launcher file: 38169
Launcher Thread - Launcher thread listening on port 17000
Launching Slave: 
QXcbConnection: Could not connect to display 
Stacktrace:

  at <unknown> <0xffffffff>
  at (wrapper managed-to-native) Python.Runtime.Runtime.PyObject_Call (intptr,intptr,intptr) <0x0006f>
  at Python.Runtime.ImportHook.__import__ (intptr,intptr,intptr) <0x0032f>
  at (wrapper native-to-managed) Python.Runtime.ImportHook.__import__ (intptr,intptr,intptr) <0x000c9>
  at <unknown> <0xffffffff>
  at (wrapper managed-to-native) Python.Runtime.Runtime.PyImport_ImportModule (string) <0x0007b>
  at Python.Runtime.PythonEngine.ImportModule (string) <0x00017>
  at FranticX.Scripting.PythonNetScriptEngine.ImportModule (string,bool) <0x0032d>
  at Deadline.Scripting.DeadlineScriptManager.ImportModule (string,bool) <0x0002d>
  at DeadlineSlave.DeadlineSlaveApp.Main (string[]) <0x0051e>
  at (wrapper runtime-invoke) <Module>.runtime_invoke_int_object (object,intptr,intptr,intptr) <0x00103>

Native stacktrace:

	/opt/Thinkbox/Deadline10/bin/mono() [0x4b0088]
	/lib64/libpthread.so.0(+0xf5d0) [0x7f4237fc35d0]
	/lib64/libc.so.6(gsignal+0x37) [0x7f4237a07207]
	/lib64/libc.so.6(abort+0x148) [0x7f4237a088f8]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Core.so.5(+0x8d735) [0x7f4224d97735]
	/opt/Thinkbox/Deadline10/lib/platforms/libqxcb.so(+0x2e912) [0x7f4219b01912]
	/opt/Thinkbox/Deadline10/lib/platforms/libqxcb.so(+0x304de) [0x7f4219b034de]
	/opt/Thinkbox/Deadline10/lib/platforms/libqxcb.so(+0x4133b) [0x7f4219b1433b]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Gui.so.5(_ZN27QPlatformIntegrationFactory6createERK7QStringRK11QStringListRiPPcS2_+0x91) [0x7f422555abf1]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Gui.so.5(_ZN22QGuiApplicationPrivate25createPlatformIntegrationEv+0x5a1) [0x7f4225565f21]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Gui.so.5(_ZN22QGuiApplicationPrivate21createEventDispatcherEv+0x2d) [0x7f4225566a6d]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Core.so.5(_ZN16QCoreApplication4initEv+0x211) [0x7f4224f86e31]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Core.so.5(_ZN16QCoreApplicationC1ER23QCoreApplicationPrivate+0x26) [0x7f4224f86ea6]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Gui.so.5(_ZN15QGuiApplicationC2ER22QGuiApplicationPrivate+0x9) [0x7f42255678b9]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Widgets.so.5(_ZN12QApplicationC1ERiPPci+0x3d) [0x7f4225d3cffd]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/QtWidgets.so(+0x2a5129) [0x7f42266a4129]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/QtWidgets.so(+0x2a51f9) [0x7f42266a41f9]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/sip.so(+0x9624) [0x7f42236fd624]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(+0xbe53f) [0x7f422dda853f]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyObject_Call+0x43) [0x7f422dd3df03]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyEval_EvalFrameEx+0x3aa6) [0x7f422ddf3436]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyEval_EvalCodeEx+0x80d) [0x7f422ddf905d]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyEval_EvalCode+0x32) [0x7f422ddf9192]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyImport_ExecCodeModuleEx+0x8c) [0x7f422de0deac]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(+0x12470f) [0x7f422de0e70f]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(+0x125109) [0x7f422de0f109]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyImport_ImportModuleLevel+0x2aa) [0x7f422de0fe3a]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(+0x10398f) [0x7f422dded98f]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyObject_Call+0x43) [0x7f422dd3df03]
	[0x40c99550]

Debug info from gdb:


=================================================================
Got a SIGABRT while executing native code. This usually indicates
a fatal error in the mono runtime or one of the native libraries 
used by your application.
=================================================================

QXcbConnection: Could not connect to display 
Stacktrace:

  at <unknown> <0xffffffff>
  at (wrapper managed-to-native) Python.Runtime.Runtime.PyObject_Call (intptr,intptr,intptr) <0x0006f>
  at Python.Runtime.ImportHook.__import__ (intptr,intptr,intptr) <0x0032f>
  at (wrapper native-to-managed) Python.Runtime.ImportHook.__import__ (intptr,intptr,intptr) <0x000c9>
  at <unknown> <0xffffffff>
  at (wrapper managed-to-native) Python.Runtime.Runtime.PyObject_Call (intptr,intptr,intptr) <0x0006f>
  at Python.Runtime.ImportHook.__import__ (intptr,intptr,intptr) <0x0032f>
  at (wrapper native-to-managed) Python.Runtime.ImportHook.__import__ (intptr,intptr,intptr) <0x000c9>
  at <unknown> <0xffffffff>
  at (wrapper managed-to-native) Python.Runtime.Runtime.PyObject_Call (intptr,intptr,intptr) <0x0006f>
  at Python.Runtime.ImportHook.__import__ (intptr,intptr,intptr) <0x0032f>
  at (wrapper native-to-managed) Python.Runtime.ImportHook.__import__ (intptr,intptr,intptr) <0x000c9>
  at <unknown> <0xffffffff>
  at (wrapper managed-to-native) Python.Runtime.Runtime.PyImport_ExecCodeModule (string,intptr) <0x00083>
  at Python.Runtime.PythonEngine.ModuleFromString (string,string,string,bool) <0x0012b>
  at FranticX.Scripting.PythonNetScriptEngine.ExecuteFile (string,string,bool) <0x000df>
  at Deadline.Scripting.DeadlineScriptManager.CreateModuleFromFile (string,string,bool) <0x00074>
  at Deadline.Scripting.DeadlineScriptManager.CreateModuleFromFile (string,string) <0x00020>
  at DeadlineLauncher.DeadlineLauncherApp.Main (string[]) <0x0112c>
  at (wrapper runtime-invoke) <Module>.runtime_invoke_int_object (object,intptr,intptr,intptr) <0x00103>

Native stacktrace:

	/opt/Thinkbox/Deadline10/bin/mono() [0x4b0088]
	/lib64/libpthread.so.0(+0xf5d0) [0x7f9eff6575d0]
	/lib64/libc.so.6(gsignal+0x37) [0x7f9eff09b207]
	/lib64/libc.so.6(abort+0x148) [0x7f9eff09c8f8]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Core.so.5(+0x8d735) [0x7f9ed3914735]
	/opt/Thinkbox/Deadline10/lib/platforms/libqxcb.so(+0x2e912) [0x7f9ec2c5c912]
	/opt/Thinkbox/Deadline10/lib/platforms/libqxcb.so(+0x304de) [0x7f9ec2c5e4de]
	/opt/Thinkbox/Deadline10/lib/platforms/libqxcb.so(+0x4133b) [0x7f9ec2c6f33b]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Gui.so.5(_ZN27QPlatformIntegrationFactory6createERK7QStringRK11QStringListRiPPcS2_+0x91) [0x7f9ed1db4bf1]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Gui.so.5(_ZN22QGuiApplicationPrivate25createPlatformIntegrationEv+0x5a1) [0x7f9ed1dbff21]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Gui.so.5(_ZN22QGuiApplicationPrivate21createEventDispatcherEv+0x2d) [0x7f9ed1dc0a6d]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Core.so.5(_ZN16QCoreApplication4initEv+0x211) [0x7f9ed3b03e31]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Core.so.5(_ZN16QCoreApplicationC1ER23QCoreApplicationPrivate+0x26) [0x7f9ed3b03ea6]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Gui.so.5(_ZN15QGuiApplicationC2ER22QGuiApplicationPrivate+0x9) [0x7f9ed1dc18b9]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/../../../libQt5Widgets.so.5(_ZN12QApplicationC1ERiPPci+0x3d) [0x7f9ed2596ffd]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/QtWidgets.so(+0x2a5129) [0x7f9ed2efe129]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/PyQt5/QtWidgets.so(+0x2a51f9) [0x7f9ed2efe1f9]
	/opt/Thinkbox/Deadline10/bin/python/lib/python2.7/site-packages/sip.so(+0x9624) [0x7f9ed336a624]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(+0xbe53f) [0x7f9ef4a8b53f]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyObject_Call+0x43) [0x7f9ef4a20f03]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyEval_EvalFrameEx+0x3aa6) [0x7f9ef4ad6436]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyEval_EvalCodeEx+0x80d) [0x7f9ef4adc05d]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyEval_EvalCode+0x32) [0x7f9ef4adc192]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyImport_ExecCodeModuleEx+0x8c) [0x7f9ef4af0eac]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(+0x12470f) [0x7f9ef4af170f]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(+0x125109) [0x7f9ef4af2109]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyImport_ImportModuleLevel+0x2aa) [0x7f9ef4af2e3a]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(+0x10398f) [0x7f9ef4ad098f]
	/opt/Thinkbox/Deadline10/bin/libpython2.7.so(PyObject_Call+0x43) [0x7f9ef4a20f03]
	[0x40bb4150]

Debug info from gdb:


=================================================================
Got a SIGABRT while executing native code. This usually indicates
a fatal error in the mono runtime or one of the native libraries 
used by your application.
=================================================================

Aborted


### finally this worked, but didn't start service immeditaly


sudo /var/tmp/DeadlineClient-10.0.23.4-linux-x64-installer.run --mode unattended --debuglevel 2 --prefix /opt/Thinkbox/Deadline10 --connectiontype Remote --noguimode true --licensemode UsageBased --launcherstartup true --slavestartup 1 --daemonuser deadlineuser --enabletls true --tlsport 4433 --httpport 8080 --proxyrootdir 192.169.0.14:4433 --proxycertificate /opt/Thinkbox/certs/Deadline10RemoteClient.pfx --proxycertificatepassword @WhatTime