#!/bin/sh

if [ -n "$(which nft)" ]; then
	logger -st xjay[$$] -p4 "Resetting nftables rules..."
	nft -f /usr/share/xjay/firewall/nftables_reset.conf
else
	logger -st xjay[$$] -p4 "Resetting iptables rules..."
	/usr/share/xjay/firewall/iptables_reset.sh
fi

# delete ip rules
ip rule del table 100
ip -6 rule del table 106

# flush ip rules in tables
ip route del table 100
ip -6 route del table 106
