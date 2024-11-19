require "luci.http"
local uci = luci.model.uci.cursor()
local q, y

z = Map("xclient")
s = z:section(TypedSection, "global", "Routing Settings")
s.anonymous = true
s.addremove   = false

o = s:option(ListValue, 'routing_strategy', 'Query Strategy')
o:value("AsIs", "AsIs")
o:value("IPIfNonMatch", "IPIfNonMatch")
o:value("IPOnDemand", "IPOnDemand")
o.default = "IPIfNonMatch"
o.rmempty = true

o = s:option(ListValue, "domainMatcher", "Domain Matcher")
o:value("linear", "linear")
o:value("mph", "mph")
o.default = "linear"
o.rmempty = true
o.description = "Refer To Documentation"
..translatef("<a href=\"%s\" target=\"_blank\">" .. "%s".."</a>", "https://xtls.github.io/Xray-docs-next/config/routing.html", " Here")


y = Map("xclient")
y.pageaction = true

x = y:section(TypedSection, "rule", "Routing Rules")
x.anonymous = true
x.addremove = true
x.sortable = true

x.template = "cbi/tblsection"
x.extedit = luci.dispatcher.build_url("admin/services/xclient/rule/%s")
function x.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(x.extedit % sid)
		return
	end
end

o = x:option(DummyValue, "domainMatcher", "Domain Matcher")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "—"
end


o = x:option(DummyValue, "domain", "Domain")
o.rawhtml=true
function o.cfgvalue(t,e)
local t,e=t.map:get(e,"domain"),""
if t then
for a,t in pairs(t)do
e=e..t.."<br>"
end
return e
else
return"&#8212;"
end
end

o = x:option(DummyValue, "ip", "IP")
o.rawhtml=true
function o.cfgvalue(t,e)
local t,e=t.map:get(e,"ip"),""
if t then
for a,t in pairs(t)do
e=e..t.."<br>"
end
return e
else
return"&#8212;"
end
end

o = x:option(DummyValue, "port", "Port")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "—"
end

o = x:option(DummyValue, "sourcePort", "SourcePort")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "—"
end

o = x:option(DummyValue, "network", "Network")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "—"
end

o = x:option(DummyValue, "source", "Source")
o.rawhtml=true
function o.cfgvalue(t,e)
local t,e=t.map:get(e,"source"),""
if t then
for a,t in pairs(t)do
e=e..t.."<br>"
end
return e
else
return"&#8212;"
end
end

o = x:option(DummyValue, "inboundTag", "Inboundtag")
o.rawhtml=true
function o.cfgvalue(t,e)
local t,e=t.map:get(e,"inboundTag"),""
if t then
for a,t in pairs(t)do
e=e..t.."<br>"
end
return e
else
return"&#8212;"
end
end
	

o = x:option(DummyValue, "protocol", "Protocol")
o.rawhtml=true
function o.cfgvalue(t,e)
local t,e=t.map:get(e,"protocol"),""
if t then
for a,t in pairs(t)do
e=e..t.."<br>"
end
return e
else
return"&#8212;"
end
end	

o = x:option(DummyValue, "outboundTag", "Outboundtag")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "—"
end


local apply = luci.http.formvalue("cbi.apply")
if apply then
  y.uci:commit("xclient")
  z.uci:commit("xclient")
  luci.sys.call("/etc/init.d/xclient boot >/dev/null 2>&1 &")
end


return z, y
