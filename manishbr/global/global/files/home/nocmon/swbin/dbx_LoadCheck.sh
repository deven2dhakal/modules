#!/bin/bash
. ~dbxdba/.bash_profile


#Check /proc/loadavg file and parse it to get load average.

#xdudb cmd -no cat /proc/loadavg | awk 'NR%2==1 {node=$1} NR%2==0 {print node " " $0}'  | awk'

xdudb cmd -no cat /proc/loadavg | awk 'NR%2==1 {node=$1} NR%2==0 {print node " " $0}'|awk '
BEGIN { highLoad=0 }
{   #printf "%s %s %s %s\n", $1, $2, $3, $4;

    if($3>highLoad) {highLoad=$3; highSeg=$1};
    sum+=$3;
    sumsq+=$3*$3;
}
END {   stdev=sqrt(sumsq/NR - (sum/NR)**2);
        avg=(sum/NR);
        skew=((stdev/avg) * 100);

        printf "Most Loaded Segment: %.2f/%s - Skew: %.2f\n", highLoad, highSeg, skew;

        if(skew>80 && highLoad>23) {exit 3};
        if(highLoad>30) {exit 2};
        if(highLoad>20) {exit 1};
}'> /tmp/highload.txt

highload=$(cat /tmp/highload.txt)
rm -rf /tmp/highload.txt

rc=$?
if [[ $rc -eq 3 ]]; then
   warnmin=10
#   echo "Message.Load_Check_Status: CRITICAL! Warnmin is $warnmin"
else
   warnmin=5
   #echo "Message.Load_Check_Status: Warnmin is $warnmin"
#   echo "Message.Load_Check_Status: Warning! Warnmin is $warnmin"
fi

if [[ $rc -lt 2 ]]; then
   rm -f /tmp/check_dbxLoad.dat
   #STATUS=$rc
   STATUS=2
elif [[ $(find /tmp -name check_dbxLoad.dat -mmin +${warnmin} -maxdepth 1 2>/dev/null | wc -l) -eq 1 ]]; then
   STATUS=2
elif [[ -f /tmp/check_dbxLoad.dat ]]; then
   STATUS=1
else
   date +%F%T > /tmp/check_dbxLoad.dat
   chmod 666 /tmp/check_dbxLoad.dat
   STATUS=1
fi

echo "Message.Load_Check_Status: $highload"
echo "Statistic.Load_Check_Status: $STATUS"
