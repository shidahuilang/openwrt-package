-- Copyright 2019 Shun Li <riverscn@gmail.com>
-- Licensed to the public under the GNU General Public License v3.

m = Map("iptvhelper", translate("IPTV Helper"))
m.description = translate("Help you configure IPTV easily. <a href=\"https://github.com/riverscn/openwrt-iptvhelper\">Github</a>")

s = m:section(TypedSection, "tvbox", translate("IPTV topbox parameters"))
s.addremove = true
s.anonymous = false

o = s:option(Flag, "disabled", translate("Enabled"))
o.enabled = "0"
o.disabled = "1"
o.default = "1"
o.rmempty = false

o = s:option(Flag, "respawn", translate("Respawn"))
o.default = false

o = s:option(Flag, "ipset", translate("Create ipset"))
o.description = translate("You can use it in mwan3.")
o.default = true

o = s:option(Flag, "dns_redir", translate("Redirect topbox's DNS"))
o.description = translate("You may need it to jailbreak your topbox.")
o.default = false

o = s:option(Value, "mac", translate("Topbox MAC Address"))
o.description = translate("It is usually on the bottom side of topbox.")
o.rmempty = false
o.datatype = "macaddr"
luci.sys.net.mac_hints(function(mac, name)
	o:value(mac, "%s (%s)" %{ mac, name })
end)

return m
