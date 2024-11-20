#!/bin/sh

[ -e /etc/crontabs/root ] || touch /etc/crontabs/root

sleep 4
ONF=$(uci -q get watchdog.@watchdog[0].enabled)
if [ "x$ONF" != "x1" ]; then
	if grep -q "watchdog" /etc/crontabs/root; then
		grep -v "watchdog" /etc/crontabs/root > /tmp/new_cron
		mv /tmp/new_cron /etc/crontabs/root
		/etc/init.d/cron restart
	fi
	exit 0
fi

if ! grep -q "watchdog" /etc/crontabs/root; then

	grep -v "watchdog" /etc/crontabs/root > /tmp/new_cron
	mv /tmp/new_cron /etc/crontabs/root

	DY=$(uci -q get watchdog.@watchdog[0].delay)
	PD=$(uci -q get watchdog.@watchdog[0].period)
	DT=$(uci -q get watchdog.@watchdog[0].dest)
	CT=$(uci -q get watchdog.@watchdog[0].period_count)
	AN=$(uci -q get watchdog.@watchdog[0].action)

	echo "*/$PD * * * * /usr/bin/lite_watchdog.sh $DY 3 $DT $CT $AN" >> /etc/crontabs/root
	/etc/init.d/cron restart
fi

exit 0
