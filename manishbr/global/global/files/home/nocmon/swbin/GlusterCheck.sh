#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin

#Usage: GlusterCheck brick x2ord


RUNNING=$(gluster volume status | grep -i  $1 | grep -i $2| awk '{print $4'})

#echo $RUNNING
#sleep 3

if [[ "$RUNNING" = *N* ]]; then
	echo "Message.status: ${HOSTNAME}::GLUSTER $1 $2 is down or in a fault state"
	echo "Statistic.status: 1"
else 
	echo "Message.status: ${HOSTNAME}::GLUSTER $1 $2 is running"
	echo "Statistic.Status: 0"
fi

