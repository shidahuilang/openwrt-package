#!/bin/bash

nettime=$(uci get nettask.main.nettime)

while true; do
    if ping -c 4 -W 3 8.8.8.8 >/dev/null; then
        :
    else
        logger "网络异常,执行脚本"
        pgrep -f /etc/nettask/network.sh | xargs kill -9 >/dev/null 2>&1
        sh /etc/nettask/network.sh &
    fi
    sleep $nettime
done
