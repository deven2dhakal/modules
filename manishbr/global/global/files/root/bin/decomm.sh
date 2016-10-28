#!/bin/sh

# Created by: Zahid Bukhari <zbukhari@conversantmedia.com>
# Date: Wed Aug 27 20:40:12 UTC 2014
# Purpose: To safely decomm a server and perform other decomm tasks automaticall
# Updated by zbukhari: Added in reqiured reboot or shutdown option
# 20141124 Updated by zbukhari:
# - Adding in command to set BMC to DHCP
# 20150624 Updated by zbukhari
# - Adding in method to purge puppet key remotely - safely.

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/dell/srvadmin/bin
PATH=$PATH:/opt/dell/srvadmin/sbin:/opt/dell/toolkit/bin
PATH=$PATH:/usr/local/bin:/usr/local/sbin:/root/bin:.

case "$1" in
	shutdown|reboot)
		;;
	*)
		echo "Usage: $0 [shutdown|reboot]"
		exit 1
		;;
esac

echo This script will remove AD auth, wipe out the boot sector, purge puppet keys,
echo set DRAC to DHCP and reboot
echo " "
echo -n "Are you sure? (y/n): "
read yorn

if [ "x${yorn}" != "xy" ]; then
	echo Exiting script
	exit 0
fi

MAKE=$(dmidecode -s system-manufacturer)
MODEL=$(dmidecode -s system-product-name)
SERIAL=$(dmidecode -s system-serial-number)

echo "You have 30 seconds to change your mind (i.e. CTRL + C)"
sleep 30
echo Serial Number: $SERIAL
if [ "x$MAKE" = "xDell Inc." ]; then
	echo Setting Dell specific items:
	t=0
	syscfg lcp --ipaddrsrc=dhcp
	t=$(($?+i))
	syscfg lcp --nicselection=dedicated
	t=$(($?+i))
	syscfg lcp --autoneg=enable
	t=$(($?+i))
	syscfg lcp --dnsdhcp=enable
	t=$(($?+i))
	syscfg lcp --dnsracname=dell-${SERIAL}
	t=$(($?+i))
	syscfg lcp --dnsregisterrac=enable
	t=$(($?+i))
	syscfg lcp --domainnamednsdhcp=enable
	t=$(($?+i))

	if [ $t -ne 0 ]; then
		echo Setting DRAC to DHCP failed.  Be sure to ensure acces via Waheed during pre-kick phase.
	fi
fi

echo Leaving Active Directory Domain
net ads leave -U 'SVC_LinuxAdd%d0T0m!'
echo Removing Puppet key
curl -k -qs "https://dtord01ops03p.dc.dotomi.net/cgi-bin/puppet-cert-clean.cgi?fqdn=${HOSTNAME}&md5sum=$(md5sum /var/lib/puppet/ssl/certs/${HOSTNAME}.pem | awk '{print $1}')"
echo Saving sda boot sector and wiping
dd if=/dev/sda of=/root/sda.bs bs=446 count=1
dd if=/dev/zero of=/dev/sda bs=446 count=1
echo In case root is sdm as on R720xds with an H310 mini RAID
echo Saving sdm boot sector and wiping
dd if=/dev/sdm of=/root/sdm.bs bs=446 count=1
dd if=/dev/zero of=/dev/sdm bs=446 count=1

echo Setting BMC to use DHCP
ipmitool lan set 1 ipsrc dhcp

echo Setting BMC password to default
ipmitool user set password 2 calvin

if [ "$1" = "shutdown" ]; then
	shutdown -h now
elif [ "$1" = "reboot" ]; then
	reboot
fi
