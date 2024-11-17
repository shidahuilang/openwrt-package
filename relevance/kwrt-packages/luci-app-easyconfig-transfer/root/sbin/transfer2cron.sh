#!/bin/sh

[ -e /etc/crontabs/root ] || touch /etc/crontabs/root

sleep 4
ONF=$(uci -q get easyconfig_transfer.global.transfer_enabled)
if [ "x$ONF" != "x1" ]; then
	if grep -q "easyconfig" /etc/crontabs/root; then
		grep -v "easyconfig" /etc/crontabs/root > /tmp/new_cron
		mv /tmp/new_cron /etc/crontabs/root
		/etc/init.d/cron restart
	fi
	exit 0
fi

if ! grep -q "easyconfig" /etc/crontabs/root; then

	grep -v "easyconfig" /etc/crontabs/root > /tmp/new_cron
	mv /tmp/new_cron /etc/crontabs/root

	PD=$(uci -q get easyconfig_transfer.global.dataread_period)

	echo "*/$PD * * * * /usr/bin/easyconfig_statistics.sh" >> /etc/crontabs/root
	/etc/init.d/cron restart
	exit 0
fi

exit 0
