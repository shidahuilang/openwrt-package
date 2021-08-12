#!/bin/sh

. /lib/network/config.sh
. /lib/functions.sh

update_weather=0

update_time=$(uci get k3screenctrl.@general[0].update_time 2>/dev/null)

if [ -z "$update_time" ]; then
	update_time=3600
fi

DATE=$(date "+%Y-%m-%d %H:%M")
DATE_DATE=$(echo $DATE | awk '{print $1}')
DATE_TIME=$(echo $DATE | awk '{print $2}')
DATE_WEEK=$(date "+%u")
if [ "$DATE_WEEK" == "7" ]; then
	DATE_WEEK=0
fi

if [ "$update_time" -eq 0 ]; then
	echo "OFF"$city
	echo $WENDU
	echo $DATE_DATE
	echo $DATE_TIME
	echo $TYPE
	echo $DATE_WEEK
	echo 0
	exit
fi

cur_time=`date +%s`
last_time=`cat /tmp/weather_time 2>/dev/null`
if [ -z "$last_time" ]; then
	update_weather=1
	echo $cur_time > /tmp/weather_time
else
	time_tmp=`expr $cur_time - $last_time`
	if [ $time_tmp -ge $update_time ]; then
		update_weather=1
		echo $cur_time > /tmp/weather_time
	fi
fi

city_checkip=0
city_checkip=$(uci get k3screenctrl.@general[0].city_checkip 2>/dev/null)

if [ "$city_checkip" = "1" ]; then
	city_tmp=`cat /tmp/weather_city 2>/dev/null`
	if [ -z "$city_tmp" ]; then
		wanip=`curl --connect-timeout 3 -s http://pv.sohu.com/cityjson | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}"`
		city_json=`curl --connect-timeout 3 -s http://ip.taobao.com/service/getIpInfo.php?ip=$wanip`
		ip_city=`echo $city_json | jsonfilter -e '@.data.city'`
		ip_county=`echo $city_json | jsonfilter -e '@.data.county'`
		if [ "$ip_county" != "XX" ]; then
			city=`echo $ip_county`
		else
			city=`echo $ip_city`
		fi
		echo $city > /tmp/weather_city
		uci set k3screenctrl.@general[0].city=$city
		uci commit k3screenctrl
	else
		city=`echo $city_tmp`
	fi
else
	city=$(uci get k3screenctrl.@general[0].city 2>/dev/null)
fi
#echo $city

weather_info=$(cat /tmp/k3-weather.json 2>/dev/null)
if [ -z "$weather_info" ]; then
	update_weather=1
fi

key=$(uci get k3screenctrl.@general[0].key 2>/dev/null)
if [ -z "$key" ]; then
	update_weather=0
fi

if [ "$update_weather" = "1" ]; then
	rm -rf /tmp/k3-weather.json
	wget "http://api.seniverse.com/v3/weather/now.json?key=$key&location=$city&language=zh-Hans&unit=c" -T 3 -O /tmp/k3-weather.json 2>/dev/null
fi

weather_json=$(cat /tmp/k3-weather.json 2>/dev/null)
WENDU=`echo $weather_json | jsonfilter -e '@.results[0].now.temperature'`
TYPE=`echo $weather_json | jsonfilter -e '@.results[0].now.code'`

#output weather data
echo $city
echo $WENDU
echo $DATE_DATE
echo $DATE_TIME
echo $TYPE
echo $DATE_WEEK
echo 0