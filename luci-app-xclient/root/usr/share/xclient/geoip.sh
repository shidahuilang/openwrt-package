#!/bin/sh 
echo '' >/var/lock/xclient.lock 2>/dev/null
echo '' >/tmp/geo_ip_update.txt 2>/dev/null
echo 'Checking for latest version' >/tmp/geo_ip_update.txt 2>/dev/null

new_version=`wget -qO- "https://github.com/Loyalsoldier/v2ray-rules-dat/tags"| grep "/Loyalsoldier/v2ray-rules-dat/releases/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//'`

rm -rf /tmp/geoip.dat >/dev/null 2>&1
echo 'Latest version: ' $new_version >/tmp/geo_ip_update.txt 2>/dev/null

if [ -f /var/run/geo_ip_down_complete ];then 
  rm -rf /var/run/geo_ip_down_complete 2>/dev/null
fi

echo 'Starting download...' >/tmp/geo_ip_update.txt 2>/dev/null

wget -c4 --no-check-certificate --timeout=60 --user-agent="Mozilla" https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/"$new_version"/geoip.dat -O /tmp/geoip.dat
sleep 2
if [ "$?" -eq "0" ] && [ "$(ls -l /tmp/geoip.dat |awk '{print int($5)}')" -ne 0 ]; then
	touch /var/run/geo_ip_down_complete >/dev/null 2>&1
	rm -rf /var/run/geo_ip_update >/dev/null 2>&1
        rm -rf /usr/bin/geoip.dat && mv /tmp/geoip.dat  /usr/bin 
	echo $new_version > /usr/share/xclient/geoip_version 2>/dev/null
	echo "" > /tmp/geo_ip_update.txt >/dev/null 2>&1
	rm -rf /var/lock/xclient.lock 2>/dev/null
	if pidof xclient >/dev/null; then
	   /etc/init.d/xclient boot 2>/dev/null
	fi
fi
