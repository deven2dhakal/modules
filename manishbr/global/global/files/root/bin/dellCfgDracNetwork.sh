#!/bin/sh

# Programmer: Zahid Bukhari <zbukhari@dotomi.com>
# Date: Tue May  7 09:16:32 UTC 2013
# Purpose: To configure DRAC networking
# Updated 20140723 by zbukhari
# * Changed defgw ipaddr to a.b.0.1
# Updated 20140817 by zbukhari
# * Changed int to dc.dotomi.net
# Updated 20141028 by zbukhari
# * We don't use dtord01ops02p anymore
# Updated 20150408 by zbukhari
# * Set ipsrc to static. Good form.

PATH=/bin:/sbin:/usr/bin:/usr/sbin

if [ "x$1" = "x" ]; then
	DRACHOSTNAME=$(echo $HOSTNAME | sed 's/\./r./')
	DRACIP=$(dig $DRACHOSTNAME A +short)
else
	DRACHOSTNAME=$(echo $1 | sed 's/\./r./')
	DRACIP=$(dig $1 A +short)
fi

cat <<HEREDOC
You can also pass the DRAC hostname or the current hosts DRAC name will be
used

Usage: $0 [dtiad05mgr01pr.dc.dotomi.net]
HEREDOC

echo Sleeping for 5 seconds in case you want to back out.
sleep 5

ipmitool delloem lan set dedicated
ipmitool lan set 1 ipsrc static
ipmitool lan set 1 ipaddr $DRACIP
ipmitool lan set 1 defgw ipaddr $(echo $DRACIP | cut -f1-2 -d.).0.1
ipmitool lan set 1 netmask 255.255.0.0
ipmitool lan set 1 snmp 'dotom!'
