#!/bin/sh

case $1 in
	2g|3g|4g)
		SLOT=$(uci -q get modemconfig.@modem[-1].device)
		if [ $SLOT ]; then
			mmcli -J -m ${SLOT} | jsonfilter -e '@["modem"]["generic"]["supported-modes"][*]' | grep $1
		fi
	;;
esac

