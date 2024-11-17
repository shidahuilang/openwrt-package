#!/bin/sh

# $1 delay time
# $2 ping count
# $3 host
# $4 period count
# $5 action reboot|wan

T=$(uci -q get watchdog.@watchdog[0].iface)
[ -z "$T" ] && exit 0
[ "x$T" = "xnone" ] && exit 0

UPTIME=$(awk '{printf "%d", $1}' /proc/uptime)
[ $UPTIME -le $1 ] && exit 0

DIR="/etc/modem"
LOG_FILE="$DIR/log.txt"
CNT_FILE="/tmp/lite_watchdog_cnt"

LINES_MAX=11000
LINES_MIN=6000
LINES_COUNT=$(wc -l $LOG_FILE | awk '{print $1}')

LOG_D=$(uci -q get watchdog.@watchdog[0].log)

LEDST=$(uci -q get watchdog.@watchdog[0].ledstatus)
LEDX=$(uci -q get watchdog.@watchdog[0].led)
LEDON="/sys/class/leds/$LEDX/brightness"

if [[ "$LINES_COUNT" -ge "$LINES_MAX" ]]; then
	echo "$(tail -$LINES_MIN $LOG_FILE)" > $LOG_FILE
fi

if [ ! -f "$CNT_FILE" ]; then
	echo -n "" > /tmp/lite_watchdog_cnt
	echo 0 >> /tmp/lite_watchdog_cnt
fi

date +"%Y-%m-%d %T" 2>&1 > /tmp/lite_watchdog_tt
ping -q -4 -w 10 -c $2 $3 > /tmp/lite_watchdog 2>/dev/null

PR=$(awk '/packets received/ {print $4}' /tmp/lite_watchdog)
[ -z "$PR" ] && PR=0
if [ "$PR" = "0" ]; then

	echo 0 >> /tmp/lite_watchdog_cnt

	TSTC=$(wc -l < /tmp/lite_watchdog_cnt)
	TST=$((TSTC-1))

	date +"%A %d-%B %Y %T, Status: OFFLINE > Failed $TST out of $4" >> $LOG_FILE

	if [ "x$LEDST" = "x1" ]; then
		echo "0" > $LEDON
	fi
else
	if [ "$LOG_D" != "offline" ]; then
	date +"%A %d-%B %Y %T, Status: ONLINE" >> $LOG_FILE
	fi
	
	if [ "x$LEDST" = "x1" ]; then
		echo "255" > $LEDON
	fi

	echo 1 > /tmp/lite_watchdog_cnt
	exit 0
fi
CNT=$(wc -l < /tmp/lite_watchdog_cnt)
CNT=$((CNT-1))

if [ $CNT -ge $4 ]; then

	case "$5" in
		"reboot")
			[ -e /etc/lite_watchdog.user ] && env -i ACTION="reboot" /bin/sh /etc/lite_watchdog.user

			date +"%A %d-%B %Y %T, Status: OFFLINE > Action: Reboot" >> $LOG_FILE && sleep 5

			logger -t LITE-WATCHDOG "Reboot"
			reboot
			;;
		"wan")
			[ -e /etc/lite_watchdog.user ] && env -i ACTION="wan" /bin/sh /etc/lite_watchdog.user

			echo -n "" > /tmp/lite_watchdog_cnt
			echo 0 >> /tmp/lite_watchdog_cnt

			MODRES=$(uci -q get watchdog.@watchdog[0].modemrestart)
			if [ "$MODRES" == "1" ]; then
				CMD=$(uci -q get watchdog.@watchdog[0].restartcmd)
				PORT=$(uci -q get watchdog.@watchdog[0].set_port)

				logger -t LITE-WATCHDOG "Restart modem on port: \"$PORT\"."
				(sms_tool -d $PORT at "$CMD") &

				date +"%A %d-%B %Y %T, Status: OFFLINE > Action: At command was sent to modem" >> $LOG_FILE && sleep 59
			fi

			WANT=$(uci -q get watchdog.@watchdog[0].iface)

			if [[ "$WANT" == *"@"* ]]; then
				WAN=$(echo $WANT | sed 's/@//')
			else
				WAN=$(uci -q get watchdog.@watchdog[0].iface)
			fi

			date +"%A %d-%B %Y %T, Status: OFFLINE > Action: Restarting interface" >> $LOG_FILE && sleep 5
			
			logger -t LITE-WATCHDOG "Restarting network interface: \"$WAN\"."
			(ifdown $WAN; sleep 5; ifup $WAN) &
			;;
	esac
fi

exit 0
