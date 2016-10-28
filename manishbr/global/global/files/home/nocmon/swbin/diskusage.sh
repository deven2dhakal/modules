#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin

DIRPATH=$1 #file path to check
declare -i MAXSIZE #Set MAXSIZE to integer
MAXSIZE=$2 #MAXSIZE is the second command line argument. Enter the size in GB (e.g. 250 for 250GB or 256000MB)
MAXSIZE=$((MAXSIZE * 1048576)) #convert GB to KB

#USAGE filesize.sh /path/to/directory maxsize_in_G

declare -i diskUsage #Set diskUsage to Integer

diskUsage=$(du -k ${DIRPATH} --max-depth=0 | awk '{print $1}') #Pull size only from du output

if [[ $diskUsage -ge $MAXSIZE ]]; then
	echo "Message.Status: ${HOSTNAME} ${DIRPATH} is greater than $2GB used"
	echo "Statistic.status: 1"
else 
	echo "Message.Status: ${HOSTNAME} ${DIRPATH} is less than $2GB used"
	echo "Statistic.Status: 0"
fi
