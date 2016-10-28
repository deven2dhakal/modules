#!/bin/sh

# Programmer: Zahid Bukhari <zbukhari@dotomi.com>
# Date: Thu May 16 19:44:38 UTC 2013
# Purpose: To recreate the AD trust between client and server

PATH=/bin:/sbin:/usr/bin:/usr/sbin

KERNEL_VERSION=$(uname -r)

case $KERNEL_VERSION in
	2.6.18-*|2.6.32-*)
		service winbind stop
		;;
	3.10.0-*)
		systemctl stop winbind
		;;
	*)
		echo Can not determine RHEL version. Exiting.
		exit 2
		;;
esac
net ads leave -U 'SVC_LinuxAdd%d0T0m!'
net ads join -U 'SVC_LinuxAdd%d0T0m!'
case $KERNEL_VERSION in
	2.6.18-*|2.6.32-*)
		service winbind stop
		;;
	3.10.0-*)
		systemctl stop winbind
		;;
	*)
		echo Can not determine RHEL version. Exiting.
		exit 2
		;;
esac
