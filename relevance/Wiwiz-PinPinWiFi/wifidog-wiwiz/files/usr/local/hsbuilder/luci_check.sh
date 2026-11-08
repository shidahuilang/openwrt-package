#!/bin/sh
# Wiwiz HotSpot Builder Utility
# Copyright wiwiz.com. All rights reserved.

LOGFILE='/tmp/hsbuilder.log'

log1() {
	echo "$(date "+%Y-%m-%d %H:%M:%S") $1" >>$LOGFILE
	logger -t 'hsbuilder' "$1"
}

check_luci() {
	which curl >/dev/null 2>&1 || return 1
	
	# check luci url
	CHECK_URL="http://127.0.0.1/cgi-bin/luci"

	# 1. luck check
	HTTP_CODE=$(curl -s -o /dev/null -m 5 -w "%{http_code}" "$CHECK_URL")
	case "$HTTP_CODE" in
		000|404|5*)
			log1 "luci_check.sh: LuCI check code : $HTTP_CODE !!!"
			return 2
			;;
	esac

	# 2. ubus RPC check
	if ! ubus call luci getFeatures >/dev/null 2>&1; then
		log1 "luci_check.sh: LuCI ubus RPC failed !!!"
		return 3
	fi
}

if check_luci; then
    uci set wiwiz.portal.luci_keepalive='1'
	log1 "luci_check.sh: luci_keepalive enabled."
else
    uci set wiwiz.portal.luci_keepalive='0'
fi
uci commit wiwiz
