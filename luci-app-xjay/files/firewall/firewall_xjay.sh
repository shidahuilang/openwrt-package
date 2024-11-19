#!/bin/sh

# DEFAULT_INBOUND_CFG: $1

# get wan ip addresses
WAN_PROTOCOL=$(uci -q get network.wan.proto)
WAN_BP_PORTS=$(uci -q get xjay.@routing[0].service_port)
# replace blank with comma to pass it as parameter
WAN_BP_PORTS=$(echo $WAN_BP_PORTS | tr " " ,)

# get inbound port
INBOUND_PORT=$(uci -q get xjay.$1.port)
INBOUND_PROTOCOL=$(uci -q get xjay.$1.protocol)
INBOUND_TPROXY=$(uci -q get xjay.$1.sockopt_tproxy)
SOCKOPT_MARK=$(uci -q get xjay.@outbound[0].sockopt_mark)

# the default inbound has to be dokodemo-door and tproxy, otherwise we skip creating firewall rules
if [[ "$INBOUND_PROTOCOL" == "dokodemo-door" && "$INBOUND_TPROXY" == "tproxy" ]]; then
        logger -st xjay[$$] -p4 "Default inbound OK: $INBOUND_PROTOCOL, $INBOUND_TPROXY. Generating firewall rules..."
else
        logger -st xjay[$$] -p4 "Default inbound NOK: $INBOUND_PROTOCOL, $INBOUND_TPROXY. Abort firewall rules..."
        exit 0
fi

if [ "$WAN_PROTOCOL" == "pppoe" ]; then
        # pppoe ip-up.d scripts will be invoked for ipv4 and ipv6.
        # here we only need one of them, so filtered ipv6 invoke.
        # pppoe will pass WAN IP as 4th arguments to the script.
        # for pppoe, ipv6 will be handled in interface wan_6.
        ipv6_iface="wan_6"
else
        # for dhcp or others, ipv6 will be handled in interface wan6.
        ipv6_iface="wan6"
fi
WAN_IP=$(ifstatus wan | jsonfilter -e "@['ipv4-address'][0].address"  2>/dev/null)
if [ -n "$ipv6_iface" ]; then
        WAN_IP6=$(ifstatus $ipv6_iface | jsonfilter -e "@['ipv6-address'][0].address"  2>/dev/null)
        WAN_IP6_PREFIX=$(ifstatus $ipv6_iface | jsonfilter -e "@['ipv6-prefix'][0].address"  2>/dev/null)
        WAN_IP6_MASK=$(ifstatus $ipv6_iface | jsonfilter -e "@['ipv6-prefix'][0].mask"  2>/dev/null)
        [ -n "$WAN_IP6_PREFIX" ] && [ -n "$WAN_IP6_MASK" ] && WAN_IP6_PREFIX_MASK="$WAN_IP6_PREFIX/$WAN_IP6_MASK"
fi

# handling IPv4 rules
ip route add local 0.0.0.0/0 dev lo table 100
ip rule add fwmark 1 table 100

# handling IPv6 rules
ip -6 route add local ::/0 dev lo table 106
ip -6 rule add fwmark 1 table 106

# set up firewall rules based on which tools available
if [ -n "$(which nft)" ]; then
        logger -st xjay[$$] -p4 "Setting up nftables rules..."
        /usr/share/xjay/firewall/nftables_xjay.sh "$INBOUND_PORT" \
                                                "$SOCKOPT_MARK" \
                                                "$WAN_IP" "$WAN_IP6" \
                                                "$WAN_BP_PORTS" \
                                                "$WAN_IP6_PREFIX_MASK"
else
        logger -st xjay[$$] -p4 "Setting up iptables rules..."
        /usr/share/xjay/firewall/iptables_xjay.sh "$INBOUND_PORT" \
                                                "$SOCKOPT_MARK" \
                                                "$WAN_IP" \
                                                "$WAN_IP6" \
                                                "$WAN_BP_PORTS" \
                                                "$WAN_IP6_PREFIX_MASK"
fi
