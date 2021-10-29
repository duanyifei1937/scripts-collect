#!/usr/bin/env bash

LOCALTIME=`date +"%Y%m%d-%H%M%S"`

# tragit alert.log
sh get_alert.sh >> alertexec.log

ls ./alert.log* >> alertexec.log
if [ $? -eq 0 ]
then
    # 轮询每个alert.log触发报警
    ls ./alert.log* | while read line
    do
        alert_content=`cat $line`
        service_info=`cat $line | head -1 | awk '{print $3}' |  awk -F '/' '{print $NF}' | awk -F '.log' '{print $1}'`
        echo "service_info: ------- $service_info"
        echo "$LOCALTIME" >> alertexec.log
        python alarm_md_new.py "$service_info" "$alert_content"  >> alertexec.log
    done

    tail -n +1 ./alert.log* > alert-history/alert_${LOCALTIME}
    rm -f ./alert.log*
else
    echo "$LOCALTIME no have alert" >> alertexec.log
fi