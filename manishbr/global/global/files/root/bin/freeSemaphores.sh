#!/bin/sh

# Programmer: Zahid Bukhari <zbukhari@conversantmedia.com>
# Date: Mon Jul 28 23:52:52 UTC 2014
# Purpose: To free unused semaphores or semaphores which have lost their PID
# Updated by Zahid Bukhari Tue Aug 26 19:31:52 UTC 2014
# * Removed all sorts of clustery stuff
# * Adjusting for a group of PIDs which happens esp. w/ sfcbd
# * Adjusting for when a PID within a group of PIDs for a SEM exists (break)

PATH=/bin:/sbin:/usr/bin:/usr/sbin

for SEM_ID in $(ipcs -s | grep ^0x | awk '{print $2}')
do
	# Some semaphore IDs have multiple PIDs associated with them.
	# We need to investigate this further.
	SEM_PID=$(ipcs -s -i ${SEM_ID} | grep '^[0-9]' | awk '{print $5}' | grep -v '^0' | sort | uniq)

	# Due to unforseen complications, we just need to move this up.
	for PID in $(echo ${SEM_PID})
	do
		if [ -d /proc/${PID} ]; then
			echo $PID is running. Skipping semaphore $SEM_ID
			SKIP=1
			break
		else
			echo $PID not found running.
			SKIP=0
		fi
	done

	if [ $SKIP -eq 0 ]; then
		echo Removing semaphore $SEM_ID
		ipcrm -s $SEM_ID
	fi
done
