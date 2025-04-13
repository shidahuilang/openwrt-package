#!/bin/sh

. "$IPKG_INSTROOT/etc/nikki/scripts/include.sh"

# since v1.18.0

mixin_rule=$(uci -q get nikki.mixin.rule); [ -z "$mixin_rule" ] && uci set nikki.mixin.rule=0

mixin_rule_provider=$(uci -q get nikki.mixin.rule_provider); [ -z "$mixin_rule_provider" ] && uci set nikki.mixin.rule_provider=0

# since v1.19.0

mixin_ui_path=$(uci -q get nikki.mixin.ui_path); [ -z "$mixin_ui_path" ] && uci set nikki.mixin.ui_path=ui

uci show nikki | grep -E 'nikki.@rule\[[[:digit:]]+\].match=' | sed 's/nikki.@rule\[\([[:digit:]]\+\)\].match=.*/rename nikki.@rule[\1].match=matcher/' | uci batch

# since v1.19.1

proxy_fake_ip_ping_hijack=$(uci -q get nikki.proxy.fake_ip_ping_hijack); [ -z "$proxy_fake_ip_ping_hijack" ] && uci set nikki.proxy.fake_ip_ping_hijack=0

# since v1.20.0

mixin_api_port=$(uci -q get nikki.mixin.api_port); [ -n "$mixin_api_port" ] && {
	uci del nikki.mixin.api_port
	uci set nikki.mixin.api_listen=[::]:$mixin_api_port
}

mixin_dns_port=$(uci -q get nikki.mixin.dns_port); [ -n "$mixin_dns_port" ] && {
	uci del nikki.mixin.dns_port
	uci set nikki.mixin.dns_listen=[::]:$mixin_dns_port
}

# since v1.22.0

proxy_transparent_proxy=$(uci -q get nikki.proxy.transparent_proxy); [ -n "$proxy_transparent_proxy" ] && {
	uci rename nikki.proxy.transparent_proxy=enabled
	uci rename nikki.proxy.tcp_transparent_proxy_mode=tcp_mode
	uci rename nikki.proxy.udp_transparent_proxy_mode=udp_mode

	uci add nikki router_access_control
	uci set nikki.@router_access_control[-1].enabled=1
	proxy_bypass_user=$(uci -q get nikki.proxy.bypass_user); [ -n "$proxy_bypass_user" ] && {
		for user in $proxy_bypass_user; do
			uci add_list nikki.@router_access_control[-1].user="$user"
		done
	}
	proxy_bypass_group=$(uci -q get nikki.proxy.bypass_group); [ -n "$proxy_bypass_group" ] && {
		for group in $proxy_bypass_group; do
			uci add_list nikki.@router_access_control[-1].group="$group"
		done
	}
	proxy_bypass_cgroup=$(uci -q get nikki.proxy.bypass_cgroup); [ -n "$proxy_bypass_cgroup" ] && {
		for cgroup in $proxy_bypass_cgroup; do
			uci add_list nikki.@router_access_control[-1].cgroup="$cgroup"
		done
	}
	uci set nikki.@router_access_control[-1].proxy=0

	uci add nikki router_access_control
	uci set nikki.@router_access_control[-1].enabled=1
	uci set nikki.@router_access_control[-1].proxy=1

	uci add_list nikki.proxy.lan_inbound_interface=lan

	proxy_access_control_mode=$(uci -q get nikki.proxy.access_control_mode)

	[ "$proxy_access_control_mode" != "all" ] && {
		proxy_acl_ip=$(uci -q get nikki.proxy.acl_ip); [ -n "$proxy_acl_ip" ] && {
			for ip in $proxy_acl_ip; do
				uci add nikki lan_access_control
				uci set nikki.@lan_access_control[-1].enabled=1
				uci add_list nikki.@lan_access_control[-1].ip="$ip"
				[ "$proxy_access_control_mode" == "allow" ] && uci set nikki.@lan_access_control[-1].proxy=1
				[ "$proxy_access_control_mode" == "block" ] && uci set nikki.@lan_access_control[-1].proxy=0
			done
		}
		proxy_acl_ip6=$(uci -q get nikki.proxy.acl_ip6); [ -n "$proxy_acl_ip6" ] && {
			for ip6 in $proxy_acl_ip6; do
				uci add nikki lan_access_control
				uci set nikki.@lan_access_control[-1].enabled=1
				uci add_list nikki.@lan_access_control[-1].ip6="$ip6"
				[ "$proxy_access_control_mode" == "allow" ] && uci set nikki.@lan_access_control[-1].proxy=1
				[ "$proxy_access_control_mode" == "block" ] && uci set nikki.@lan_access_control[-1].proxy=0
			done
		}
		proxy_acl_mac=$(uci -q get nikki.proxy.acl_mac); [ -n "$proxy_acl_mac" ] && {
			for mac in $proxy_acl_mac; do
				uci add nikki lan_access_control
				uci set nikki.@lan_access_control[-1].enabled=1
				uci add_list nikki.@lan_access_control[-1].mac="$mac"
				[ "$proxy_access_control_mode" == "allow" ] && uci set nikki.@lan_access_control[-1].proxy=1
				[ "$proxy_access_control_mode" == "block" ] && uci set nikki.@lan_access_control[-1].proxy=0
			done
		}
	}

	[ "$proxy_access_control_mode" != "allow" ] && {
		uci add nikki lan_access_control
		uci set nikki.@lan_access_control[-1].enabled=1
		uci set nikki.@lan_access_control[-1].proxy=1
	}

	uci del nikki.proxy.access_control_mode
	uci del nikki.proxy.acl_ip
	uci del nikki.proxy.acl_ip6
	uci del nikki.proxy.acl_mac
	uci del nikki.proxy.acl_interface
	uci del nikki.proxy.bypass_user
	uci del nikki.proxy.bypass_group
	uci del nikki.proxy.bypass_cgroup
}

# commit
uci commit nikki

# exit with 0
exit 0
