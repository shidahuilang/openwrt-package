local m, s, o
local xclient = "xclient"
local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local sid = arg[1]


m = Map(xclient, "Add/Edit Rule")
--m.pageaction = false
m.redirect = luci.dispatcher.build_url("admin/services/xclient/routing")
if m.uci:get(xclient, sid) ~= "rule" then
	luci.http.redirect(m.redirect)
	return
end

s = m:section(NamedSection, sid, "rule")
s.anonymous = true
s.addremove   = false

o = s:option(ListValue, "domainMatcher", "Domain Matcher")
o:value("linear", "linear")
o:value("mph", "mph")
o.default = "linear"
o.rmempty = true

o = s:option(DynamicList, "domain", "Domain")
o.rmempty = true

o = s:option(DynamicList, "ip", "IP")
o.rmempty = true

o = s:option(Value, "port", "Port")
o.rmempty = true

o = s:option(Value, "sourcePort", "SourcePort")
o.rmempty = true

o = s:option(Value, "network", "Network")
o.rmempty = true

o = s:option(DynamicList, "source", "Source")
o.rmempty = true

o = s:option(DynamicList, "inboundTag", "InboundTag")
o:value("proxy_inbound", "PROXY_INBOUND")
o:value("dns_inbound", "DNS_INBOUND")
o:value("socks_inbound", "SOCKS_INBOUND")
o.rmempty = false

o = s:option(DynamicList, "protocol", "Protocol")
o:value("http", "HTTP")
o:value("tls", "TLS")
o:value("bittorrent", "BITTORRENT")
o.rmempty = true

o = s:option(ListValue, "outboundTag", "OutboundTag")
o:value("proxy_outbound", "PROXY_OUTBOUND")
o:value("dns_outbound", "DNS_OUTBOUND")
o:value("direct", "DIRECT")
o:value("block", "BLOCK")
o.rmempty = false
o.description = "Refer To Documentation"
..translatef("<a href=\"%s\" target=\"_blank\">" .. "%s".."</a>", "https://xtls.github.io/Xray-docs-next/config/routing.html", " Here")


return m
