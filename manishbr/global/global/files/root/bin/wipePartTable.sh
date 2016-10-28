#!/bin/sh

# Programmer: Zahid Bukhari <zbukhari@dotomi.com>
# Date: Thu Apr 25 06:14:47 UTC 2013
# Purpose: To clean the boot sector(s) and reboot to PXE hopefully
# Updated 20141119 by zbukhari
# * Needed to find a re-read which works. partprobe and sync failed hdparm worked.
# * Missed exit call after no args passed check
# * Adding in test to verify a correct device is chosen.
# * Adding in completion message
# * Using 512 for MBR - no need to save the boot sector.

PATH=/bin:/sbin:/usr/bin:/usr/sbin

if [ "x$1" = "x" ]; then
	cat <<HEREDOC
Usage: $0 sda [sdb] [sdc] ... [sdN]

This program will wipe the MBR & GPT for any drives supplied then reboot.
It will also save them in case you actually needed them. This is just the
boot manager, not the partitioning table. I'm not too familiar with GPT so
use it at your own risk for that.
HEREDOC
	exit 1
fi

for drive in $*
do
	# Simple check
	test -b /dev/${drive}
	if [ $? -ne 0 ]; then
		echo Invalid block device ${drive} supplied
		continue
	fi

	# Do what you have to do
	echo Backing up MBR to /root/${drive}.mbr
	dd if=/dev/${drive} of=/root/${drive}.mbr bs=512 count=1
	echo Zeroing out MBR
	dd if=/dev/zero of=/dev/${drive} bs=512 count=1
	END=$(cat /sys/block/${drive}/size)
	echo Backing up GPT to /root/${drive}.gpt
	dd if=/dev/${drive} of=/root/${drive}.gpt bs=512 count=34 skip=$(($END - 34))
	echo Zeroing out GPT
	dd if=/dev/zero of=/dev/${drive} bs=512 count=34 skip=$(($END - 34))
	hdparm -z /dev/${drive}

	echo GPT and or MBR for ${drive} has been wiped.
done
