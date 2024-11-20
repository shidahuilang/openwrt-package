#!/bin/sh

# to use uci shell script functions
. /lib/functions.sh

# dependencies: iptables-mod-tproxy, iptables-mod-iprange

# parameters
# TPROXY_PORT: $1
# TPROXY_MARK: $2
# WAN_IP: $3
# WAN_IP6: $4
# WAN_BYPASS_PORTS: $5
# WAN_IP6_PREFIX_MASK: $6

# list private IPv4 ipaddresses
PRIVATE_IP="0.0.0.0/8,10.0.0.0/8,\
127.0.0.0/8,169.254.0.0/16,\
172.16.0.0/12,192.0.0.0/24,\
192.0.2.0/24,192.88.99.0/24,\
192.168.0.0/16,198.18.0.0/15,\
198.51.100.0/24,203.0.113.0/24"

MULTICAST_IP="240.0.0.0-255.255.255.255"

# list private IPv6 ipaddresses
PRIVATE_IP6="
::,\
::1,\
::ffff:0:0:0/96,\
64:ff9b::/96,\
100::/64,\
2001::/32,\
2001:20::/28,\
2001:db8::/32,\
2002::/16,\
fc00::/7,\
fe80::/10"

MULTICAST_IP6="ff00::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"

# handle IPv4 traffic coming into this device
iptables -t mangle -N XJAY
# bypass WAN IPv4 addresses
[ -n "$3" ] && iptables -t mangle -A XJAY -d $3 -j RETURN
if [ "$6" == "true" ]; then
        # bypass all private IPv4 addresses but hijack dns traffic
        iptables -t mangle -A XJAY -d $PRIVATE_IP -p tcp ! --dport 53 -j RETURN
        iptables -t mangle -A XJAY -d $PRIVATE_IP -p udp ! --dport 53 -j RETURN
else
        # bypass all private IPv4 addresses
        iptables -t mangle -A XJAY -d $PRIVATE_IP -j RETURN
fi
iptables -t mangle -A XJAY -m iprange --dst-range $MULTICAST_IP -j RETURN
# avoid traffic loop for the case of dns ptr queries
iptables -t mangle -A XJAY -m mark --mark $2 -j RETURN
# hijack all IPv4 traffic into this device to proxy port
iptables -t mangle -A XJAY -p tcp -j TPROXY --on-port $1 --tproxy-mark 1
iptables -t mangle -A XJAY -p udp -j TPROXY --on-port $1 --tproxy-mark 1
iptables -t mangle -A PREROUTING -j XJAY

# handle IPv4 traffic going out from this device
iptables -t mangle -N XJAY_MASK
# bypass WAN IPv4 addresses
[ -n "$3" ] && iptables -t mangle -A XJAY_MASK -d $3 -j RETURN
# bypass WAN PORT to let service traffic of this device pass
[ -n "$3" ] && [ -n "$5" ] && iptables -t mangle -A XJAY_MASK -s $3 -p tcp -m multiport --sport $5 -j RETURN
[ -n "$3" ] && [ -n "$5" ] && iptables -t mangle -A XJAY_MASK -s $3 -p udp -m multiport --sport $5 -j RETURN
if [ "$6" == "true" ]; then
        # bypass all private IPv4 addresses but hijack dns traffic
        iptables -t mangle -A XJAY_MASK -d $PRIVATE_IP -p tcp ! --dport 53 -j RETURN
        iptables -t mangle -A XJAY_MASK -d $PRIVATE_IP -p udp ! --dport 53 -j RETURN
else
        # bypass all private IPv4 addresses
        iptables -t mangle -A XJAY_MASK -d $PRIVATE_IP -j RETURN
fi
iptables -t mangle -A XJAY_MASK -m iprange --dst-range $MULTICAST_IP -j RETURN
# bypass xray IPv4 outbound traffic to avoid loop
iptables -t mangle -A XJAY_MASK -m mark --mark $2 -j RETURN
# hijack all IPv4 traffic going out from this device to xray
iptables -t mangle -A XJAY_MASK -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -j XJAY_MASK

# handle IPv6 traffic coming into this device
ip6tables -t mangle -N XJAY6
# bypass WAN IPv6 addresses
[ -n "$4" ] && ip6tables -t mangle -A XJAY6 -d $4 -j RETURN
# bypass all private IPv6 addresses
ip6tables -t mangle -A XJAY6 -d $PRIVATE_IP6 -j RETURN
[ -n "$6" ] && ip6tables -t mangle -A XJAY6 -d $WAN_IP6_PREFIX_MASK -j RETURN
ip6tables -t mangle -A XJAY6 -m iprange --dst-range $MULTICAST_IP6 -j RETURN
# avoid traffic loop for the case of dns ptr queries
ip6tables -t mangle -A XJAY6 -m mark --mark $2 -j RETURN
# hijack all IPv6 traffic into this device to proxy port
ip6tables -t mangle -A XJAY6 -p udp -j TPROXY --on-port $1 --tproxy-mark 1
ip6tables -t mangle -A XJAY6 -p tcp -j TPROXY --on-port $1 --tproxy-mark 1
ip6tables -t mangle -A PREROUTING -j XJAY6

# handle IPv6 traffic going out from this device
ip6tables -t mangle -N XJAY6_MASK
# bypass WAN IPv6 addresses
[ -n "$4" ] && ip6tables -t mangle -A XJAY6_MASK -d $4 -j RETURN
# bypass WAN PORT to let service traffic of this device pass
[ -n "$4" ] && [ -n "$5" ] && ip6tables -t mangle -A XJAY_MASK -s $4 -p tcp -m multiport --sport $5 -j RETURN
[ -n "$4" ] && [ -n "$5" ] && ip6tables -t mangle -A XJAY_MASK -s $4 -p udp -m multiport --sport $5 -j RETURN
# bypass all private IPv6 addresses
ip6tables -t mangle -A XJAY6_MASK -d $PRIVATE_IP6 -j RETURN
# bypass LAN IPv6 traffic
[ -n "$6" ] && ip6tables -t mangle -A XJAY6_MASK -d $WAN_IP6_PREFIX_MASK -j RETURN
ip6tables -t mangle -A XJAY6_MASK -m iprange --dst-range $MULTICAST_IP6 -j RETURN
# bypass xray IPv6 outbound traffic to avoid loop
ip6tables -t mangle -A XJAY6_MASK -m mark --mark $2 -j RETURN
# hijack all IPv6 traffic going out from this device to xray
ip6tables -t mangle -A XJAY6_MASK -j MARK --set-mark 1
ip6tables -t mangle -A OUTPUT -j XJAY6_MASK

# add divert rules to improve speed theoretically
# this rule avoids established connections to go through tproxy agian
iptables -t mangle -N DIVERT
iptables -t mangle -A DIVERT -j MARK --set-mark 1
iptables -t mangle -A DIVERT -j ACCEPT
iptables -t mangle -I PREROUTING -p tcp -m socket -j DIVERT
ip6tables -t mangle -N DIVERT6
ip6tables -t mangle -A DIVERT6 -j MARK --set-mark 1
ip6tables -t mangle -A DIVERT6 -j ACCEPT
ip6tables -t mangle -I PREROUTING -p tcp -m socket -j DIVERT6


# handle lan control devices
add_lan_devices_rule() {
    local bypassed=$(config_get $1 bypassed)
    local macaddr=$(config_get $1 macaddr)
    if [ "$bypassed" = "1" ]; then
        iptables -t mangle -I XJAY -m mac --mac-source $macaddr -j RETURN
        # x_tables: ip_tables: mac match: used from hooks OUTPUT, but only valid from PREROUTING/INPUT/FORWARD
        # iptables -t mangle -I XJAY_MASK -m mac --mac-source $macaddr -j RETURN
        ip6tables -t mangle -I XJAY6 -m mac --mac-source $macaddr -j RETURN
        # ip6tables -t mangle -I XJAY6_MASK -m mac --mac-source $macaddr -j RETURN
    fi
}
config_load xjay
config_foreach add_lan_devices_rule lan_hosts
