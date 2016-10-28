#!/bin/bash
#USAGE: ./diskusage_percent.sh /dir

PATH=/bin:/sbin:/usr/bin:/usr/sbin

DIRPATH=$1 #file path to check

declare -i diskUsage #Set diskUsage to Integer
declare -i diskAvailable #Set diskAvailable to Integer

diskUsage=90
diskAvailable=$(df -h | grep $1 | awk '{print $5}'| sed 's/.\{1\}$//')

if [[ $diskAvailable -ge $diskUsage ]]; then
        echo "Message.1: ${HOSTNAME} ${DIRPATH} is greater than ${diskUsage}% used"
        echo "Statistic.1: 1"
else
        echo "Message.1: ${HOSTNAME} ${DIRPATH} is less than ${diskUsage}% used"
        echo "Statistic.1: 0"
fi

