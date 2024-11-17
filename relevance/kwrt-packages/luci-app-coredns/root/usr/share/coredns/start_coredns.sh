#!/bin/sh

CONF_FILE=$(uci -q get coredns.config.configfile)
LOG_FILE=$(uci -q get coredns.global.logfile)
ENABLED_LOG=$(uci -q get coredns.config.enabled_log)
ENABLED=$(uci -q get coredns.config.enabled)

chmod +x /usr/share/coredns/coredns

# if [$ENABLED -eq 0]
# then
#     killall coredns
#     return 1
# fi
echo "开始启动 coredns 程序..." >> /tmp/coredns.log

if [ $ENABLED_LOG -ne 0 ]
then
    /usr/share/coredns/coredns -conf="$CONF_FILE" >> $LOG_FILE
else
    /usr/share/coredns/coredns -conf="$CONF_FILE" >/dev/null 2>&1
fi
