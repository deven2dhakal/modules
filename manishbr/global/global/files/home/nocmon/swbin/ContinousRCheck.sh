#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin

#MONITOR-480: Check to see if acq_continous_R is running, if not alert Neus Herranz
#3-6-2014 added new check per Neus. Look for /dotomi/tmp/acquisition/acq_continuous_data_run.R and /dotomi/tmp/acquisition/acq_continuous_model_run.R


#RUNNING=$(ps -eaf | grep /dotomi/tmp/acquisition/acq_continuous_data_run.R | grep -v grep > /dev/null && echo 1)
RUNNING2=$(ps -eaf | grep /dotomi/tmp/acquisition/acq_continuous_model_run.R | grep -v grep > /dev/null && echo 1)


#if [[ $RUNNING -ne 1 ]]; then
#	echo "Message.status: ${HOSTNAME}::acq_continuous_data_run.R is not running"
#	echo "Statistic.status: 1"
#else 
#	echo "Message.status: ${HOSTNAME}::acq_continuous_data_run.R is running"
#	echo "Statistic.Status: 0"
#fi

if [[ $RUNNING2 -ne 1 ]]; then
        echo "Message.status: ${HOSTNAME}::acq_continuous_model_run.R is not running"
        echo "Statistic.status: 1"
else
        echo "Message.status: ${HOSTNAME}::acq_continuous_model_run.R is running"
        echo "Statistic.Status: 0"
fi


