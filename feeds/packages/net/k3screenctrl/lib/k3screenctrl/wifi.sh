#!/bin/sh

COMPLETE_STAT=`wifi status`

print_wifi_info() {
    local ucidev=$1 ifname=$2
    local status device_json ssid psk client_count=0 enabled=0

    device_json=`echo $COMPLETE_STAT | jsonfilter -e "@.$ucidev"`
    if [ -n "$device_json" ]; then
        status=`echo $device_json | jsonfilter -e "@.disabled"`
        if [ "x$status" == "xfalse" -a -n "` echo $device_json | jsonfilter -e \"@.interfaces[0]\"`" ]; then
            ssid=`echo $COMPLETE_STAT | jsonfilter -e "@.$ucidev.interfaces[0].config.ssid"`
            psk=`echo $COMPLETE_STAT | jsonfilter -e "@.$ucidev.interfaces[0].config.key"`
            #client_count=`iw dev $ifname station dump | grep Station | wc -l`
            client_count=`iwinfo $ifname assoclist | grep dBm | wc -l`
            enabled=1
        fi
    fi

    echo $ssid

    if [ $(uci get k3screenctrl.@general[0].psk_hide) -eq 1 ]; then
        echo $psk | sed 's/./*/g'
    else
        echo $psk
    fi
    echo $enabled
    echo $client_count
}

echo 0 # Band mix
print_wifi_info radio0 wlan0 # 2.4GHz
print_wifi_info radio1 wlan1 # 5GHZ
print_wifi_info radiox wlanx # Visitor - not implemented
