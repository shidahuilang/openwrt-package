#!/bin/sh
# Wiwiz HotSpot Builder Utility
# Copyright wiwiz.com. All rights reserved.

MAC="$1"


if [ "$MAC" == "" ]; then
    echo 'usage : checkauth.sh <MAC>'
    exit 1
fi

#IS_AUTHED=$(wdctl status 2>/dev/null | grep 'IP:' | grep 'MAC:' | grep -i "$MAC")
IS_AUTHED=$(wdctl status 2>/dev/null | grep -i "$MAC")
if [ "$IS_AUTHED" != "" ]; then
    echo 'true'
else
    echo 'false'
fi
