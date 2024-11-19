local m, s, o
local xclient = "xclient"
local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local sid = arg[1]


m = Map(xclient, "Add/Edit DNS Rule")
--m.pageaction = false
m.redirect = luci.dispatcher.build_url("admin/services/xclient/dns")
if m.uci:get(xclient, sid) ~= "dns" then
	luci.http.redirect(m.redirect)
	return
end


s = m:section(NamedSection, sid, "dns")
s.anonymous = true
s.addremove   = false


o = s:option(Value, "address", "Address")
o.rmempty = true


o = s:option(Value, "port", "Port")
o.rmempty = false

o = s:option(DynamicList, "domains", "Domains")
o.rmempty = true

o = s:option(DynamicList, "expectIPs", "expectIPs")
o.rmempty = true

o = s:option(Flag, "skipFallback", "skipFallback")
o.rmempty = true
o.description = "Refer To Documentation"
..translatef("<a href=\"%s\" target=\"_blank\">" .. "%s".."</a>", "https://xtls.github.io/Xray-docs-next/config/dns.html", " Here")


return m