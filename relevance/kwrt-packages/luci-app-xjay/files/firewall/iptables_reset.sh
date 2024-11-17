#!/bin/sh

# remove links to created chains
iptables -t mangle -D PREROUTING -j XJAY
iptables -t mangle -D OUTPUT -j XJAY_MASK
ip6tables -t mangle -D PREROUTING -j XJAY6
ip6tables -t mangle -D OUTPUT -j XJAY6_MASK

# flush rules in the chains
iptables -t mangle -F XJAY
iptables -t mangle -F XJAY_MASK
ip6tables -t mangle -F XJAY6
ip6tables -t mangle -F XJAY6_MASK

# delete chains
iptables -t mangle -X XJAY
iptables -t mangle -X XJAY_MASK
ip6tables -t mangle -X XJAY6
ip6tables -t mangle -X XJAY6_MASK
