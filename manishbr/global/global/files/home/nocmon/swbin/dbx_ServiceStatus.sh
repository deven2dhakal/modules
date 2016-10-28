#!/bin/bash
#. ~dbxdba/.bash_profile
/home/dbxdba/.bash_profile

#Checks statuses of all dbx services including the head node.  
#Sends SUCCESS message if all are up and CRITICAL ALERT message when one 
#or more services are down.
srv_status=$(xdudb status | grep "failed")
srv_status_count=$(sudo -iu dbxdba xdudb status | grep "failed"| wc -l)

if [[ $srv_status_count -gt 0 ]];then 
	echo "Message.Service_Status: CRITICAL ALERT! $srv_status!"
	echo "Statistic.Service_Status: 3"

else
   	echo "Message.Service_Status: SUCCESS: All dbx services are running."
  	echo "Statistic.Service_Status: 0"
fi


