#!/bin/sh

# Basic vars
TEMP_FILE="/tmp/k3screenctrl/wan_speed"
WAN_STAT=`ifstatus wan`
WAN6_STAT=`ifstatus wan6`

# Internet connectivity
IPV4_ADDR=`echo $WAN_STAT | jsonfilter -e "@['ipv4-address']"`
IPV6_ADDR=`echo $WAN6_STAT | jsonfilter -e "@['ipv6-address']"`

if [ -n "$IPV4_ADDR" -o -n "$IPV6_ADDR" ]; then
    CONNECTED=1
else
    CONNECTED=0
fi

WAN_IFNAME=`echo $WAN_STAT | jsonfilter -e "@.l3_device"` # pppoe-wan
if [ -z "$WAN_IFNAME" ]; then
    WAN_IFNAME=`echo $WAN_STAT | jsonfilter -e "@.device"` # eth0.2
    if [ -z "$WAN_IFNAME" ]; then
        WAN_IFNAME=`uci get network.wan.ifname` # eth0.2
    fi
fi
# If there is still no WAN iface found, the script will fail - but that's rare

# Calculate speed by traffic delta / time delta
# NOTE: /proc/net/dev updates every ~1s.
# You must call this script with longer interval!
CURR_TIME=$(date +%s)
CURR_STAT=$(cat /proc/net/dev | grep $WAN_IFNAME | sed -e 's/^ *//' -e 's/  */ /g')
CURR_DOWNLOAD_BYTES=$(echo $CURR_STAT | cut -d " " -f 2)
CURR_UPLOAD_BYTES=$(echo $CURR_STAT | cut -d " " -f 10)

if [ -e "$TEMP_FILE" ]; then
    LINENO=0
    while read line; do
        case "$LINENO" in
            0)
                LAST_TIME=$line
                ;;
            1)
                LAST_UPLOAD_BYTES=$line
                ;;
            2)
                LAST_DOWNLOAD_BYTES=$line
                ;;
            *)
                ;;
        esac
        LINENO=$(($LINENO+1))
    done < $TEMP_FILE
fi

echo $CURR_TIME > $TEMP_FILE
echo $CURR_UPLOAD_BYTES >> $TEMP_FILE
echo $CURR_DOWNLOAD_BYTES >> $TEMP_FILE

if [ -z "$LAST_TIME" -o -z "$LAST_UPLOAD_BYTES" -o -z "$LAST_DOWNLOAD_BYTES" ]; then
    # First time of launch
    UPLOAD_BPS=0
    DOWNLOAD_BPS=0
else
    TIME_DELTA_S=$(($CURR_TIME-$LAST_TIME))
    if [ $TIME_DELTA_S -eq 0 ]; then
        TIME_DELTA_S=1
    fi
    UPLOAD_BPS=$((($CURR_UPLOAD_BYTES-$LAST_UPLOAD_BYTES)/$TIME_DELTA_S))
    DOWNLOAD_BPS=$((($CURR_DOWNLOAD_BYTES-$LAST_DOWNLOAD_BYTES)/$TIME_DELTA_S))
fi

echo $CONNECTED
echo $UPLOAD_BPS
echo $DOWNLOAD_BPS
