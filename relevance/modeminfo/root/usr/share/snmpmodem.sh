#!/bin/sh

# Simple SNMP Script for modeminfo
# Exapmle configuration OpenWrt snmpd package
# file: /etc/config/snmpd
# config exec
#        option name     modem				# Example name
#        option prog     /usr/share/snmpmodem.sh	# This script
#        option args     0				# Modem in system
#        option miboid   1.3.6.1.2.1.25.1.9		# Example OID

if [ ! $1 ]; then
	exit 0
fi

modeminfo | jsonfilter -e "@['modem'][$1]['device']" \
	-e "@['modem'][$1]['cops']" \
	-e "@['modem'][$1]['rssi']" \
	-e "@['modem'][$1]['rsrp']" \
	-e "@['modem'][$1]['rsrq']" \
	-e "@['modem'][$1]['sinr']"

