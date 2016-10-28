#!/bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Ensure no output is sent back
exec > /dev/null
exec 2> /dev/null

# Act if the state file has a last modification that's greater than below
STALE_TIME=3600

# You most likely don't need to edit below this line.
LOGGER="logger fixStalePuppet:"
STATE_FILE=$(puppet config print --section agent statefile)
PID_FILE=$(puppet config print --section agent pidfile)
NOW=$(date +%s)
MOD_TIME=$(stat -c %Y $STATE_FILE)
# We'll only act on this if there's an issue
HUNG_RUN_PIDS=$(pgrep -u root -d ' ' -f 'puppet agent: applying configuration')

EL_VER=$(lsb_release -r | cut -f2- -d: | cut -f1 -d. | xargs)

if [ "x$EL_VER" = "x" ]; then
	$LOGGER Can not determine version. Exiting.
	exit 2
fi

# Eventually we can remove the test for the puppet PID file and or process but
# we first need an audit in case puppet was shut off anywhere hence the slight
# complexity in the if then statement below.
if [ $((NOW - MOD_TIME)) -gt $STALE_TIME -a "x$HUNG_RUN_PIDS" != "x" -a -f $PID_FILE -a -d $(<PID_FILE) ]; then
	$LOGGER Puppet state file is older than $STALE_TIME seconds. Checking for hung runs.

	# Be gentle
	for pid in $HUNG_RUN_PIDS
	do
		kill -TERM $pid
	done

	# Be patient
	sleep 10

	# No more Mr. Nice Guy
	for pid in $HUNG_RUN_PIDS
	do
		test -d /proc/${pid} && kill -KILL $pid
	done

	case $EL_VER in
		[456])
			service puppet restart
			;;
		7)
			systemctl restart puppet
			;;
		*)
			$LOGGER Unexpected version. Contact SYSENG.
			exit 2
			;;
	esac
fi
