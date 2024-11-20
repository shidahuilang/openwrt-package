#!/bin/sh
# Wiwiz HotSpot Builder Utility
# Copyright wiwiz.com. All rights reserved.

MY_VERSION="3.0.0"	#for Wiwiz-opensource

SRV_SAVE='/usr/local/hsbuilder/srv'
ROAMING_FILE='/tmp/wiwizroaming'
HID=""
TMPFILE='/tmp/hsbuilder_token.tmp'
DEBUG_FILE='/tmp/wiwizroaming.debug'
LOGFILE='/tmp/hsbuilder.log'

debug() {
	DEBUG=$(cat "$DEBUG_FILE" 2>/dev/null)
	if [ "$DEBUG" = "1" ]; then
		echo "$1" >>$LOGFILE
	fi
}

doAuth() {
	MAC="$1"
	IP="$2"
	AS_HOSTNAME_X="$3"

    URL="http://$AS_HOSTNAME_X/as/s/auth/?stage=token&gw_id=$HID&mac=$MAC"
    
	debug "HID=$HID"

	rm -f "$TMPFILE"
	curl -m 10 -o "$TMPFILE" "$URL"	
	token=$(cat "$TMPFILE" 2>/dev/null |  cut -d ':' -f 2)
	ip=$(cat "$TMPFILE" 2>/dev/null |  cut -d ':' -f 3)
	rm -f "$TMPFILE"
	
	if [ "$token" == "" ]; then
		return
	fi
	
	wdctl auth "$MAC" "$IP" "$token"
	debug "wdctl auth $MAC $IP $token"

	wdctl status | grep 'IP:' | grep 'MAC:' | tr -d ' ' | sed 's/IP://g' | sed 's/MAC:/ /g' | grep -i "$MAC" | grep -v "$IP " | while read LINE; do
		IPtoReset=$(echo "$LINE" | cut -d ' ' -f 1)
		wdctl reset "$IPtoReset"
		debug "wdctl reset $IPtoReset"
	done
}


logread -f | while read LINE; do
	s=$(echo "$LINE"  | grep 'dnsmasq' | grep 'DHCPACK')
			
	if [ "$s" != "" ]; then
		LANDEV=$(uci get wiwiz.portal.lan 2>/dev/null)
		ss=$(echo "$s" | grep -F "$LANDEV")
		debug "ss = $ss"
		if [ "$ss" == "" ]; then
			continue
		fi

		HID=$(uci get wiwiz.portal.hotspotid 2>/dev/null)
		if [ "$HID" == "" ]; then
			continue
		fi				
		
		ROAMING=$(cat "$ROAMING_FILE" 2>/dev/null)
		if [ "$ROAMING" == "" ]; then
			continue
		fi

		AS_HOSTNAME_X=$(uci get wiwiz.portal.server 2>/dev/null)
		if [ "$AS_HOSTNAME_X" == "" ]; then
			continue
		fi

		MAC=$(echo "$ss" | awk '{print $10}')
		IP=$(echo "$ss" | awk '{print $9}')
		if [ "$MAC" == "" ]; then
			continue
		fi
		if [ "$IP" == "" ]; then
			continue
		fi
		
		debug "MAC = $MAC, IP = $IP"				
		doAuth "$MAC" "$IP" "$AS_HOSTNAME_X" &
	fi
done
