#!/bin/sh

VERSION="0.5.34"

. /lib/functions.sh
config_load 'qosmate'

# Default values
DEFAULT_WAN="eth1"
DEFAULT_DOWNRATE="90000"
DEFAULT_UPRATE="45000"
DEFAULT_OH="44"

load_config() {
    # Global settings
    ROOT_QDISC=$(uci -q get qosmate.settings.ROOT_QDISC || echo "hfsc")
    WAN=$(uci -q get qosmate.settings.WAN || echo "$DEFAULT_WAN")
    DOWNRATE=$(uci -q get qosmate.settings.DOWNRATE || echo "$DEFAULT_DOWNRATE")
    UPRATE=$(uci -q get qosmate.settings.UPRATE || echo "$DEFAULT_UPRATE")
    
    # Advanced settings
    PRESERVE_CONFIG_FILES=$(uci -q get qosmate.advanced.PRESERVE_CONFIG_FILES || echo "0")
    WASHDSCPUP=$(uci -q get qosmate.advanced.WASHDSCPUP || echo "1")
    WASHDSCPDOWN=$(uci -q get qosmate.advanced.WASHDSCPDOWN || echo "1")
    BWMAXRATIO=$(uci -q get qosmate.advanced.BWMAXRATIO || echo "20")
    ACKRATE=$(uci -q get qosmate.advanced.ACKRATE || echo "$((UPRATE * 5 / 100))")
    UDP_RATE_LIMIT_ENABLED=$(uci -q get qosmate.advanced.UDP_RATE_LIMIT_ENABLED || echo "0")
    TCP_UPGRADE_ENABLED=$(uci -q get qosmate.advanced.TCP_UPGRADE_ENABLED || echo "1")
    UDPBULKPORT=$(uci -q get qosmate.advanced.UDPBULKPORT || echo "")
    TCPBULKPORT=$(uci -q get qosmate.advanced.TCPBULKPORT || echo "")
    VIDCONFPORTS=$(uci -q get qosmate.advanced.VIDCONFPORTS || echo "")
    REALTIME4=$(uci -q get qosmate.advanced.REALTIME4 || echo "")
    REALTIME6=$(uci -q get qosmate.advanced.REALTIME6 || echo "")
    LOWPRIOLAN4=$(uci -q get qosmate.advanced.LOWPRIOLAN4 || echo "")
    LOWPRIOLAN6=$(uci -q get qosmate.advanced.LOWPRIOLAN6 || echo "")
    MSS=$(uci -q get qosmate.advanced.MSS || echo "536")
    NFT_HOOK=$(uci -q get qosmate.advanced.NFT_HOOK || echo "forward")
    NFT_PRIORITY=$(uci -q get qosmate.advanced.NFT_PRIORITY || echo "0")

    # HFSC specific settings
    LINKTYPE=$(uci -q get qosmate.hfsc.LINKTYPE || echo "ethernet")
    OH=$(uci -q get qosmate.hfsc.OH || echo "$DEFAULT_OH")
    gameqdisc=$(uci -q get qosmate.hfsc.gameqdisc || echo "pfifo")
    GAMEUP=$(uci -q get qosmate.hfsc.GAMEUP || echo "$((UPRATE*15/100+400))")
    GAMEDOWN=$(uci -q get qosmate.hfsc.GAMEDOWN || echo "$((DOWNRATE*15/100+400))")    
    nongameqdisc=$(uci -q get qosmate.hfsc.nongameqdisc || echo "fq_codel")
    nongameqdiscoptions=$(uci -q get qosmate.hfsc.nongameqdiscoptions || echo "besteffort ack-filter")
    MAXDEL=$(uci -q get qosmate.hfsc.MAXDEL || echo "24")
    PFIFOMIN=$(uci -q get qosmate.hfsc.PFIFOMIN || echo "5")
    PACKETSIZE=$(uci -q get qosmate.hfsc.PACKETSIZE || echo "450")
    netemdelayms=$(uci -q get qosmate.hfsc.netemdelayms || echo "30")
    netemjitterms=$(uci -q get qosmate.hfsc.netemjitterms || echo "7")
    netemdist=$(uci -q get qosmate.hfsc.netemdist || echo "normal")
    pktlossp=$(uci -q get qosmate.hfsc.pktlossp || echo "none")

    # CAKE specific settings
    COMMON_LINK_PRESETS=$(uci -q get qosmate.cake.COMMON_LINK_PRESETS || echo "ethernet")
    OVERHEAD=$(uci -q get qosmate.cake.OVERHEAD || echo "")
    MPU=$(uci -q get qosmate.cake.MPU || echo "")
    LINK_COMPENSATION=$(uci -q get qosmate.cake.LINK_COMPENSATION || echo "")
    ETHER_VLAN_KEYWORD=$(uci -q get qosmate.cake.ETHER_VLAN_KEYWORD || echo "")
    PRIORITY_QUEUE_INGRESS=$(uci -q get qosmate.cake.PRIORITY_QUEUE_INGRESS || echo "diffserv4")
    PRIORITY_QUEUE_EGRESS=$(uci -q get qosmate.cake.PRIORITY_QUEUE_EGRESS || echo "diffserv4")
    HOST_ISOLATION=$(uci -q get qosmate.cake.HOST_ISOLATION || echo "1")
    NAT_INGRESS=$(uci -q get qosmate.cake.NAT_INGRESS || echo "1")
    NAT_EGRESS=$(uci -q get qosmate.cake.NAT_EGRESS || echo "0")
    ACK_FILTER_EGRESS=$(uci -q get qosmate.cake.ACK_FILTER_EGRESS || echo "auto")
    RTT=$(uci -q get qosmate.cake.RTT || echo "")
    AUTORATE_INGRESS=$(uci -q get qosmate.cake.AUTORATE_INGRESS || echo "0")
    EXTRA_PARAMETERS_INGRESS=$(uci -q get qosmate.cake.EXTRA_PARAMETERS_INGRESS || echo "")
    EXTRA_PARAMETERS_EGRESS=$(uci -q get qosmate.cake.EXTRA_PARAMETERS_EGRESS || echo "")

    # Calculated values
    FIRST500MS=$((DOWNRATE * 500 / 8))
    FIRST10S=$((DOWNRATE * 10000 / 8))
}

load_config

validate_and_adjust_rates() {
    if [ "$ROOT_QDISC" = "hfsc" ]; then
        if [ -z "$DOWNRATE" ] || [ "$DOWNRATE" -eq 0 ]; then
            echo "Warning: DOWNRATE is zero or not set for HFSC. Setting to minimum value of 1000 kbps."
            DOWNRATE=1000
            uci set qosmate.settings.DOWNRATE=1000
        fi
        if [ -z "$UPRATE" ] || [ "$UPRATE" -eq 0 ]; then
            echo "Warning: UPRATE is zero or not set for HFSC. Setting to minimum value of 1000 kbps."
            UPRATE=1000
            uci set qosmate.settings.UPRATE=1000
        fi
        uci commit qosmate
    fi
}

validate_and_adjust_rates

# Adjust DOWNRATE based on BWMAXRATIO
if [ $((DOWNRATE > UPRATE*BWMAXRATIO)) -eq 1 ]; then
    echo "We limit the downrate to at most $BWMAXRATIO times the upstream rate to ensure no upstream ACK floods occur which can cause game packet drops"
    DOWNRATE=$((BWMAXRATIO*UPRATE))
fi

##############################
# Function to preserve configuration files
##############################
preserve_config_files() {
    if [ "$PRESERVE_CONFIG_FILES" -eq 1 ]; then
        {
            echo "/etc/qosmate.sh"
            echo "/etc/init.d/qosmate"
            echo "/etc/hotplug.d/iface/13-qosmateHotplug" 
        } | while read LINE; do
            grep -qxF "$LINE" /etc/sysupgrade.conf || echo "$LINE" >> /etc/sysupgrade.conf
        done
        echo "Config files have been added to sysupgrade.conf for preservation."
    else
        echo "Preservation of config files is disabled."
             
        # Remove the config files from sysupgrade.conf if they exist
        sed -i '\|/etc/qosmate.sh|d' /etc/sysupgrade.conf
        sed -i '\|/etc/init.d/qosmate|d' /etc/sysupgrade.conf
        sed -i '\|/etc/hotplug.d/iface/13-qosmateHotplug|d' /etc/sysupgrade.conf
    fi
}

preserve_config_files

##############################
# Variable checks and dynamic rule generation
##############################

# Function to calculate different ACK rates based on the existing ACKRATE variable
calculate_ack_rates() {
    if [ -n "$ACKRATE" ] && [ "$ACKRATE" -gt 0 ]; then
        SLOWACKRATE=$ACKRATE
        MEDACKRATE=$ACKRATE
        FASTACKRATE=$(($ACKRATE * 10))
        XFSTACKRATE=$(($ACKRATE * 100))
    fi
}

# Call the function to perform the ACK rates calculations
calculate_ack_rates

# Function to check if an IP is IPv6
is_ipv6() {
    case "$1" in
        *:*) return 0 ;;
        *) return 1 ;;
    esac
}

# Create rules
create_nft_rule() {
    local config="$1"
    local src_ip src_port dest_ip dest_port proto class counter name enabled
    config_get src_ip "$config" src_ip
    config_get src_port "$config" src_port
    config_get dest_ip "$config" dest_ip
    config_get dest_port "$config" dest_port
    config_get proto "$config" proto
    config_get class "$config" class
    config_get_bool counter "$config" counter 0
    config_get name "$config" name
    config_get_bool enabled "$config" enabled 1  # Default to enabled if not set

    # Check if the rule is enabled
    [ "$enabled" = "0" ] && return 0

    # Convert class to lowercase
    class=$(echo "$class" | tr 'A-Z' 'a-z')

    # Ensure class is not empty
    if [ -z "$class" ]; then
        echo "Error: Class for rule '$config' is empty."
        return 1
    fi

    # Initialize rule string
    local rule_cmd=""

    # Function to handle multiple values
    handle_multiple_values() {
        local values="$1"
        local prefix="$2"
        local result=""
        local exclude=0
        
        if [ $(echo "$values" | grep -c "!=") -gt 0 ]; then
            exclude=1
            values=$(echo "$values" | sed 's/!=//g')
        fi
        
        if [ $(echo "$values" | wc -w) -gt 1 ]; then
            if [ $exclude -eq 1 ]; then
                result="$prefix != { $(echo $values | tr ' ' ',') }"
            else
                result="$prefix { $(echo $values | tr ' ' ',') }"
            fi
        else
            if [ $exclude -eq 1 ]; then
                result="$prefix != $values"
            else
                result="$prefix $values"
            fi
        fi
        echo "$result"
    }

    # Handle multiple protocols
    if [ -n "$proto" ]; then
        rule_cmd="$rule_cmd $(handle_multiple_values "$proto" "meta l4proto")"
    fi

    # Append source IP and port if provided
    if [ -n "$src_ip" ]; then
        local ip_cmd="ip saddr"
        if is_ipv6 "$src_ip"; then
            ip_cmd="ip6 saddr"
        fi
        rule_cmd="$rule_cmd $(handle_multiple_values "$src_ip" "$ip_cmd")"
    fi
    [ -n "$src_port" ] && rule_cmd="$rule_cmd $(handle_multiple_values "$src_port" "th sport")"

    # Append destination IP and port if provided
    if [ -n "$dest_ip" ]; then
        local ip_cmd="ip daddr"
        if is_ipv6 "$dest_ip"; then
            ip_cmd="ip6 daddr"
        fi
        rule_cmd="$rule_cmd $(handle_multiple_values "$dest_ip" "$ip_cmd")"
    fi
    [ -n "$dest_port" ] && rule_cmd="$rule_cmd $(handle_multiple_values "$dest_port" "th dport")"

    # Append class and counter if provided
    if is_ipv6 "$src_ip" || is_ipv6 "$dest_ip"; then
        rule_cmd="$rule_cmd ip6 dscp set $class"
    else
        rule_cmd="$rule_cmd ip dscp set $class"
    fi
    [ "$counter" -eq 1 ] && rule_cmd="$rule_cmd counter"

    # Add comment if name is provided
    [ -n "$name" ] && rule_cmd="$rule_cmd comment \"$name\""

    # Finalize the rule by removing any extra spaces and adding a semicolon
    rule_cmd=$(echo "$rule_cmd" | sed 's/[ ]*$//')

    # Ensure the rule is not just a semicolon
    if [ -n "$rule_cmd" ] && [ "$rule_cmd" != ";" ]; then
        echo "$rule_cmd;"
    fi
}

generate_dynamic_nft_rules() {
    . /lib/functions.sh
    config_load 'qosmate'
    
    # Check global enable setting
    local global_enabled
    config_get_bool global_enabled global enabled 1  # Default to enabled if not set
    
    if [ "$global_enabled" = "1" ]; then
        config_foreach create_nft_rule rule
    else
        echo "# QoSmate rules are globally disabled"
    fi
}

# Generate dynamic rules
DYNAMIC_RULES=$(generate_dynamic_nft_rules)

# Check if ACKRATE is greater than 0
if [ "$ACKRATE" -gt 0 ]; then
    ack_rules="\
meta length < 100 tcp flags & ack == ack add @xfst4ack {ct id limit rate over ${XFSTACKRATE}/second} counter jump drop995
        meta length < 100 tcp flags & ack == ack add @fast4ack {ct id limit rate over ${FASTACKRATE}/second} counter jump drop95
        meta length < 100 tcp flags & ack == ack add @med4ack {ct id limit rate over ${MEDACKRATE}/second} counter jump drop50
        meta length < 100 tcp flags & ack == ack add @slow4ack {ct id limit rate over ${SLOWACKRATE}/second} counter jump drop50"
else
    ack_rules="# ACK rate regulation disabled as ACKRATE=0 or not set."
fi

# Check if UDPBULKPORT is set
if [ -n "$UDPBULKPORT" ]; then
    udpbulkport_rules="\
meta l4proto udp ct original proto-src \$udpbulkport counter jump mark_cs1
        meta l4proto udp ct original proto-dst \$udpbulkport counter jump mark_cs1"
else
    udpbulkport_rules="# UDP Bulk Port rules disabled, no ports defined."
fi

# Check if TCPBULKPORT is set
if [ -n "$TCPBULKPORT" ]; then
    tcpbulkport_rules="\
meta l4proto tcp ct original proto-dst \$tcpbulkport counter jump mark_cs1"
else
    tcpbulkport_rules="# UDP Bulk Port rules disabled, no ports defined."
fi

# Check if VIDCONFPORTS is set
if [ -n "$VIDCONFPORTS" ]; then
    vidconfports_rules="\
meta l4proto udp ct original proto-dst \$vidconfports counter jump mark_af42"
else
    vidconfports_rules="# VIDCONFPORTS Port rules disabled, no ports defined."
fi

# Check if REALTIME4 and REALTIME6 are set
if [ -n "$REALTIME4" ]; then
    realtime4_rules="\
meta l4proto udp ip daddr \$realtime4 ip dscp set cs5 counter
        meta l4proto udp ip saddr \$realtime4 ip dscp set cs5 counter"
else
    realtime4_rules="# REALTIME4 rules disabled, address not defined."
fi

if [ -n "$REALTIME6" ]; then
    realtime6_rules="\
meta l4proto udp ip6 daddr \$realtime6 ip6 dscp set cs5 counter
        meta l4proto udp ip6 saddr \$realtime6 ip6 dscp set cs5 counter"
else
    realtime6_rules="# REALTIME6 rules disabled, address not defined."
fi

# Check if LOWPRIOLAN4 and LOWPRIOLAN6 are set
if [ -n "$LOWPRIOLAN4" ]; then
    lowpriolan4_rules="\
meta l4proto udp ip daddr \$lowpriolan4 ip dscp set cs0 counter
        meta l4proto udp ip saddr \$lowpriolan4 ip dscp set cs0 counter"
else
    lowpriolan4_rules="# LOWPRIOLAN4 rules disabled, address not defined."
fi

if [ -n "$LOWPRIOLAN6" ]; then
    lowpriolan6_rules="\
meta l4proto udp ip6 daddr \$lowpriolan6 ip6 dscp set cs0 counter
        meta l4proto udp ip6 saddr \$lowpriolan6 ip6 dscp set cs0 counter"
else
    lowpriolan6_rules="# LOWPRIOLAN6 rules disabled, address not defined."
fi

# Check if UDP rate limiting should be applied
if [ "$UDP_RATE_LIMIT_ENABLED" -eq 1 ]; then
    udp_rate_limit_rules="\
meta l4proto udp ip dscp > cs2 add @udp_meter {ct id limit rate over 450/second} counter ip dscp set cs0 counter
        meta l4proto udp ip6 dscp > cs2 add @udp_meter {ct id limit rate over 450/second} counter ip6 dscp set cs0 counter"
else
    udp_rate_limit_rules="# UDP rate limiting is disabled."
fi

# Check if TCP upgrade for slow connections should be applied
if [ "$TCP_UPGRADE_ENABLED" -eq 1 ]; then
    tcp_upgrade_rules="
meta l4proto tcp add @slowtcp {ct id limit rate 150/second burst 150 packets } ip dscp set af42 counter
        meta l4proto tcp add @slowtcp {ct id limit rate 150/second burst 150 packets} ip6 dscp set af42 counter"
else
    tcp_upgrade_rules="# TCP upgrade for slow connections is disabled"
fi

# Conditionally defining TCPMSS rules based on UPRATE and DOWNRATE

if [ "$UPRATE" -lt 3000 ]; then
    # Clamp MSS between 536 and 1500
    SAFE_MSS=$(( MSS > 1500 ? 1500 : (MSS < 536 ? 536 : MSS) ))
    RULE_SET_TCPMSS_UP="meta oifname \"$WAN\" tcp flags syn tcp option maxseg size set $SAFE_MSS counter;"
else
    RULE_SET_TCPMSS_UP=''
fi

if [ "$DOWNRATE" -lt 3000 ]; then
    # Clamp MSS between 536 and 1500
    SAFE_MSS=$(( MSS > 1500 ? 1500 : (MSS < 536 ? 536 : MSS) ))
    RULE_SET_TCPMSS_DOWN="meta iifname \"$WAN\" tcp flags syn tcp option maxseg size set $SAFE_MSS counter;"
else
    RULE_SET_TCPMSS_DOWN=''
fi

##############################
#       dscptag.nft
##############################

## Check if the folder does not exist
if [ ! -d "/usr/share/nftables.d/ruleset-post" ]; then
    mkdir -p "/usr/share/nftables.d/ruleset-post"
fi

cat << DSCPEOF > /usr/share/nftables.d/ruleset-post/dscptag.nft

define udpbulkport = {$UDPBULKPORT}
define tcpbulkport = {$TCPBULKPORT}
define vidconfports = {$VIDCONFPORTS}
define realtime4 = {$REALTIME4}
define realtime6 = {$REALTIME6}
define lowpriolan4 = {$LOWPRIOLAN4}
define lowpriolan6 = {$LOWPRIOLAN6}

define downrate = $DOWNRATE
define uprate = $UPRATE

define first500ms = $FIRST500MS
define first10s = $FIRST10S

define wan = "$WAN"


table inet dscptag # forward declaration so the next command always works

delete table inet dscptag # clear all the rules

table inet dscptag {

    map priomap { type dscp : classid ;
        elements =  {ef : 1:11, cs5 : 1:11, cs6 : 1:11, cs7 : 1:11,
                    cs4 : 1:12, af41 : 1:12, af42 : 1:12,
                    cs2 : 1:14 , cs1 : 1:15, cs0 : 1:13}
    }


    set xfst4ack { typeof ct id
        flags dynamic;
        timeout 5m
    }
    set fast4ack { typeof ct id
        flags dynamic;
        timeout 5m
    }
    set med4ack { typeof ct id
        flags dynamic;
        timeout 5m
    }
    set slow4ack { typeof ct id
        flags dynamic;
        timeout 5m
    }
    set udp_meter {typeof ct id
        flags dynamic;
        timeout 5m
    }
    set slowtcp {typeof ct id
        flags dynamic;
        timeout 5m
    }

    chain drop995 {
	numgen random mod 1000 ge 995 return
	drop
    }
    chain drop95 {
	numgen random mod 1000 ge 950 return
	drop
    }
    chain drop50 {
	numgen random mod 1000 ge 500 return
	drop
    }

    chain mark_500ms {
        ip dscp < cs4 ip dscp set cs0 counter return
        ip6 dscp < cs4 ip6 dscp set cs0 counter
    }
    chain mark_10s {
        ip dscp < cs4 ip dscp set cs1 counter return
        ip6 dscp < cs4 ip6 dscp set cs1 counter
    }
    
    chain mark_cs1 {
        ip dscp set cs1 return
        ip6 dscp set cs1
    }
    chain mark_af42 {
        ip dscp set af42 return
        ip6 dscp set af42
    }

    chain dscptag {
        type filter hook $NFT_HOOK priority $NFT_PRIORITY; policy accept;

        
        $(if [ "$ROOT_QDISC" = "hfsc" ] && [ "$WASHDSCPDOWN" -eq 1 ]; then
            echo "# wash all the DSCP on ingress ... "
            echo "        ip dscp set cs0 counter"
            echo "        ip6 dscp set cs0 counter"
          fi
        )

        $RULE_SET_TCPMSS_UP
        $RULE_SET_TCPMSS_DOWN

        $udpbulkport_rules

        $tcpbulkport_rules

        $ack_rules

        $vidconfports_rules

        $realtime4_rules

        $realtime6_rules

        $lowpriolan4_rules

        $lowpriolan6_rules

        $udp_rate_limit_rules
        
        # down prioritize the first 500ms of tcp packets
        meta l4proto tcp ct bytes < \$first500ms jump mark_500ms

        # downgrade tcp that has transferred more than 10 seconds worth of packets
        meta l4proto tcp ct bytes > \$first10s jump mark_10s

        $tcp_upgrade_rules
        
${DYNAMIC_RULES}

        ## classify for the HFSC queues:
        meta priority set ip dscp map @priomap counter
        meta priority set ip6 dscp map @priomap counter

        # Store DSCP in conntrack for restoration on ingress
        ct mark set ip dscp or 128 counter
        ct mark set ip6 dscp or 128 counter

        $(if [ "$ROOT_QDISC" = "hfsc" ] && [ "$WASHDSCPUP" -eq 1 ]; then
            echo "# wash all DSCP on egress ... "
            echo "meta oifname \$wan ip dscp set cs0"
            echo "        meta oifname \$wan ip6 dscp set cs0"
          fi
        )
    }
}
DSCPEOF

## Set up ctinfo downstream shaping

# Set up ingress handle for WAN interface
tc qdisc add dev $WAN handle ffff: ingress

# Create IFB interface
ip link add name ifb-$WAN type ifb
ip link set ifb-$WAN up

# Redirect ingress traffic from WAN to IFB and restore DSCP from conntrack
tc filter add dev $WAN parent ffff: protocol all matchall action ctinfo dscp 63 128 mirred egress redirect dev ifb-$WAN
LAN=ifb-$WAN

cat <<EOF

This script prioritizes the UDP packets from / to a set of gaming
machines into a real-time HFSC queue with guaranteed total bandwidth 

Based on your settings:

Game upload guarantee = $GAMEUP kbps
Game download guarantee = $GAMEDOWN kbps

Download direction only works if you install this on a *wired* router
and there is a separate AP wired into your network, because otherwise
there are multiple parallel queues for traffic to leave your router
heading to the LAN.

Based on your link total bandwidth, the **minimum** amount of jitter
you should expect in your network is about:

UP = $(((1500*8)*3/UPRATE)) ms

DOWN = $(((1500*8)*3/DOWNRATE)) ms

In order to get lower minimum jitter you must upgrade the speed of
your link, no queuing system can help.

Please note for your display rate that:

at 30Hz, one on screen frame lasts:   33.3 ms
at 60Hz, one on screen frame lasts:   16.6 ms
at 144Hz, one on screen frame lasts:   6.9 ms

This means the typical gamer is sensitive to as little as on the order
of 5ms of jitter. To get 5ms minimum jitter you should have bandwidth
in each direction of at least:

$((1500*8*3/5)) kbps

The queue system can ONLY control bandwidth and jitter in the link
between your router and the VERY FIRST device in the ISP
network. Typically you will have 5 to 10 devices between your router
and your gaming server, any of those can have variable delay and ruin
your gaming, and there is NOTHING that your router can do about it.

EOF


if [ "$ROOT_QDISC" = "hfsc" ]; then
setqdisc () {
DEV=$1
RATE=$2
MTU=1500
highrate=$((RATE*90/100))
lowrate=$((RATE*10/100))
gamerate=$3
useqdisc=$4
DIR=$5


tc qdisc del dev "$DEV" root > /dev/null 2>&1

case $LINKTYPE in
    "atm")
	tc qdisc replace dev "$DEV" handle 1: root stab mtu 2047 tsize 512 mpu 68 overhead ${OH} linklayer atm hfsc default 13
	;;
    "DOCSIS")
	tc qdisc replace dev $DEV stab overhead 25 linklayer ethernet handle 1: root hfsc default 13
	;;
    *)
	tc qdisc replace dev $DEV stab overhead 40 linklayer ethernet handle 1: root hfsc default 13
	;;
esac
     

DUR=$((5*1500*8/RATE))
if [ $DUR -lt 25 ]; then
    DUR=25
fi

# if we're on the LAN side, create a queue just for traffic from the
# router, like LUCI and DNS lookups
if [ $DIR = "lan" ]; then
    tc class add dev "$DEV" parent 1: classid 1:2 hfsc ls m1 50000kbit d "${DUR}ms" m2 10000kbit
fi


#limit the link overall:
tc class add dev "$DEV" parent 1: classid 1:1 hfsc ls m2 "${RATE}kbit" ul m2 "${RATE}kbit"




gameburst=$((gamerate*10))
if [ $gameburst -gt $((RATE*97/100)) ] ; then
    gameburst=$((RATE*97/100));
fi


# high prio realtime class
tc class add dev "$DEV" parent 1:1 classid 1:11 hfsc rt m1 "${gameburst}kbit" d "${DUR}ms" m2 "${gamerate}kbit"

# fast non-realtime
tc class add dev "$DEV" parent 1:1 classid 1:12 hfsc ls m1 "$((RATE*70/100))kbit" d "${DUR}ms" m2 "$((RATE*30/100))kbit"

# normal
tc class add dev "$DEV" parent 1:1 classid 1:13 hfsc ls m1 "$((RATE*20/100))kbit" d "${DUR}ms" m2 "$((RATE*45/100))kbit"

# low prio
tc class add dev "$DEV" parent 1:1 classid 1:14 hfsc ls m1 "$((RATE*7/100))kbit" d "${DUR}ms" m2 "$((RATE*15/100))kbit"

# bulk
tc class add dev "$DEV" parent 1:1 classid 1:15 hfsc ls m1 "$((RATE*3/100))kbit" d "${DUR}ms" m2 "$((RATE*10/100))kbit"



## set this to "drr" or "qfq" to differentiate between different game
## packets, or use "pfifo" to treat all game packets equally

## games often use a 1/64 s = 15.6ms tick rate +- if we're getting so
## many packets that it takes that long to drain at full RATE, we're
## in trouble, because then everything lags by a full tick... so we
## set our RED minimum to start dropping at 9ms of packets at full
## line rate, and then drop 100% by 3x that much, it's better to drop
## packets for a little while than play a whole game lagged by a full
## tick

REDMIN=$((RATE*MAXDEL/3/8)) 

REDMAX=$((RATE * MAXDEL/8)) 

# for fq_codel
INTVL=$((100+2*1500*8/RATE))
TARG=$((540*8/RATE+4))



case $useqdisc in
    "drr")
	tc qdisc add dev "$DEV" parent 1:11 handle 2:0 drr
	tc class add dev "$DEV" parent 2:0 classid 2:1 drr quantum 8000
	tc qdisc add dev "$DEV" parent 2:1 handle 10: red limit 150000 min $REDMIN max $REDMAX avpkt 500 bandwidth ${RATE}kbit probability 1.0
	tc class add dev "$DEV" parent 2:0 classid 2:2 drr quantum 4000
	tc qdisc add dev "$DEV" parent 2:2 handle 20: red limit 150000 min $REDMIN max $REDMAX avpkt 500 bandwidth ${RATE}kbit probability 1.0
	tc class add dev "$DEV" parent 2:0 classid 2:3 drr quantum 1000
	tc qdisc add dev "$DEV" parent 2:3 handle 30: red limit 150000  min $REDMIN max $REDMAX avpkt 500 bandwidth ${RATE}kbit probability 1.0
	## with this send high priority game packets to 10:, medium to 20:, normal to 30:
	## games will not starve but be given relative importance based on the quantum parameter
    ;;

    "qfq")
	tc qdisc add dev "$DEV" parent 1:11 handle 2:0 qfq
	tc class add dev "$DEV" parent 2:0 classid 2:1 qfq weight 8000
	tc qdisc add dev "$DEV" parent 2:1 handle 10: red limit 150000  min $REDMIN max $REDMAX avpkt 500 bandwidth ${RATE}kbit probability 1.0
	tc class add dev "$DEV" parent 2:0 classid 2:2 qfq weight 4000
	tc qdisc add dev "$DEV" parent 2:2 handle 20: red limit 150000 min $REDMIN max $REDMAX avpkt 500 bandwidth ${RATE}kbit probability 1.0
	tc class add dev "$DEV" parent 2:0 classid 2:3 qfq weight 1000
	tc qdisc add dev "$DEV" parent 2:3 handle 30: red limit 150000  min $REDMIN max $REDMAX avpkt 500 bandwidth ${RATE}kbit probability 1.0
	## with this send high priority game packets to 10:, medium to 20:, normal to 30:
	## games will not starve but be given relative importance based on the weight parameter

    ;;

    "pfifo")
    tc qdisc add dev "$DEV" parent 1:11 handle 10: pfifo limit $((PFIFOMIN+MAXDEL*RATE/8/PACKETSIZE))
	;;
    "bfifo")
	tc qdisc add dev "$DEV" parent 1:11 handle 10: bfifo limit $((MAXDEL * gamerate / 8))
 	#tc qdisc add dev "$DEV" parent 1:11 handle 10: bfifo limit $((MAXDEL * RATE / 8))   
	;;    
    "red")
	tc qdisc add dev "$DEV" parent 1:11 handle 10: red limit 150000 min $REDMIN max $REDMAX avpkt 500 bandwidth ${RATE}kbit  probability 1.0
	## send game packets to 10:, they're all treated the same
	;;
    "fq_codel")
	tc qdisc add dev "$DEV" parent "1:11" fq_codel memory_limit $((RATE*200/8)) interval "${INTVL}ms" target "${TARG}ms" quantum $((MTU * 2))
	;;
    "netem")
	tc qdisc add dev "$DEV" parent 1:11 handle 10: netem limit $((4+9*RATE/8/500)) delay "${netemdelayms}ms" "${netemjitterms}ms" distribution "$netemdist"
	;;


esac

if [ "$DIR" = "lan" ]; then
    # Apply the filters on the IFB interface's egress
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0xb8 0xfc classid 1:11 # ef (46)
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0xa0 0xfc classid 1:11 # cs5 (40)
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0xc0 0xfc classid 1:11 # cs6 (48)
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0xe0 0xfc classid 1:11 # cs7 (56)
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0x80 0xfc classid 1:12 # cs4 (32)
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0x88 0xfc classid 1:12 # af41 (34)
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0x90 0xfc classid 1:12 # af42 (36)
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0x40 0xfc classid 1:14 # cs2 (16)
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0x20 0xfc classid 1:15 # cs1 (8)
    tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dsfield 0x00 0xfc classid 1:13 # none (0)
fi

echo "adding $nongameqdisc qdisc for non-game traffic"
for i in 12 13 14 15; do 
    if [ "$nongameqdisc" = "cake" ]; then
        tc qdisc add dev "$DEV" parent "1:$i" cake $nongameqdiscoptions
    elif [ "$nongameqdisc" = "fq_codel" ]; then
        tc qdisc add dev "$DEV" parent "1:$i" fq_codel memory_limit $((RATE*200/8)) interval "${INTVL}ms" target "${TARG}ms" quantum $((MTU * 2))
    else
        echo "Unsupported qdisc for non-game traffic: $nongameqdisc"
        exit 1
    fi
done

}
fi

setup_cake() {
    tc qdisc del dev "$WAN" root > /dev/null 2>&1
    tc qdisc del dev "$LAN" root > /dev/null 2>&1
    
    # Egress (Upload) CAKE setup
    EGRESS_CAKE_OPTS="bandwidth ${UPRATE}kbit"
    [ -n "$PRIORITY_QUEUE_EGRESS" ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS $PRIORITY_QUEUE_EGRESS"
    [ "$HOST_ISOLATION" -eq 1 ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS dual-srchost"
    [ "$NAT_EGRESS" -eq 1 ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS nat" || EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS nonat"
    
    [ "$WASHDSCPUP" -eq 1 ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS wash" || EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS nowash"
    
    if [ "$ACK_FILTER_EGRESS" = "auto" ]; then
        if [ $((DOWNRATE / UPRATE)) -ge 15 ]; then
            EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS ack-filter"
        else
            EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS no-ack-filter"
        fi
    elif [ "$ACK_FILTER_EGRESS" -eq 1 ]; then
        EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS ack-filter"
    else
        EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS no-ack-filter"
    fi
    
    [ -n "$RTT" ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS rtt ${RTT}ms"
    [ -n "$COMMON_LINK_PRESETS" ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS $COMMON_LINK_PRESETS"
    [ -n "$LINK_COMPENSATION" ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS $LINK_COMPENSATION" || EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS noatm"
    [ -n "$OVERHEAD" ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS overhead $OVERHEAD"
    [ -n "$MPU" ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS mpu $MPU"
    [ -n "$EXTRA_PARAMETERS_EGRESS" ] && EGRESS_CAKE_OPTS="$EGRESS_CAKE_OPTS $EXTRA_PARAMETERS_EGRESS"
    
    tc qdisc add dev $WAN root cake $EGRESS_CAKE_OPTS
    
    # Ingress (Download) CAKE setup
    INGRESS_CAKE_OPTS="bandwidth ${DOWNRATE}kbit ingress"
    [ "$AUTORATE_INGRESS" -eq 1 ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS autorate-ingress"
    [ -n "$PRIORITY_QUEUE_INGRESS" ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS $PRIORITY_QUEUE_INGRESS"
    [ "$HOST_ISOLATION" -eq 1 ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS dual-dsthost"
    [ "$NAT_INGRESS" -eq 1 ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS nat" || INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS nonat"
    
    [ "$WASHDSCPDOWN" -eq 1 ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS wash" || INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS nowash"
    
    [ -n "$RTT" ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS rtt ${RTT}ms"
    [ -n "$COMMON_LINK_PRESETS" ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS $COMMON_LINK_PRESETS"
    [ -n "$LINK_COMPENSATION" ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS $LINK_COMPENSATION" || INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS noatm"
    [ -n "$OVERHEAD" ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS overhead $OVERHEAD"
    [ -n "$MPU" ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS mpu $MPU"
    [ -n "$EXTRA_PARAMETERS_INGRESS" ] && INGRESS_CAKE_OPTS="$INGRESS_CAKE_OPTS $EXTRA_PARAMETERS_INGRESS"
    
    tc qdisc add dev $LAN root cake $INGRESS_CAKE_OPTS
}

# Main logic for selecting and applying the QoS system
if [ "$ROOT_QDISC" = "hfsc" ]; then
    if [ "$gameqdisc" != "fq_codel" ] && [ "$gameqdisc" != "red" ] && [ "$gameqdisc" != "pfifo" ] && [ "$gameqdisc" != "bfifo" ] && [ "$gameqdisc" != "netem" ]; then
        echo "Warning: $gameqdisc is not tested and may not work on OpenWrt. Reverting to red."
        gameqdisc="red"
    fi
    setqdisc $WAN $UPRATE $GAMEUP $gameqdisc wan
    setqdisc $LAN $DOWNRATE $GAMEDOWN $gameqdisc lan
elif [ "$ROOT_QDISC" = "cake" ]; then
    setup_cake
else
    echo "Unsupported ROOT_QDISC: $ROOT_QDISC. Using HFSC as default."
    ROOT_QDISC="hfsc"
    setqdisc $WAN $UPRATE $GAMEUP $gameqdisc wan
    setqdisc $LAN $DOWNRATE $GAMEDOWN $gameqdisc lan
fi

echo "DONE!"

if [ "$ROOT_QDISC" = "hfsc" ] && [ "$gameqdisc" = "red" ]; then
   echo "Can not output tc -s qdisc because it crashes on OpenWrt when using RED qdisc, but things are working!"
else
   tc -s qdisc
fi

