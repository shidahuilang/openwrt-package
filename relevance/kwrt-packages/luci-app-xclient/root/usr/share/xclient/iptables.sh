#!/bin/sh

TAG="_XCLIENT_SPEC_RULE_"                                  # comment tag
IPT="iptables -t nat"                                 # alias of iptables
FWI=$(uci get firewall.xclient.path 2>/dev/null) # firewall include file
usage() {
	cat <<-EOF
		Usage: xrules [options]

		Valid options are:

		    -s <server_ip>          ip address of xclient remote server
		    -l <local_port>         port number of xclient local server
		    -S <server_ip>          ip address of xclient remote UDP server
		    -L <local_port>         port number of xclient local UDP server
		                            define access control mode
		    -b <wan_ips>            wan ip of will be bypassed
		    -B <bp_lan_ips>         lan ip of will be bypassed proxy
		    -p <fp_lan_ips>         lan ip of will be global proxy
		    -m <Interface>          Interface name
		    -e <extra_options>      extra options for iptables
		    -u                      enable udprelay mode, TPROXY is required
		    -U                      enable udprelay mode, using different IP
		                            and ports for TCP and UDP
		    -f                      flush the rules
		    -h                      show this help message and exit
	EOF
	exit $1
}

loger() {
	# 1.alert 2.crit 3.err 4.warn 5.notice 6.info 7.debug
	logger -st xrules[$$] -p$1 $2
}

flush_r() {
	flush_iptables() {
		local ipt="iptables -t $1"
		local DAT=$(iptables-save -t $1)
		eval $(echo "$DAT" | grep "$TAG" | sed -e 's/^-A/$ipt -D/' -e 's/$/;/')
		for chain in $(echo "$DAT" | awk '/^:XCLIENT_SPEC/{print $1}'); do
			$ipt -F ${chain:1} 2>/dev/null && $ipt -X ${chain:1}
		done
	}
	flush_iptables nat
	flush_iptables mangle
	ip rule del fwmark 0x01/0x01 table 100 2>/dev/null
	ip route del local 0.0.0.0/0 dev lo table 100 2>/dev/null
	ipset -X xclient_spec_wan_ac 2>/dev/null
	ipset -X fplan 2>/dev/null
	ipset -X bplan 2>/dev/null
	ipset -X blacklist 2>/dev/null
	[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
	return 0
}

ipset_r() {
	ipset -! -R <<-EOF || return 1
		create xclient_spec_wan_ac hash:net
		$(gen_spec_iplist | sed -e "s/^/add xclient_spec_wan_ac /")
	EOF
	$IPT -N XCLIENT_SPEC_WAN_AC
	$IPT -I XCLIENT_SPEC_WAN_AC -p tcp ! --dport 53 -d $server -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_AC -m set --match-set xclient_spec_wan_ac dst -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_AC -j XCLIENT_SPEC_WAN_FW
	ipset -N fplan hash:net 2>/dev/null
	for ip in $LAN_FP_IP; do ipset -! add fplan $ip; done
	$IPT -I XCLIENT_SPEC_WAN_AC -m set --match-set fplan src -j XCLIENT_SPEC_WAN_FW
	ipset -N bplan hash:net 2>/dev/null
	for ip in $LAN_BP_IP; do ipset -! add bplan $ip; done
	$IPT -I XCLIENT_SPEC_WAN_AC -m set --match-set bplan src -j RETURN
	ipset -N blacklist hash:net 2>/dev/null
	$IPT -I XCLIENT_SPEC_WAN_AC -m set --match-set blacklist dst -j RETURN
	if [ $(ipset list music -name -quiet | grep music) ]; then
		$IPT -I XCLIENT_SPEC_WAN_AC -m set --match-set music dst -j RETURN 2>/dev/null
	fi
	for ip in $WAN_BP_IP; do ipset -! add blacklist $ip; done
	return $?
}

fw_rule() {
	$IPT -N XCLIENT_SPEC_WAN_FW
	$IPT -A XCLIENT_SPEC_WAN_FW -d 0.0.0.0/8 -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_FW -d 10.0.0.0/8 -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_FW -d 127.0.0.0/8 -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_FW -d 169.254.0.0/16 -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_FW -d 172.16.0.0/12 -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_FW -d 192.168.0.0/16 -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_FW -d 224.0.0.0/4 -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_FW -d 240.0.0.0/4 -j RETURN
	$IPT -A XCLIENT_SPEC_WAN_FW -p tcp -j REDIRECT --to-ports $local_port 2>/dev/null || {
		loger 3 "Can't redirect, please check the iptables."
		exit 1
	}
	return $?
}

ac_rule() {
	if [ -z "$Interface" ]; then
		$IPT -I PREROUTING 1 -p tcp $EXT_ARGS  -m comment --comment "$TAG" -j XCLIENT_SPEC_WAN_AC
	else
		for name in $Interface; do
			local IFNAME=$(uci -P /var/state get network.$name.device 2>/dev/null)
			[ -n "$IFNAME" ] && $IPT -I PREROUTING 1 ${IFNAME:+-i $IFNAME} -p tcp $EXT_ARGS  -m comment --comment "$TAG" -j XCLIENT_SPEC_WAN_AC
		done
	fi
	$IPT -I OUTPUT 1 -p tcp $EXT_ARGS -m comment --comment "$TAG" -j XCLIENT_SPEC_WAN_AC
	return $?
}

tp_rule() {
	[ -n "$TPROXY" ] || return 0
	ip rule add fwmark 0x01/0x01 table 100
	ip route add local 0.0.0.0/0 dev lo table 100
	local ipt="iptables -t mangle"
	$ipt -N XCLIENT_SPEC_TPROXY
	$ipt -A XCLIENT_SPEC_TPROXY -p udp --dport 53 -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -d 0.0.0.0/8 -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -d 10.0.0.0/8 -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -d 127.0.0.0/8 -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -d 169.254.0.0/16 -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -d 172.16.0.0/12 -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -d 192.168.0.0/16 -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -d 224.0.0.0/4 -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -d 240.0.0.0/4 -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp ! --dport 53 -d $SERVER -j RETURN
	[ "$server" != "$SERVER" ] && ipset -! add blacklist $SERVER
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -m set --match-set bplan src -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -m set --match-set fplan src -j TPROXY --on-port "$LOCAL_PORT" --tproxy-mark 0x01/0x01
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -m set --match-set xclient_spec_wan_ac dst -j RETURN
	$ipt -A XCLIENT_SPEC_TPROXY -p udp -j TPROXY --on-port "$LOCAL_PORT" --tproxy-mark 0x01/0x01
	if [ -z "$Interface" ]; then
		$ipt -I PREROUTING 1 -p udp $EXT_ARGS  -m comment --comment "$TAG" -j XCLIENT_SPEC_TPROXY
	else
		for name in $Interface; do
			local IFNAME=$(uci -P /var/state get network.$name.device 2>/dev/null)
			[ -n "$IFNAME" ] && $ipt -I PREROUTING 1 ${IFNAME:+-i $IFNAME} -p udp $EXT_ARGS -m comment --comment "$TAG" -j XCLIENT_SPEC_TPROXY
		done
	fi
	return $?
}

get_wan_ip() {
	cat <<-EOF | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}"
		$server
		$SERVER
		$WAN_BP_IP
	EOF
}

gen_spec_iplist() {
	cat <<-EOF
		0.0.0.0/8
		10.0.0.0/8
		100.64.0.0/10
		127.0.0.0/8
		169.254.0.0/16
		172.16.0.0/12
		192.0.0.0/24
		192.0.2.0/24
		192.88.99.0/24
		192.168.0.0/16
		198.18.0.0/15
		198.51.100.0/24
		203.0.113.0/24
		224.0.0.0/4
		240.0.0.0/4
		255.255.255.255
		$(get_wan_ip)
	EOF
}

gen_include() {
	[ -n "$FWI" ] || return 0
	extract_rules() {
		echo "*$1"
		iptables-save -t $1 | grep XCLIENT_SPEC_ | sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/"
		echo 'COMMIT'
	}
	cat <<-EOF >>$FWI
		iptables-save -c | grep -v "XCLIENT_SPEC" | iptables-restore -c
		iptables-restore -n <<-EOT
		$(extract_rules nat)
		$(extract_rules mangle)
		EOT
	EOF
	return 0
}

while getopts ":m:s:l:S:L:e:B:b:p:D:uUfh" arg; do
	case "$arg" in
	m)
		Interface=$OPTARG
		;;
	s)
		server=$OPTARG
		;;
	l)
		local_port=$OPTARG
		;;
	S)
		SERVER=$OPTARG
		;;
	L)
		LOCAL_PORT=$OPTARG
		;;
	e)
		EXT_ARGS=$OPTARG
		;;
	B)
		LAN_BP_IP=$OPTARG
		;;
	b)
		WAN_BP_IP=$(for ip in $OPTARG; do echo $ip; done)
		;;
	p)
		LAN_FP_IP=$OPTARG
		;;
	u)
		TPROXY=1
		;;
	U)
		TPROXY=2
		;;
	f)
		flush_r
		exit 0
		;;
	h) usage 0 ;;
	esac
done

if [ -z "$server" -o -z "$local_port" ]; then
	usage 2
fi

case "$TPROXY" in
1)
	SERVER=$server
	LOCAL_PORT=$local_port
	;;
2)
	: ${SERVER:?"You must assign an ip for the udp relay server."}
	: ${LOCAL_PORT:?"You must assign a port for the udp relay server."}
	;;
esac

flush_r && fw_rule && ipset_r && ac_rule && tp_rule && gen_include
RET=$?
[ "$RET" = 0 ] || loger 3 "Start failed!"
exit $RET
