local uci = luci.model.uci.cursor()

a = Map("miaplus")
a.title = translate("Internet Access Schedule Control Plus")
a.description = translate("Access Schedule Control Description")

a:section(SimpleSection).template = "miaplus/miaplus_status"

t = a:section(TypedSection, "basic")
t.anonymous = true

e = t:option(Flag, "enable", translate("Enabled"))
e.rmempty = false

e = t:option(Flag, "strict", translate("Strict Mode"))
e.description = translate("Strict Mode will degrade CPU performance, but it can achieve better results")
e.rmempty = false

e = t:option(Flag, "ipv6enable", translate("IPV6 Enabled"))
e.rmempty = false

t = a:section(TypedSection, "macbind", translate("Client Rules"))
t.template = "cbi/tblsection"
t.anonymous = true
t.addremove = true
t.sortable  = true

e = t:option(Flag, "enable", translate("Enabled"))
e.rmempty = false
e.default = "1"

e = t:option(Value, "macaddr", translate("MAC address (Computer Name)"))
e.rmempty = true
luci.sys.net.mac_hints(function(t,a)
e:value(t,"%s (%s)"%{t,a})
end)

e = t:option(ListValue, "template", translate("Template"))
uci:foreach("miaplus", "templates",
        function(s)
            e:value(s['.name'],s['title'])
        end)
return a
