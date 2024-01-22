#!/bin/sh
. /usr/share/libubox/jshn.sh

json_load "$(/usr/bin/modeminfo)"
json_get_var DEVICE device
json_get_var COPS cops
json_get_var MODE mode
json_get_var PERS csq_per
echo -ne "*Device:* $DEVICE\n*Operator:* $COPS 📶${PERS}% $MODE\n"
json_get_var CH arfcn
. /usr/share/modeminfo/scripts/ch_to_band
ch_to_band $CH
json_get_var RSSI rssi
case $MODE in
	LTE)
		json_get_var CA lteca
		if [ $CA -ge 1 ]; then
		        json_get_var SB scc
		        CA="$(($CA+1))xCA"
		        BAND="${SC}${SB}"
		        echo -ne "*CA:* $CA BAND ($BAND)\n"
		else
		        echo -ne "*BAND:* $SC\n"
		fi
		json_get_var RSRP rsrp
		json_get_var RSRQ rsrq
		json_get_var SINR sinr
		json_get_var ENBID enbid
		json_get_var PCI pci
		json_get_var CELL cell
        	json_get_var DIST distance
		echo -ne "*RSSI/RSRP:* ${RSSI}dBm/${RSRP}dBm\n*RSRQ/SINR:* ${RSRQ}dB/${SINR}dB\n*eNBID-Cell/PCI:* ${ENBID}-${CELL}/${PCI}"
                if [ $DIST ] && [ "$DIST" -ne "0.00" ]; then
                        echo -ne " ~${DIST}km\n"
                else
                        echo -ne "\n"
                fi
	;;
	UMT*|WCD*|*HSP*|*HUS*)
		json_get_var SINR sinr
		json_get_var LAC lac
		json_get_var CID cid
		echo -ne "*BAND:* $SC\n"
		echo -ne "*RSSI/ECIO:* ${RSSI}dBm/${SINR}dB\n*LAC/CID:* ${LAC}/${CID}"
	;;
	*)
		json_get_var LAC lac
		json_get_var CID cid
		echo -ne "*BAND:* $SC\n"
		echo -ne "*RSSI:*  ${RSSI}dBm\n*LAC/CID:* ${LAC}/${CID}"
	;;
esac

