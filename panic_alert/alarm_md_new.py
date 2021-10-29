# -*- coding: utf-8 -*-
# @Time    : 2019/12/5
# @Author  : Yifei Duan
# @Summary :
# python alarm.py "$service_info" "$alert_content"

import json
import requests
import sys


def send_alarm(source, content):
    underline_count = source.count('_')
    if '10' in source:
        node_type = "online-非K8S"
        if underline_count == 1:
            alert_group = "{}".format(source.split('_')[0])
        else:
            alert_group = "{}".format(source.split('_')[1])
    else:
        node_type = "online-K8S"
        alert_group = "{}".format(source.split('_')[2])

    logpath = '10.111.209.191' + ':' + content.split()[2]

    # alert_md_format:
    # node_type: k8s or 非k8s;
    # source: sla_sla-0 or job84_transcoding_10.111.203.251 or picturebook_10.111.203.3
    # logpath: 10.111.209.191:/data/abc/aaa/ccc.log
    # content: 报警内容


    if alert_group == "qi":
    	alert_group = "qi-platform"

    send_content = {
        "labels": {
            "title": "生产环境 Panic",
            "source": source,
            "details": content,
            "project_name": alert_group,
            #"project_name": 'qtapi',
            "customized_Labels": {
                "deploy_way": node_type,
                "log_path": logpath,
            }
        },
        "annotations": {
            "alert_source": "/alert",
            "should_ignore_threshold": "true",
        }
    }


    send_data = json.dumps(send_content)
    print(send_data)
    #url = "https://sea.pri.xxx.com/qtapi/base/alertmanager/alert/info/add"
    url = "http://pam.pri.xxx.com/alert/info/add"
    r = requests.post(url, data=send_data)
    print(r.text)


if __name__ == '__main__':
    '''
    $1: service info: sla_sla-0 or job84_transcoding_10.111.203.251 or picturebook_10.111.203.3.log
    $2: alert-content
    '''

    source = sys.argv[1]
    content = sys.argv[2]
    send_alarm(source, content)