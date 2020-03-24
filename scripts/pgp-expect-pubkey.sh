#!/usr/bin/expect -f

log_user 0
stty -echo

set pgp_pass [lindex $argv 0];
set secret [lindex $argv 1];

set force_conservative 0  ;# set to 1 to force conservative mode even if
			  ;# script wasn't run conservatively originally
if {$force_conservative} {
	set send_slow {1 .1}
	proc send {ignore arg} {
		sleep .1
		exp_send -s -- $arg
	}
}

# pipe encrypted secret in and use pgp pass to retrieve
set timeout 300
# stty -echo
# spawn /deployuser/scripts/pgp-decrypt-pubkey.sh $secret
# match_max 100000
# log_user 1
stty echo
# expect {
#     "Enter passphrase: " {
#         send $pgp_pass\r
#         expect eof
#     }
#     eof {}
# }
echo $secret | base64 --decode | gpg -dq --no-tty --passphrase $pgp_pass
# -q --no-tty --passphrase thepassphraseyouchoseforthiskey