require "luci.sys"
require "luci.http"
local uci = require"luci.model.uci".cursor()
local m, s, sec, o
local uci = luci.model.uci.cursor()


font_green = [[<b style=color:green>]]
font_red = [[<b style=color:red>]]
font_off = [[</b>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]

local server_table = {}

uci:foreach("xclient", "servers", function(s)
	if s.alias then
		server_table[s[".name"]] = "[%s]:%s" % {string.upper(s.protocol or s.type), s.alias}
	elseif s.server and s.server_port then
		server_table[s[".name"]] = "[%s]:%s:%s" % {string.upper(s.protocol or s.type), s.server, s.server_port}
	end
end)

local key_table = {}
for key,_ in pairs(server_table) do
    table.insert(key_table,key)
end

table.sort(key_table)


m = Map("xclient")
m.pageaction = true
m:append(Template("xclient/status"))


s = m:section(TypedSection, "global")
s.anonymous = true
s.addremove = false


s:tab("main", "Client")
s:tab("settings", "Settings")
s:tab("access", "Access")
s:tab("ports", "Ports")

o = s:taboption("main", Flag, "enable", "Enable Client")
o.rmempty = true

o = s:taboption("main", ListValue, "global_server", "TCP Server")
o:value("nil", "Disable")
for _, key in pairs(key_table) do o:value(key, server_table[key]) end
o.default = "nil"
o.rmempty = false

o = s:taboption("main", ListValue, "udp_relay_server", "UDP Server")
o:value("same", "Same as TCP Server")
for _, key in pairs(key_table) do o:value(key, server_table[key]) end
o.default = "nil"


o = s:taboption("main", ListValue, "socks5_server", "Socks5 Server")
o:value("nil", "Disable")
o:value("same", "Same as TCP Server")
for _, key in pairs(key_table) do o:value(key, server_table[key]) end
o.default = "nil"

o = s:taboption("settings", ListValue, 'log_level')
o.title = "Log Level"
o:value("debug", "Debug")
o:value("info", "Info")
o:value("warning", "Warning")
o:value("error", "Error")
o:value("none", "None")
o.default = "info"


o = s:taboption("settings", ListValue, "pdnsd_enable", "DNS Resolver")
o:value("1", "PDNSD")
o:value("2", "DNS2SOCKS")
o.default = 1

o = s:taboption("settings", Value, "tunnel_forward", "DNS Server")
o:value("8.8.4.4:53", "Google Public DNS (8.8.4.4:53)")
o:value("8.8.8.8:53", "Google Public DNS (8.8.8.8:53)")
o:value("208.67.222.222:53", "OpenDNS (208.67.222.222:53)")
o:value("208.67.220.220:53", "OpenDNS (208.67.220.220:53)")
o:value("209.244.0.3:53", "Level 3 Public DNS (209.244.0.3:53)")
o:value("209.244.0.4:53", "Level 3 Public DNS (209.244.0.4:53)")
o:value("4.2.2.1:53", "Level 3 Public DNS (4.2.2.1:53)")
o:value("4.2.2.2:53", "Level 3 Public DNS (4.2.2.2:53)")
o:value("4.2.2.3:53", "Level 3 Public DNS (4.2.2.3:53)")
o:value("4.2.2.4:53", "Level 3 Public DNS (4.2.2.4:53)")
o:value("1.1.1.1:53", "Cloudflare DNS (1.1.1.1:53)")
o:depends("pdnsd_enable", "1")
o:depends("pdnsd_enable", "2")
o.datatype = "hostport"



o = s:taboption('access', ListValue, 'lan_ifaces')
o.title = "LAN Interface"
o:value("br-lan", "br-lan")
for _, e in ipairs(luci.sys.net.devices()) do if e ~= "lo" then o:value(e) end end
o.default="br-lan"
o.rmempty = false

		
o = s:taboption("access", ListValue, "lan_ac_mode", "LAN Access Control")
o:value("1", "Bypassed List Mode")
o:value("2", "Proxied List Mode")

o = s:taboption("access", DynamicList, "lan_fp_ips", "LAN Proxied Host List")
o.datatype = "ipaddr"
luci.ip.neighbors({family = 4}, function(entry)
	if entry.reachable then
		o:value(entry.dest:string())
	end
end)
o:depends("lan_ac_mode","2")


o = s:taboption("access", DynamicList, "lan_bp_ips", "LAN Bypassed Host List")
o.datatype = "ipaddr"
luci.ip.neighbors({family = 4}, function(entry)
	if entry.reachable then
		o:value(entry.dest:string())
	end
end)
o:depends("lan_ac_mode","1")

o = s:taboption("access", DynamicList, "wan_bp_ips", "WAN Bypassed Host List")
o.datatype = "ip4addr"


o = s:taboption("ports", Value, "tcp_port", "TCP Port")
o.datatype = "port"
o.default = 1234
o.rmempty = false

o = s:taboption("ports", Value, "udp_port", "UDP Port")
o.datatype = "port"
o.default = 5350
o.rmempty = false

o = s:taboption("ports", Value, "socks5_port", translate("Socks5 Port"))
o.datatype = "port"
o.default = 1081
o.rmempty = false

o = s:taboption("ports", Value, "dns2socks_port", translate("DNS2Socks Port"))
o.datatype = "port"
o.default = 5351
o.rmempty = false

local apply = luci.http.formvalue("cbi.apply")
if apply then
  m.uci:commit("xclient")
  luci.sys.call("/etc/init.d/xclient boot >/dev/null 2>&1 &")
end

return m
