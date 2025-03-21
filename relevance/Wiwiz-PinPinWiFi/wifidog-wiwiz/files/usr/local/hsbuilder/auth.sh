#!/bin/sh
LOGFILE='/tmp/hsbuilder.log'

AS_HOSTNAME_X=$(uci get wiwiz.portal.server 2>/dev/null)
HID=$(uci get wiwiz.portal.hotspotid 2>/dev/null)
GWIF=$(uci get wiwiz.portal.lan 2>/dev/null)
GWIFMAC=$(ifconfig $GWIF | grep HWaddr | awk '{print $5}' 2>/dev/null)

URL="http://$AS_HOSTNAME_X/as/s/auth/?stage=batch&gw_id=$HID&gw_mac=$GWIFMAC"

curl -m 30 -o /tmp/wiwiz_auth_data -d "data=$(cat /tmp/wiwiz_client_data)" "$URL" 1>/dev/null 2>/dev/null

