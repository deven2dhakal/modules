#!/bin/sh

# Created by: Zahid Bukhari <zbukhari@conversantmedia.com>
# Purpose: To aide in moving IP
# Date: Tue Jun 10 18:05:13 UTC 2014
# Updated 20150617 by zbukhari
# - Added new pgm4 VIP for pgm02 and pgm03 per SYSENG-1800
# - TODO: A DNS lookup may be better because we don't want to have to keep track of all the IPs
# - TODO: Doing a quick verification as to whether or not a VIP can be stood up on a server would be wise too.
# Updated 20150618 by zbukhari
# - Removed pgm1-o01-vip option from pgm02 and pgm03

PATH=/bin:/usr/bin:/sbin:/usr/sbin

HOST=$(echo $HOSTNAME | cut -f1 -d.)
INTF=$(/sbin/ip route | awk '($1 == "default") { print $NF ; exit }')
case $HOST in
	dtord01pgm02p|dtord01pgm03p)
		VIP_IP=10.110.100.18
		DEV=$INTF
		;;

	dtord01pgm05p|dtord01pgm06p)
		echo -n "This server can handle two VIPs. Please choose one (pgm1 or pgm2): "
		read VIP_NAME
		if [ "x${VIP_NAME}" = "xpgm1" ]; then
			echo "pgm1 (i.e. pgm1-o01-vip / dtord01pgm01p / dtordpgmpn01) chosen"
			VIP_IP=10.110.100.91
		elif [ "x${VIP_NAME}" = "xpgm2" ]; then
			echo "pgm2 (i.e. pgm2-o01-vip) chosen"
			VIP_IP=10.110.100.166
		else
			echo Incorrect argument supplied. Exiting.
			exit
		fi
		DEV=$INTF
		;;

	dtord01pgm07p|dtord01pgm08p)
		VIP_IP=10.110.100.186
		DEV=$INTF
		;;

	# pgm07-o01-vip (i.e. pgm7-o01-vip)
	dtord01pgm09p|dtord01pgm10p)
		VIP_IP=10.110.100.7
		DEV=$INTF
		;;

	dtord*ydb*p)
		VIP_IP=10.110.102.61
		DEV=$INTF
		;;

	dtord*atl*p)
		VIP_IP=10.110.101.94
		DEV=$INTF
		;;

	dtord*ymg*p)
		VIP_IP=10.110.104.42
		DEV=$INTF
		;;

	*)
		echo No VIP defined for this host.
		exit 1
		;;
esac

case $1 in
	up)
		echo Bringing VIP IP ${VIP_IP} up on DEVICE ${DEV}
		ip addr add ${VIP_IP}/32 dev ${DEV}
		echo Send ARP REQUEST packets to update ARP
		arping -c 4 -U -I ${DEV} ${VIP_IP}
		echo Send ARP REPLY packets to update ARP
		arping -c 4 -A -I ${DEV} ${VIP_IP}
		;;

	down)
		echo Bringing VIP IP ${VIP_IP} down on DEVICE ${DEV}
		ip addr del ${VIP_IP}/24 dev ${DEV} 2>&1 > /dev/null
		ip addr del ${VIP_IP}/32 dev ${DEV}
		;;

	*)
		echo "Usage: $0 [up|down]"
		exit 1
		;;
esac
