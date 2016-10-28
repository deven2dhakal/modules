#!/bin/bash
/home/dbxdba/.bash_profile

#Usage statement.
if test "$1" == "" ; then
        echo "Please supply servername parameter."
        echo "Example: bash dbx_ServerStatus.sh MP_PRD"
        exit
fi

#Get the status of the specified server.
#srv_status=$(xdudb status $1 |grep "Status"|awk 'NR%2==0 {print $2}') 
srv_status_outout=$(/usr/local/bin/xdudb status $1 2>/dev/null)
srv_status=$(echo "$srv_status_outout" |grep "Status"|awk 'NR%2==0 {print $2}')
#echo $srv_status

#If it doesn't exist or server is idle then issue critical alert return status of 1.

if [ $srv_status == ""] 2>/dev/null ; 
then  
		echo "Message.Server_Status: CRITICAL ALERT! Can't detect server status!"
		echo "Statistic.Server_Status: 2"

elif [ $srv_status == "Idle" ]; then

 		echo "Message.Server_Status: CRITICAL ALERT! DBX server $1 is $srv_status!"
                echo "Statistic.Server_Status: 2"

#If the server is Running then report and return status of 0.
elif [ $srv_status == "Running" ]; then
 		echo "Message.Server_Status: SUCCESS! DBX server $1 is $srv_status!"
                echo "Statistic.Server_Status: 0"

fi


