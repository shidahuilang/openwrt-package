#!/bin/bash
log_max_size="128" #KB
log_file="/tmp/unblockneteasemusic.log"

((log_size = "$(ls -l "${log_file}" | awk -F ' ' '{print $5}')" / "1024"))
(("${log_size}" >= "${log_max_size}")) && echo "" >"${log_file}"
if [ "$(uci get unblockneteasemusic.@unblockneteasemusic[0].daemon_enable)" == "1" ]; then
    if [ -z "$(ps | grep "UnblockNeteaseMusic" | grep -v "grep")" ]; then
        echo "$(date -R) try restart..." >>"${log_file}"
        /etc/init.d/unblockneteasemusic restart
    fi
fi
