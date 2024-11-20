#!/bin/sh
# Wiwiz HotSpot Builder Utility
# Copyright wiwiz.com. All rights reserved.
. /usr/share/libubox/jshn.sh

LOGFILE=/tmp/wiwiz_autokick.log
SLEEPTIME=20

count_interfaces() {
    echo $2
}

makekickjson() {
    echo `. /usr/share/libubox/jshn.sh
    json_init;
    json_add_string "addr" "$1";
    json_add_int "reason" 15;
    json_add_boolean "deauth" 1;
    json_add_string "ban_time" "3000";
    json_dump`
}

dokick() {
    MAC=$1
    KICKED=0

    json_load "$(ubus call network.wireless status)"
    json_get_keys keys
    for DEV in $keys; do
        echo $DEV
        if [ "$DEV" == "" ]; then
            continue
        fi

        json_select "$DEV"
        for i in $(json_for_each_item "count_interfaces" "interfaces"); do
            echo json_select "interfaces"
            json_select "interfaces"

            echo json_select $i
            json_select $i

            echo json_get_var IFNAME "ifname"
            json_get_var IFNAME "ifname"

            echo json_select config
            json_select config
            json_get_var MODE "mode"

            echo MODE = $MODE, IFNAME = $IFNAME
            if [ "$MODE" == "ap" ]; then
                ACCOCLIST=$(iwinfo $IFNAME accoclist | grep dBm | grep ':' | awk '{print $1}')
                FINDMAC=$(echo "$ACCOCLIST" | grep -i "$MAC")
                if [ "$FINDMAC" != "" ]; then
                    echo found $MAC
                    KICKED=1
                    # kicks off wireless user
                    #MSG_JSON=$(sh /usr/bin/makekickjson.sh $MAC 2>/dev/null)
                    MSG_JSON=$(makekickjson $MAC 2>/dev/null)
                    echo "$MSG_JSON"
                    ubus call hostapd.$IFNAME del_client "$MSG_JSON"
                    sleep 1
                    ubus call hostapd.$IFNAME del_client "$MSG_JSON"

                    echo ubus call "hostapd.$IFNAME" del_client "$MSG_JSON"
                fi
            fi

            json_select ..
            json_select ..
            json_select ..
            echo 'loop end'
        done
        json_select ..
        echo 'LOOP end'
    done

    if [ "$KICKED" == "1" ]; then
        # tells GW I kicked it
        _ss=$(curl -m 5 "http://$GW_IP/cgi-bin/kickmac?act=kick&mac=$MAC" 2>/dev/null)
                
        OUTPUT="kick $MAC, GW said: $_ss"
        echo $OUTPUT
        if [ "$SAVE_LOG" = "1" ]; then
            echo $OUTPUT>>$LOGFILE
        fi
    fi
}

while :
do
    ENABLED=$(uci get autokick.autokick.enabled 2>/dev/null)
    if [ "$ENABLED" != "1" ]; then
        echo "ENABLED = $ENABLED"
        sleep $SLEEPTIME
        continue
    fi

    GW_IP=$(uci get autokick.autokick.gw_ip 2>/dev/null)
    SAVE_LOG=$(uci get autokick.autokick.save_log 2>/dev/null)

    _s=$(curl -m 5 "http://$GW_IP/cgi-bin/kickmac?act=list" 2>/dev/null)
    if [ "$_s" == "" ]; then
        echo "GW says: $_s"
        sleep $SLEEPTIME
        continue
    fi

    #NOW=$(date +%s)
    TIMESTAMP=$(echo "$_s" | grep 'timestamp' | awk '{print $2}')

    echo "$_s" | grep -v 'timestamp' | while read LINE; do
        if [ "$LINE" == "" ]; then
            echo "LINE is empty"
            continue
        fi

        MAC=$(echo "$LINE" | awk '{print $1}')
        if [ "$MAC" == "" ]; then
            echo "MAC is empty"
            continue
        fi
        MAC_TIMESTAMP=$(echo "$LINE" | awk '{print $2}')
        if [ "$MAC_TIMESTAMP" == "" ]; then
            echo "MAC_TIMESTAMP is empty"
            continue
        fi

        TIMEDIFF=$(expr "$TIMESTAMP" - "$MAC_TIMESTAMP")
        echo "TIMEDIFF = $TIMEDIFF"
        if [ "$TIMEDIFF" -lt 60 ]; then # if TIMEDIFF < 60
            dokick $MAC
            sleep 4
            dokick $MAC
        fi
    done

	sleep $SLEEPTIME
done
