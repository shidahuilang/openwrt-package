#!/bin/sh
# Wiwiz HotSpot Builder Utility
# Copyright wiwiz.com. All rights reserved.

ENABLED=$(uci get wiwiz.portal.enabled 2>/dev/null)
DP=$(uci get wiwiz.portal.dhcp_portal 2>/dev/null)
HOST=$(uci get wiwiz.portal.server 2>/dev/null | cut -d ':' -f 1)
DEV=$(uci get wiwiz.portal.lan 2>/dev/null)
#NETIF=$(uci show network | grep "$DEV" | grep -v '@' | cut -d '=' -f 1 | cut -d '.' -f 2 2>/dev/null)
NETIF=$(ubus call network.interface dump | jsonfilter -e "@.interface[@.device='$DEV']['interface']")

if [ "$NETIF" == "" ]; then
    NETIF="lan"
fi

dof=$(uci get dhcp.$NETIF.dhcp_option_force 2>/dev/null)
if [ "$dof" != "" ]; then
    for op in $dof; do
        is_114=$(echo "$op" | grep -F "114," | grep "$HOST")
        if [ ! -z "$is_114" ]; then
            uci del_list dhcp.$NETIF.dhcp_option_force="$op"
        fi
    done
fi

if [ "$ENABLED" == "1" -a "$DP" == "1" ]; then
    lan_ip=$(ifconfig $(uci get wiwiz.portal.lan 2>/dev/null) | grep 'inet addr' | awk '{ print $2}' | awk -F: '{print $2}' 2>/dev/null)
    url="https://$HOST/as/cpi.jsp?ip=$lan_ip"
    op114="114,$url"
    uci add_list dhcp.$NETIF.dhcp_option_force="$op114"
fi

uci commit dhcp
sleep 2
/etc/init.d/dnsmasq restart