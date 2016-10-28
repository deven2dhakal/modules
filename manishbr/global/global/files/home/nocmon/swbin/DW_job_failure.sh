#!/bin/sh

query="
SELECT
   alert_type,
   scheduler_event_name,
   to_char(runtime, 'HH24:MI:SS') runtime
FROM
   public.ytsp_get_dw_job_failure()
";

rc=0
retstr=""
while IFS='|' read alert_type scheduler runtime
do
    if [[ -z $alert_type ]]; then
       continue
    fi
    if [[ $alert_type = FAIL* ]]; then
       rc=2
    elif [[ $rc -ne 2 ]]; then
       rc=1
    fi
    if [[ ! -z $retstr ]]; then
       retstr="$retstr; "
    fi
    retstr="$retstr$alert_type$scheduler-$runtime"
done << EOF
$(/opt/postgresql/bin/psql -q -tA -U postgres -c "$query" yotta_management_db)
EOF


case $rc in
   0) retstr="OK:";;
   1) retstr="WARN: $retstr";;
   2) retstr="CRIT: $retstr";;
esac

echo "Message.Job_Fail_Status: $retstr" 
echo "Statistic.Job_Fail_Status: $rc"
#exit $rc

