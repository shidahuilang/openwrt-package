local m, s, o
local xclient = "xclient"
local uci = luci.model.uci.cursor()

m = Map(xclient)

s = m:section(TypedSection, "global", "DNS Servers")
s.anonymous = true
s.addremove   = false

o = s:option(DynamicList, "dns_servers", "Servers")
o.rmempty = false

o = s:option(Value, 'clientIp', 'Client Ip')
o.rmempty = true

o = s:option(ListValue, 'queryStrategy', 'Query Strategy')
o:value("UseIP", "UseIP")
o:value("UseIPv4", "UseIPv4")
o:value("UseIPv6", "UseIPv6")
o.rmempty = true


o = s:option(ListValue, 'disableCache', 'Disable Cache')
o:value("0", "False")
o:value("1", "True")
o.rmempty = true

o = s:option(ListValue, 'disableFallback', 'Disable Fallback')
o:value("0", "False")
o:value("1", "True")
o.rmempty = true

o = s:option(ListValue, 'disableFallbackIfMatch', 'Disable Fallback If Match')
o:value("0", "False")
o:value("1", "True")
o.rmempty = true
o.description = "Refer To Documentation"
..translatef("<a href=\"%s\" target=\"_blank\">" .. "%s".."</a>", "https://xtls.github.io/Xray-docs-next/config/dns.html", " Here")

y = Map("xclient")
y.pageaction = true

x = y:section(TypedSection, "dns", "DNS Rules")
x.anonymous = true
x.addremove = true
x.sortable = true

x.template = "cbi/tblsection"
x.extedit = luci.dispatcher.build_url("admin/services/xclient/add-dns/%s")
function x.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(x.extedit % sid)
		return
	end
end


o = x:option(DummyValue, "address", "Address")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "—"
end

o = x:option(DummyValue, "port", "Port")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "—"
end


o = x:option(DummyValue, "domains", "Domains")
o.rawhtml=true
function o.cfgvalue(t,e)
local t,e=t.map:get(e,"domains"),""
if t then
for a,t in pairs(t)do
e=e..t.."<br>"
end
return e
else
return"&#8212;"
end
end

o = x:option(DummyValue, "expectIPs", "ExpectIPs")
o.rawhtml=true
function o.cfgvalue(t,e)
local t,e=t.map:get(e,"expectIPs"),""
if t then
for a,t in pairs(t)do
e=e..t.."<br>"
end
return e
else
return"&#8212;"
end
end
	
o = x:option(Flag, "skipFallback", "SkipFallback")
o.rmempty     = false
o.default     = o.skipFallback
o.cfgvalue    = function(...)
    return Flag.cfgvalue(...) or "0"
end


local apply = luci.http.formvalue("cbi.apply")
if apply then
  m.uci:commit("xclient")
  y.uci:commit("xclient")
  luci.sys.call("/etc/init.d/xclient boot >/dev/null 2>&1 &")
end

return m,y

