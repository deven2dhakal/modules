#!/bin/bash
#. ~dbxdba/.bash_profile
/home/dbxdba/.bash_profile

#Usage statement.
#if test "$1" == "" ; then
#        echo "Please supply servername parameter."
#        echo "Example: bash dbx_DiskCheck.sh MP_PRD"
#        exit
#fi

LOGFILE="/tmp/dbx_DiskCheck.log"
OUTPUT="/tmp/active_servers.out"
date > $LOGFILE

#Get filesystem usage from head and all nodes. Assign alert level to highest space usage.
xdudb df |grep -e node -e head -e /| awk 'NR%2==1 {node=$1} NR%2==0 {print $5 " "node " " $1}'|sed 's/%//'| sort -r |head -1| awk '

$1 <85 {print "Message.Disk_Status: SUCCESS! DBX file system " $3 " is less than 85% full!"; print "Statistic.Disk_Status: 0"; exit 0;}
$1 >84 && $1 <90 {print "Message.Disk_Status: WARNING! DBX file system " $3 " on " $2 " is "$1 "% full!"; print "Statistic.Disk_Status: 1"; exit 1;}
$1 >89 && $1 <93 {print "Message.Disk_Status: CRITICAL ALERT! DBX file system " $3 " on " $2 " is "$1 "% full!"; print "Statistic.Disk_Status: 2"; exit 2}
$1 >92 {print "Message.Disk_Status: DIRE ALERT!  DBX file system " $3 " on " $2 " is "$1 "% full!"; print "Statistic.Disk_Status: 3";  exit 3;}
'

#Returns an exit value of 3 if the filesystem is full.
rc=$?


#If the rc value is equal to 3 then we will attempt to shut down the server.
if [ $rc -eq 3 ]; then
	
	echo "Message.Disk_Status: DIRE ALERT! Attempting shutdown all servers." >>$LOGFILE

	#Get list of running servers on the host.
	xdudb list | grep "*" | sed 's/*//' > $OUTPUT

	while read -r servername 
	do
		xdudb stop $servername 2>/dev/null
		#sleep for 10 seconds
		sleep 10
	
		#check the status of the server
		srv_status=$(xdudb status $servername|grep "Status"|awk 'NR%2==0 {print $2}')
	
		#for testing: if down, then send out notice that the server has been shutdown
		if [ $srv_status == "Idle" ]; then
    			echo "$servername has been shut down!!!" >> $LOGFILE
     
		else
			echo "$servername is still up!  DBA please check server $servername!" >> $LOGFILE
		fi
	done < "$OUTPUT"
elif [ $rc -eq 2 ]; then
	echo "Message.Disk_Status: CRITICAL ALERT!" >>$LOGFILE
elif [ $rc -eq 1 ]; then
	echo "Message.Disk_Status: WARNING! File system usage above 85%" >>$LOGFILE
elif [ $rc -eq 0 ]; then
	echo "Message.Disk_Status: SUCCESS! File system usage below 85%" >>$LOGFILE 
fi

date >> $LOGFILE
