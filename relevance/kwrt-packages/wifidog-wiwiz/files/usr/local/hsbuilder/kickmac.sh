#!/bin/sh
# Wiwiz HotSpot Builder Utility
# Copyright wiwiz.com. All rights reserved.

CMD=$1
MAC=$2

LOCKFILE='/tmp/wiwiz_kickmac.lock'
KICKMAC='/tmp/wiwiz_kickmac'


if [ "$CMD" = "" -o $MAC = ""]; then
	echo "Usage:"
	echo "kickmac.sh add <MAC>"
	echo "kickmac.sh del <MAC>"
	exit 1
fi

GIVEUP=""
for i in `seq 0 30`; do
	LOCK=$(cat $LOCKFILE 2>/dev/null)
	if [ "$LOCK" = "1" ]; then
		echo "Locked, waiting..."
		wdctl sleep 50000
	else
		break
	fi
	if [ "$i" = "30" ]; then
		GIVEUP="1"
	fi	
done
if [ "$GIVEUP" = "1" ]; then
	echo "waited too long. giving up."
	exit 9
fi

echo '1'>$LOCKFILE

if [ "$CMD" = "add" ]; then
	NOW=$(date +%s)
    #deletes old data in KICKMAC (older than 1 min)
	cat $KICKMAC | while read LINE; do
		TIMESTAMP=$(echo "$LINE" | awk '{print $2}')
		TIMEDIFF=$(expr "$NOW" - "$TIMESTAMP")
		if [ "$TIMEDIFF" -gt 60 ]; then
			S=$(cat $KICKMAC | grep -v "$TIMESTAMP" 2>/dev/null)
			echo "$S">$KICKMAC
		fi
	done

    echo "$MAC $NOW">>$KICKMAC    
fi

if [ "$CMD" = "del" ]; then
    S=$(cat $KICKMAC | grep -v $MAC 2>/dev/null)
    echo "$S">KICKMAC
fi

rm -f $LOCKFILE 2>/dev/null