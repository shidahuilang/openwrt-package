-- Copyright 2019 X-WRT <dev@x-wrt.com>
-- Copyright 2022 sirpdboy

local net = require "luci.model.network".init()
local sys = require "luci.sys"
local ifaces = sys.net:devices()
local nt = require "luci.sys".net
local uci = require("luci.model.uci").cursor()
local lan_gateway = uci:get("netwizard", "default", "lan_gateway")
if lan_gateway ~= "" then
   lan_gateway = sys.exec("ipaddr=`uci -q get network.lan.ipaddr`;echo ${ipaddr%.*}")
end
local lan_ip = uci:get("network", "lan", "ipaddr")
local wan_face = sys.exec(" [ `uci -q get network.wan.ifname` ] && uci -q get network.wan.ifname  || uci -q get network.wan.device ")
local wanproto = uci:get("netwizard", "default", "wan_proto")
if wanproto == "" then
     wanproto = sys.exec("uci -q get network.wan.proto || echo 'siderouter'")
end
local validation = require "luci.cbi.datatypes"
local has_wifi = false
uci:foreach("wireless", "wifi-device",
		function(s)
			has_wifi = true
			return false
		end)

local m = Map("netwizard", luci.util.pcdata(translate("Network Router Setup")), translate("Quick network setup wizard. If you need more settings, please enter network - interface to set.</br>")..translate("The network card is automatically set, and the physical interfaces other than the specified WAN interface are automatically bound as LAN ports, and all side routes are bound as LAN ports.</br>")..translate("For specific usage, see:")..translate("<a href=\'https://github.com/sirpdboy/luci-app-netwizard.git' target=\'_blank\'>GitHub @sirpdboy/netwizard</a>") )

local s = m:section(TypedSection, "netwizard", "")
s.addremove = false
s.anonymous = true

s:tab("wansetup", translate("Wan Settings"))
if has_wifi then
	s:tab("wifisetup", translate("Wireless Settings"), translate("Set the router's wireless name and password. For more advanced settings, please go to the Network-Wireless page."))
end
s:tab("othersetup", translate("Other setting"))

local e = s:taboption("wansetup", Value, "lan_ipaddr", translate("Lan IPv4 address") ,translate("You must specify the IP address of this machine, which is the IP address of the web access route"))
e.default = lan_ip
e.datatype = "ip4addr"

e = s:taboption("wansetup", Value, "lan_netmask", translate("Lan IPv4 netmask"))
e.datatype = "ip4addr"
e:value("255.255.255.0")
e:value("255.255.0.0")
e:value("255.0.0.0")
e.default = '255.255.255.0'

e = s:taboption("wansetup", Flag, "ipv6",translate('Enable IPv6'))
e.default = "0"

wan_proto = s:taboption("wansetup", ListValue, "wan_proto", translate("Network protocol mode selection"), translate("Four different ways to access the Internet, please choose according to your own situation.</br>"))
wan_proto.default = wanproto
wan_proto:value("dhcp", translate("DHCP client"))
wan_proto:value("static", translate("Static address"))
wan_proto:value("pppoe", translate("PPPoE dialing"))
wan_proto:value("siderouter", translate("SideRouter"))

wan_interface = s:taboption("wansetup",Value, "wan_interface",translate("interface<font color=\"red\">(*)</font>"), translate("Allocate the physical interface of WAN port"))
wan_interface:depends({wan_proto="pppoe"})
wan_interface:depends({wan_proto="dhcp"})
wan_interface:depends({wan_proto="static"})

for _, iface in ipairs(ifaces) do
   if not (iface:match("_ifb$") or iface:match("^ifb*")) then
	if ( iface:match("^eth*") or iface:match("^wlan*") or iface:match("^usb*")) then
		local nets = net:get_interface(iface)
		nets = nets and nets:get_networks() or {}
		for k, v in pairs(nets) do
			nets[k] = nets[k].sid
		end
		nets = table.concat(nets, ",")
		wan_interface:value(iface, ((#nets > 0) and "%s (%s)" % {iface, nets} or iface))
	end
  end
end
-- wan_interface.default = wan_face

wan_pppoe_user = s:taboption("wansetup", Value, "wan_pppoe_user", translate("PAP/CHAP username"))
wan_pppoe_user:depends({wan_proto="pppoe"})

wan_pppoe_pass = s:taboption("wansetup", Value, "wan_pppoe_pass", translate("PAP/CHAP password"))
wan_pppoe_pass:depends({wan_proto="pppoe"})
wan_pppoe_pass.password = true

wan_ipaddr = s:taboption("wansetup", Value, "wan_ipaddr", translate("Wan IPv4 address"))
wan_ipaddr:depends({wan_proto="static"})
wan_ipaddr.datatype = "ip4addr"

wan_netmask = s:taboption("wansetup", Value, "wan_netmask", translate("Wan IPv4 netmask"))
wan_netmask:depends({wan_proto="static"})
wan_netmask.datatype = "ip4addr"
wan_netmask:value("255.255.255.0")
wan_netmask:value("255.255.0.0")
wan_netmask:value("255.0.0.0")
wan_netmask.default = "255.255.255.0"

wan_gateway = s:taboption("wansetup", Value, "wan_gateway", translate("Wan IPv4 gateway"))
wan_gateway:depends({wan_proto="static"})
wan_gateway.datatype = "ip4addr"

wan_dns = s:taboption("wansetup", DynamicList, "wan_dns", translate("Use custom Wan DNS"))
wan_dns:value("223.5.5.5", translate("Ali DNS:223.5.5.5"))
wan_dns:value("180.76.76.76", translate("Baidu dns:180.76.76.76"))
wan_dns:value("114.114.114.114", translate("114 DNS:114.114.114.114"))
wan_dns:value("8.8.8.8", translate("Google DNS:8.8.8.8"))
wan_dns:value("1.1.1.1", translate("Cloudflare DNS:1.1.1.1"))
wan_dns.default = "223.5.5.5"
wan_dns:depends({wan_proto="static"})
wan_dns:depends({wan_proto="pppoe"})
wan_dns.datatype = "ip4addr"

e = s:taboption("wansetup", Value, "lan_gateway", translate("Lan IPv4 gateway"), translate( "Please enter the main routing IP address. The bypass gateway is not the same as the login IP of this bypass WEB and is in the same network segment"))
e.default = lan_gateway
e:depends({wan_proto = "siderouter"})
e.datatype = "ip4addr"

lan_dns = s:taboption("wansetup", DynamicList, "lan_dns", translate("Use custom Siderouter DNS"))
lan_dns:value("223.5.5.5", translate("Ali DNS:223.5.5.5"))
lan_dns:value("180.76.76.76", translate("Baidu dns:180.76.76.76"))
lan_dns:value("114.114.114.114", translate("114 DNS:114.114.114.114"))
lan_dns:value("8.8.8.8", translate("Google DNS:8.8.8.8"))
lan_dns:value("1.1.1.1", translate("Cloudflare DNS:1.1.1.1"))
lan_dns:depends({wan_proto="siderouter"})
lan_dns.datatype = "ip4addr"
lan_dns.default = "223.5.5.5"

lan_dhcp = s:taboption("wansetup", Flag, "lan_dhcp", translate("Disable DHCP Server"), translate("Selecting means that the DHCP server is not enabled. In a network, only one DHCP server is needed to allocate and manage client IPs. If it is a secondary route, it is recommended to turn off the primary routing DHCP server."))
lan_dhcp.default = 0
lan_dhcp.anonymous = false

e = s:taboption("wansetup", Flag, "dnsset", translate("Enable DNS notifications (ipv4/ipv6)"),translate("Force the DNS server in the DHCP server to be specified as the IP for this route"))
e:depends("lan_dhcp", false)
e.default = "0"

e = s:taboption("wansetup", Value, "dns_tables", translate(" "))
e:value("1", translate("Use local IP for DNS (default)"))
e:value("223.5.5.5", translate("Ali DNS:223.5.5.5"))
e:value("180.76.76.76", translate("Baidu dns:180.76.76.76"))
e:value("114.114.114.114", translate("114 DNS:114.114.114.114"))
e:value("8.8.8.8", translate("Google DNS:8.8.8.8"))
e:value("1.1.1.1", translate("Cloudflare DNS:1.1.1.1"))
e.anonymous = false
e:depends("dnsset", true)

lan_snat = s:taboption("wansetup", Flag, "lan_snat", translate("Custom firewall"),translate("Bypass firewall settings, when Xiaomi or Huawei are used as the main router, the WIFI signal cannot be used normally"))
lan_snat:depends({wan_proto="siderouter"})
lan_snat.anonymous = false

e = s:taboption("wansetup", Value, "snat_tables", translate(" "))
e:value("iptables -t nat -I POSTROUTING -o br-lan -j MASQUERADE")
e:value("iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE")
e:value("iptables -t nat -I POSTROUTING -o eth1 -j MASQUERADE")
e.default = "iptables -t nat -I POSTROUTING -o br-lan -j MASQUERADE"
e.anonymous = false
e:depends("lan_snat", true)

redirectdns = s:taboption("wansetup", Flag, "redirectdns", translate("Custom firewall"),translate("Use iptables to force all TCP/UDP DNS 53ports in IPV4/IPV6 to be forwarded from this route[Suggest opening]"))
redirectdns:depends({wan_proto="dhcp"})
redirectdns:depends({wan_proto="static"})
redirectdns:depends({wan_proto="pppoe"})
redirectdns.anonymous = false

masq = s:taboption("wansetup", Flag, "masq", translate("Enable IP dynamic camouflage"),translate("Enable IP dynamic camouflage when the side routing network is not ideal"))
masq:depends({wan_proto="siderouter"})
masq.anonymous = false

if has_wifi then
	e = s:taboption("wifisetup", Value, "wifi_ssid", translate("<abbr title=\"Extended Service Set Identifier\">ESSID</abbr>"))
	e.datatype = "maxlength(32)"
	e = s:taboption("wifisetup", Value, "wifi_key", translate("Key"))
	e.datatype = "wpakey"
	e.password = true
end

synflood = s:taboption("othersetup", Flag, "synflood", translate("Enable SYN-flood defense"),translate("Enable Firewall SYN-flood defense [Suggest opening]"))
synflood.default = 1
synflood.anonymous = false

e = s:taboption("othersetup", Flag, "showhide",translate('Hide Wizard'), translate('Show or hide the setup wizard menu. After hiding, you can open the display wizard menu in [Advanced Settings] [Advanced] or use the 3rd function in the background to restore the wizard and default theme.'))

m.apply_on_parse = true
m.on_after_apply = function(self,map)
	luci.sys.exec("/etc/init.d/netwizard start >/dev/null 2>&1")
end

return m
