local o = require "luci.sys"
local a, t, e
a = Map("zerotier", translate("ZeroTier"))
a.description = translate("Zerotier is an open source, cross-platform and easy to use virtual LAN.")
a.template = "zerotier/index"

t = a:section(NamedSection, "sample_config", "zerotier")
t.anonymous = true
t.addremove = false
---- status
e = t:option(DummyValue, "status", translate("Status"))
e.template = "zerotier/status"
e.value = translate("Collectiong data...")
---- enable
e = t:option(Flag, "enabled", translate("Enable"))
e.default = 0
e.rmempty = false
---- network id
e = t:option(DynamicList, "join", translate('ZeroTier Network ID'))
e.password = true
e.rmempty = false
---- auto nat
e = t:option(Flag, "nat", translate("Auto NAT Clients"))
e.description = translate("Allow zerotier clients access your LAN network")
e.default = 0
e.rmempty = false
---- my zerotier
e = t:option(DummyValue,"opennewwindow" , translate("<input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\"My ZeroTier\" onclick=\"window.open('https://my.zerotier.com/network')\" />"))
e.description = translate("Create or manage your zerotier network, and auth clients who could access")

return a
