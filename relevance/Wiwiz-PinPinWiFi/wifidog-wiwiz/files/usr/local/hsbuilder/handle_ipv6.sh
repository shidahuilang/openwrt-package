#!/bin/sh
# Wiwiz HotSpot Builder Utility
# Copyright wiwiz.com. All rights reserved.

LOGFILE='/tmp/hsbuilder.log'
ENABLED=$(uci get wiwiz.portal.enabled 2>/dev/null)
DISABLE_IPV6=$(uci get wiwiz.portal.disable_ipv6 2>/dev/null)

log1() {
	echo "$1" >>$LOGFILE
	logger -t 'hsbuilder' "$1"
}

if [ "$ENABLED" == "1" -a "$DISABLE_IPV6" == "1" ]; then
    uci del network.lan.ip6assign
    uci set network.lan.delegate='0'
    uci del network.wan.ip6assign
    uci set network.wan.delegate='0'


    [ "$(uci get network.lan.ipv6 2>/dev/null)" != "0" ] && {
        uci set network.lan.ipv6='0'
    }
    [ "$(uci get network.wan6.reqaddress 2>/dev/null)" != "none" ] && {
        uci set network.wan6.reqaddress='none'
    }
    [ "$(uci get network.wan6.reqprefix 2>/dev/null)" != "no" ] && {
        uci set network.wan6.reqprefix='no'
    }

    uci commit network
    /etc/init.d/network restart

    log1 "IPv6 disabled"
fi