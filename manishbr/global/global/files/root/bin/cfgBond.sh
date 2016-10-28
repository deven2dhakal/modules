#!/bin/sh

# Programmer: Zahid Bukhari <zbukhari@dotomi.com>
# Date: 20130708 (YYYYMMDD)
# Purpose: To ease bonded device configuration for CentOS 5/6
# Updated 20151013 by zbukhari
# - No need for a modprobe file. The Red Hat network config files take care of
#   this for us

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$HOME/bin:.

# Help
if [ "x$5" = "x" ]; then
	echo Usage: $0 master ipaddr netmask slave0 slave1 ... slaven
	echo Example: $0 bond0 10.120.1.3 255.255.255.0 em1 em2 em3
	exit
fi

# Create master bond device
echo Creating ${1} bond master
cat <<HEREDOC > /etc/sysconfig/network-scripts/ifcfg-${1}
DEVICE=${1}
BOOTPROTO=none
ONBOOT=yes
IPADDR=${2}
NETMASK=${3}
BONDING_OPTS="mode=802.3ad miimon=100 lacp_rate=1 xmit_hash_policy=layer2+3"
HEREDOC

# Loop through possible slave interfaces
i=0
for IF in $*
do
	if [ ${i} -lt 3 ]; then
		i=$((i+1))
		continue
	fi

	IFMACID=$(ip link show ${IF} | fgrep ether | awk '{ print $2 }' | tr a-z A-Z)
	if [ "x${IF}" = "x" ]; then
		echo Done with slave interfaces
		break
	else
		echo Configuring ${IF} as a slave interface of ${1}
		cat <<HEREDOC >/etc/sysconfig/network-scripts/ifcfg-${IF}
DEVICE=${IF}
#HWADDR=${IFMACID}
BOOTPROTO=none
ONBOOT=yes
MASTER=${1}
SLAVE=yes
HEREDOC
	fi

	i=$((i+1))
done

cat <<HEREDOC
For RHEL 7 based machines you will want to disable the NetworkManager.service
and ensure the network.service is enabled.  You probably want to be in a
console session.  The commands if interested are below:

systemctl stop NetworkManager.service
systemctl disable NetworkManager.service
systemctl enable network.service
systemctl start network.service
systemctl restart network.service
HEREDOC
