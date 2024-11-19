#!/bin/sh

[ -e /etc/crontabs/root ] || touch /etc/crontabs/root

sleep 2
ONF=$(uci -q get easyconfig_transfer.traffic.enable_backup)
if [ "x$ONF" != "x1" ]; then
	if grep -q "easyconfig_statistics.json" /etc/crontabs/root; then
		grep -v "easyconfig_statistics.json" /etc/crontabs/root > /tmp/new_cron
		mv /tmp/new_cron /etc/crontabs/root
		/etc/init.d/cron restart
	fi
	exit 0
fi

if ! grep -q "easyconfig_statistics.json" /etc/crontabs/root; then

	grep -v "easyconfig_statistics.json" /etc/crontabs/root > /tmp/new_cron
	mv /tmp/new_cron /etc/crontabs/root
		
		TM=$(uci -q get easyconfig_transfer.traffic.make_time)

			N1=$(echo $TM | tr -dc '0-9');

			TMHH=$(echo ${N1:0:2});
			TMMM=$(echo ${N1:2:4});

			if [[ ${TMHH:0:1} -eq 0 ]]; then
				TMHH="${TMHH:1}"
			fi

			if [[ ${TMMM:0:1} -eq 0 ]]; then
				TMMM="${TMMM:1}"
			fi

		TR=$(uci -q get easyconfig_transfer.traffic.restore_time)
		
			N2=$(echo $TR | tr -dc '0-9');

			TRHH=$(echo ${N2:0:2});
			TRMM=$(echo ${N2:2:4});

			if [[ ${TRHH:0:1} -eq 0 ]]; then
				TRHH="${TRHH:1}"
			fi

			if [[ ${TRMM:0:1} -eq 0 ]]; then
				TRMM="${TRMM:1}"
			fi

		echo "$TMMM $TMHH * * * cp /tmp/easyconfig_statistics.json /etc/modem" >> /etc/crontabs/root
		echo "$TRMM $TRHH * * * cp /etc/modem/easyconfig_statistics.json /tmp" >> /etc/crontabs/root
	/etc/init.d/cron restart
	exit 0
	
fi

exit 0
