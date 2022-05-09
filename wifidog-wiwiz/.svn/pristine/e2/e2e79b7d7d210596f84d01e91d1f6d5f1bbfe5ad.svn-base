#!/bin/sh
# Wiwiz HotSpot Builder Utility
# Copyright wiwiz.com. All rights reserved.

LOAD_LIMIT=3.8

DEST=""
OS=""
WIFIDOG_START="wifidog"
WIFIDOG_CONFPATH=/etc

LOGFILE='/tmp/hsbuilder.log'
TMPFILE='/tmp/hsbuilder_helper.tmp'
#SRV_SAVE='/usr/local/hsbuilder/srv'

getIP() {
	_mac="$1"
	s=$(cat /proc/net/arp | grep -F "$_mac" | grep -F '0x2' | grep -F 'br-lan'| awk '{print $1}')
	echo "$s"
}

passAuthed() {
	HID=$(uci get wiwiz.portal.hotspotid 2>/dev/null)
	if [ "$HID" = "" ]; then
		echo "Helper: passAuthed() unable to get hotspot_id." >>$LOGFILE
		return
	fi
	
	AS_HOSTNAME_X=$(uci get wiwiz.portal.server 2>/dev/null)
	if [ "$AS_HOSTNAME_X" = "" ]; then
		echo "Helper: passAuthed() unable to get AS_HOSTNAME_X." >>$LOGFILE
		return
	fi
	
	URL="http://$AS_HOSTNAME_X/as/s/getauthed/?&gw_id=$HID"
	rm -f "$TMPFILE" 2>/dev/null
	curl -m 10 -o "$TMPFILE" "$URL"
	
	cat "$TMPFILE" | while read LINE; do
		token=$(echo "$LINE" | cut -d ' ' -f 1)
		mac=$(echo "$LINE" | cut -d ' ' -f 2)
		ip=$(getIP "$mac")
		
		if [ "$ip" = "" ]; then
			ip=$(echo "$LINE" | cut -d ' ' -f 3)
		fi
		
		if [ "$ip" != "" ]; then
			wdctl auth "$mac" "$ip" "$token"
			echo "Helper: passAuthed() auth $mac $ip $token." >>$LOGFILE
		fi
	done
	
	rm -f "$TMPFILE" 2>/dev/null	
}

if [ "$1" = "-os" ]; then
	if [ "$2" = "openwrt" ]; then
#		WIFIDOG_START="wifidog-init start"
		WIFIDOG_START="wifidog"
	fi
	OS="$2"
	
	shift 2
fi

if [ "$1" = "-dest" ]; then
	if [ ! -d "$2" -a "$2" != "" ]; then
		echo "Error: $2 does not exist!"
		exit 1
	else
		DEST="$2"
	fi
	shift 2
fi
echo "hsbuilder_helper.sh: $(date)" >> $LOGFILE

LAN_IP=$(ifconfig br-lan | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}')
#_s=$(wget -O - -T 5 "http://$LAN_IP:2060/wifidog" 2>/dev/null)
_s=$(curl -m 5 "http://$LAN_IP:2060/wifidog" 2>/dev/null)
if [ "$_s" == "" ]; then
	killall -9 wifidog 2>/dev/null
	sleep 3
	$WIFIDOG_START
#	wdctl restart
	echo "Helper: $(date) Wifidog not respond. Restarted." >>$LOGFILE
	sleep 5
	passAuthed
	exit 0
fi

LOAD=$(cat /proc/loadavg | cut -d " " -f 1)
IS_LOAD_HIGH=$(awk -v num1="$LOAD" -v num2="$LOAD_LIMIT" 'BEGIN{print(num1>num2)?"true":"false"}')

#debug starts
#echo "LOAD=$LOAD"
#echo "IS_LOAD_HIGH=$IS_LOAD_HIGH"
#debug ends

if [ "$IS_LOAD_HIGH" = "true" ]; then
	killall -9 wifidog 2>/dev/null
	sleep 3
	$WIFIDOG_START
#	wdctl restart
	echo "Helper: $(date) Wifidog too busy! Restarted (wdctl)." >>$LOGFILE
	sleep 5
	passAuthed
	exit 0
fi

_p=$(ps | grep wifidog | grep -v grep 2>/dev/null)
if [ "$_p" = "" ]; then
	#if [ $OS != "linux" ]; then	
	#	cp -f $DEST/usr/local/hsbuilder/wifidog.conf $WIFIDOG_CONFPATH/wifidog.conf
	#fi
	$WIFIDOG_START
	echo "Helper: $(date) Wifidog not running! Started." >>$LOGFILE
	sleep 5
	passAuthed
	exit 0
else
	_wc=$(echo "$_p" | wc -l)
	if [ "$_wc" -gt 1 ]; then
		_pids=$(echo "$_p" | awk '{print $1}')
		
		echo "$_pids" | while read LINE; do
			kill -9 "$LINE"
		done
		
		$WIFIDOG_START
		echo "Helper: $(date) All Wifidogs killed and restarted" >>$LOGFILE
		sleep 5
		passAuthed
		exit 0
	fi
fi


#wdctl status
#CODE="$?"
#
#if [ $CODE != "0" ]; then
#	if [ $OS != "linux" ]; then	
#		cp -f $DEST/usr/local/hsbuilder/wifidog.conf $WIFIDOG_CONFPATH/wifidog.conf
#	fi
#	$WIFIDOG_START
#	echo "Helper: $(date) Wifidog not running! Started." >>$LOGFILE
#	exit 0
#fi

echo "hsbuilder_helper.sh: done." >> $LOGFILE

exit 0