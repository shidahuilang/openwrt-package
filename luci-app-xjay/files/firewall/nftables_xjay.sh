#!/bin/sh

# to use uci shell script functions
. /lib/functions.sh

# parameters
# TPROXY_PORT: $1
# TPROXY_MARK: $2
# WAN_IP: $3
# WAN_IP6: $4
# WAN_BYPASS_PORTS: $5
# WAN_IP6_PREFIX_MASK: $6

BYPASS_WAN_IP=""
BYPASS_WAN_IP6=""
BYPASS_PRIVATE_IP=""
BYPASS_WAN_IP6_PREFIX_MASK=""

# bypass WAN addresses
[ -n "$3" ] && BYPASS_WAN_IP="ip daddr $3 return"
[ -n "$4" ] && BYPASS_WAN_IP6="ip6 daddr $4 return"

# bypass private IP
BYPASS_PRIVATE_IP="
        ip daddr @byp4 return
        ip6 daddr @byp6 return"

# bypass WAN PORT to let service traffic of this device pass
[ -n "$3" ] && [ -n "$5" ] && \
BYPASS_WAN_SIP_SPORT_TCP="ip saddr $3 tcp sport { $5 } return" && \
BYPASS_WAN_SIP_SPORT_UDP="ip saddr $3 udp sport { $5 } return" &&
[ -n "$4" ] && [ -n "$5" ] && \
BYPASS_WAN_SIP6_SPORT_TCP="ip6 saddr $4 tcp sport { $5 } return" && \
BYPASS_WAN_SIP6_SPORT_UDP="ip6 saddr $4 udp sport { $5 } return"

# bypass private IP
BYPASS_PRIVATE_IP="
                ip daddr @byp4 return
                ip6 daddr @byp6 return"
# bypass LAN IPv6 traffic
[ -n "$6" ] && BYPASS_WAN_IP6_PREFIX_MASK="ip6 daddr $6 return"

cat <<-EOF > /var/etc/xjay/nftables_xjay.conf
table inet xjay {
        set byp4 {
                typeof ip daddr
                flags interval
                elements = {
                        0.0.0.0/8, 10.0.0.0/8,
                        127.0.0.0/8, 169.254.0.0/16,
                        172.16.0.0/12, 192.0.0.0/24,
                        192.0.2.0/24, 192.88.99.0/24,
                        192.168.0.0/16, 198.18.0.0/15,
                        198.51.100.0/24, 203.0.113.0/24,
                        224.0.0.0/4, 240.0.0.0-255.255.255.255
                }
        }

        set byp6 {
                typeof ip6 daddr
                flags interval
                elements = {
                        ::,
                        ::1,
                        ::ffff:0:0:0/96,
                        64:ff9b::/96,
                        100::/64,
                        2001::/32,
                        2001:20::/28,
                        2001:db8::/32,
                        2002::/16,
                        fc00::/7,
                        fe80::/10,
                        ff00::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
                }
        }

        chain prerouting {
                type filter hook prerouting priority mangle; policy accept;
                $BYPASS_WAN_IP
                $BYPASS_WAN_IP6
                $BYPASS_PRIVATE_IP
                $BYPASS_WAN_IP6_PREFIX_MASK
                meta mark $2 return
                meta l4proto { tcp, udp } mark set 1 tproxy to :$1 accept
        }

        chain output {
                type route hook output priority mangle; policy accept;
                $BYPASS_WAN_IP
                $BYPASS_WAN_IP6
                $BYPASS_WAN_SIP_SPORT_TCP
                $BYPASS_WAN_SIP_SPORT_UDP
                $BYPASS_WAN_SIP6_SPORT_TCP
                $BYPASS_WAN_SIP6_SPORT_UDP
                $BYPASS_PRIVATE_IP
                $BYPASS_WAN_IP6_PREFIX_MASK
                meta mark $2 return
                meta l4proto { tcp, udp } mark set 1 accept
        }

        chain filter {
                type filter hook prerouting priority mangle; policy accept;
                meta l4proto tcp socket transparent 1 meta mark set 1 accept
        }
}
EOF

nft -f /var/etc/xjay/nftables_xjay.conf

# handle lan control devices
add_lan_devices_rule() {
    local bypassed=$(config_get $1 bypassed)
    local macaddr=$(config_get $1 macaddr)
    if [ "$bypassed" = "1" ]; then
        nft insert rule inet xjay prerouting ether saddr $macaddr return
        nft insert rule inet xjay output ether saddr $macaddr return
    fi
}
config_load xjay
config_foreach add_lan_devices_rule lan_hosts
