#!/bin/sh

. "$IPKG_INSTROOT/lib/functions.sh"
. "$IPKG_INSTROOT/etc/mihomo/scripts/constants.sh"

config_load mihomo
config_get enabled "config" "enabled" 0
config_get tcp_transparent_proxy_mode "proxy" "tcp_transparent_proxy_mode"
config_get udp_transparent_proxy_mode "proxy" "udp_transparent_proxy_mode"

if [ "$enabled" == 1 ] && [[ "$tcp_transparent_proxy_mode" == "tun" || "$udp_transparent_proxy_mode" == "tun" ]]; then
	nft insert rule inet fw4 input iifname "$TUN_DEVICE" counter accept comment "mihomo"
	nft insert rule inet fw4 forward oifname "$TUN_DEVICE" counter accept comment "mihomo"
	nft insert rule inet fw4 forward iifname "$TUN_DEVICE" counter accept comment "mihomo"
fi

exit 0
