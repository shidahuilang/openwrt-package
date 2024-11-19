#!/bin/sh

VPING="$(cat /tmp/lite_watchdog)"
VMIN=$(echo $VPING | awk -v FS="(round-trip|ms)" '{print $2}')
MIN=$(echo $VMIN | awk -F[=/] '{print $4}' | xargs)
AVG=$(echo $VMIN | awk -F[=/] '{print $5}' | xargs)
MAX=$(echo $VMIN | awk -F[=/] '{print $6}' | xargs)

TEST_TIME="$(cat /tmp/lite_watchdog_tt)"

CNT=$(wc -l < /tmp/lite_watchdog_cnt)
CNT=$((CNT-1))

ONV=$(uci -q get watchdog.@watchdog[0].enabled)
if [ $ONV == "0" ]; then

	ON="0"
else
	ON="1"
fi

DT=$(uci -q get watchdog.@watchdog[0].dest)
DY=$(uci -q get watchdog.@watchdog[0].delay)
PD=$(uci -q get watchdog.@watchdog[0].period)
CT=$(uci -q get watchdog.@watchdog[0].period_count)
AN=$(uci -q get watchdog.@watchdog[0].action)

cat <<EOF
{
"enable":"$ON",
"dest":"$DT",
"delay":"$DY",
"period":"$PD",
"count":"$CT",
"now_count":"$CNT",
"action":"$AN",
"testtime":"$TEST_TIME",
"min":"$MIN",
"avg":"$AVG",
"max":"$MAX"
}
EOF
exit 0
