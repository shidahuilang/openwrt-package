#!/bin/sh

. $IPKG_INSTROOT/etc/init.d/xclient
LOCK_FILE="/var/lock/monitor.lock"
[ -f "$LOCK_FILE" ] && exit 2
touch "$LOCK_FILE"
redir_tcp_process=$1
redir_udp_process=$2
pdnsd_process=$3
if [ -z "$pdnsd_process" ]; then
	pdnsd_process=0
fi
i=0
GLOBAL_SERVER=$(uci_get_by_type global global_server)
server=$(uci_get_by_name $GLOBAL_SERVER server)
server_port=$(uci_get_by_name $GLOBAL_SERVER server_port)


while [ "1" == "1" ]; do 
	sleep 1
	#redir tcp
	if [ "$redir_tcp_process" -gt 0 ]; then
		icount=$(busybox ps -w | grep xclient-retcp | grep -v grep | wc -l)
		if [ "$icount" == 0 ]; then
			logger -t "$NAME" "xclient redir tcp error.restart!"
			echolog "xclient redir tcp error.restart!"
			/etc/init.d/xclient reload
			exit 0
		fi
	fi
	#redir udp
	if [ "$redir_udp_process" -gt 0 ]; then
		icount=$(busybox ps -w | grep xclient-reudp | grep -v grep | wc -l)
		if [ "$icount" == 0 ]; then
			logger -t "$NAME" "xclient redir udp error.restart!"
			echolog "xclient redir udp error.restart!"
			/etc/init.d/xclient reload
			exit 0
		fi
	fi
	#pdnsd
	if [ "$pdnsd_process" -eq 1 ]; then
		icount=$(busybox ps -w | grep $TMP_BIN_PATH/pdnsd | grep -v grep | wc -l)
		if [ "$icount" -lt "$pdnsd_process" ]; then 
			logger -t "$NAME" "pdnsd tunnel error.restart!"
			echolog "pdnsd tunnel error.restart!"
			if [ -f /var/run/pdnsd.pid ]; then
				kill $(cat /var/run/pdnsd.pid) >/dev/null 2>&1
			else
				kill -9 $(ps | grep $TMP_PATH/pdnsd.conf | grep -v grep | awk '{print $1}') >/dev/null 2>&1
			fi
			ln_start_bin $(first_type pdnsd) pdnsd -c $TMP_PATH/pdnsd.conf
		fi
	fi
	#dns2socks
	if [ "$pdnsd_process" -eq 2 ]; then
		icount=$(busybox ps -w | grep -e xclient-dns -e "dns2socks 127.0.0.1 $tmp_dns_port" | grep -v grep | wc -l)
		if [ "$icount" -lt 2 ]; then 
			logger -t "$NAME" "dns2socks $dnsstr tunnel error.restart!"
			echolog "dns2socks $dnsstr tunnel error.restart!"
			dnsstr=$(uci_get_by_type global tunnel_forward 8.8.4.4:53)
			dnsserver=$(echo "$dnsstr" | awk -F ':' '{print $1}')
			dnsport=$(echo "$dnsstr" | awk -F ':' '{print $2}')
			kill -9 $(busybox ps -w | grep xclient-dns | grep -v grep | awk '{print $1}') >/dev/null 2>&1
			kill -9 $(busybox ps -w | grep "dns2socks 127.0.0.1 $tmp_dns_port" | grep -v grep | awk '{print $1}') >/dev/null 2>&1
			ln_start_bin $(first_type microsocks) microsocks -i 127.0.0.1 -p $tmp_dns_port xclient-dns
			ln_start_bin $(first_type dns2socks) dns2socks 127.0.0.1:$tmp_dns_port $dnsserver:$dnsport 127.0.0.1:$dns_port -q
		fi
	fi
done
