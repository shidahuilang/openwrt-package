#!/bin/sh
# Wiwiz HotSpot Builder Utility
# Copyright wiwiz.com. All rights reserved.
. /usr/share/libubox/jshn.sh

count_interfaces() {
    echo $2
}

json_load "$(ubus call network.wireless status)"
json_get_keys keys
for DEV in $keys; do
    #echo $DEV
    if [ "$DEV" == "" ]; then
        continue
    fi

    json_select "$DEV"
    for i in $(json_for_each_item "count_interfaces" "interfaces"); do
        #echo json_select "interfaces"
        json_select "interfaces"

        #echo json_select $i
        json_select $i

        #echo json_get_var IFNAME "ifname"
        json_get_var IFNAME "ifname"

        #echo json_select config
        json_select config
        json_get_var MODE "mode"

        #echo MODE = $MODE, IFNAME = $IFNAME
        if [ "$MODE" == "ap" ]; then
            ACCOCLIST="$(iwinfo $IFNAME accoclist | grep dBm | grep ':' | awk '{print $1}')"
            echo "$ACCOCLIST"
        fi

        json_select ..
        json_select ..
        json_select ..
        #echo 'loop end'
    done
    json_select ..
    #echo 'LOOP end'
done
