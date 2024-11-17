local api = require "luci.coredns.api"
local fs   = require "nixio.fs"
local sys  = require "luci.sys"

m = Map("coredns")
m.title = "DNS " .. translate("Redir Rule")
m.description = translate("Please refer to") .. " <a href='https://github.com/leiless/dnsredir' target='_blank'>https://github.com/leiless/dnsredir</a>"

-- s = m:section(TypedSection, "coredns_rule_update", translate("Rules Update"))
-- s.anonymous = true
   
-- -- o = s:option(Button, "_update", translate("Manual subscription All"))
-- o = s:option(Button, "_update", translate("Manual subscription All"))
-- o.inputstyle = "apply"
-- function o.write(t, n)
-- 	luci.sys.call("lua /usr/share/coredns/update_rule.lua > /dev/null 2>&1 &")
-- 	luci.http.redirect(api.url("log"))
-- end

s = m:section(TypedSection, "coredns_rule_file", "DNS " .. translate("Redir Rule") .. " - " .. translate("File"))
s.addremove = true
s.anonymous = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = api.url("rule_file_config", "%s")
function s.create(e, t)
	local id = TypedSection.create(e, t)
	luci.http.redirect(e.extedit:format(id))
end

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

o = s:option(DummyValue, "name", translate("Name"))
o.width = "auto"
o.rawhtml = true 

o = s:option(DummyValue, "file", translate("File"))
o.width = "auto"
o.rawhtml = true 

o = s:option(DummyValue, "dns", translate("DNS"))
o.width = "auto"
o.rawhtml = true 

o = s:option(DummyValue, "bootstrap_dns", translate("Bootstrap DNS"))
o.width = "auto"
o.rawhtml = true 

o = s:option(Button, "_view", translate("View"))
o.inputstyle = "reset"
function o.write(t, n)
	luci.http.redirect(api.url("rule_file_content/" .. n))
end

s = m:section(TypedSection, "coredns_rule_url", "DNS " .. translate("Redir Rule") .. " - " .. translate("Subscribe"))
s.addremove = true
s.anonymous = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = api.url("rule_url_config", "%s")
function s.create(e, t)
	local id = TypedSection.create(e, t)
	luci.http.redirect(e.extedit:format(id))
end

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

o = s:option(DummyValue, "name", translate("Name"))
o.width = "auto"
o.rawhtml = true 

o = s:option(DummyValue, "url", translate("Subscribe URL"))
o.width = "auto"
o.rawhtml = true 

o = s:option(DummyValue, "dns", translate("DNS"))
o.width = "auto"
o.rawhtml = true 

o = s:option(DummyValue, "bootstrap_dns", translate("Bootstrap DNS"))
o.width = "auto"
o.rawhtml = true 

o = s:option(Button, "_update", translate("Update"))
o.inputstyle = "apply"
function o.write(t, n)
	luci.sys.call("lua /usr/share/coredns/update_rule.lua " .. n .. " > /dev/null 2>&1 &")
	luci.http.redirect(api.url("log"))
end

o = s:option(Button, "_view", translate("View"))
o.inputstyle = "reset"
function o.write(t, n)
	luci.http.redirect(api.url("rule_file_content/" .. n))
end

s = m:section(TypedSection, "coredns", "Hosts " .. translate("File"), translate("The hosts file has a top prority over DNS"))
s.addremove = false
s.anonymous = true

o = s:option(TextValue, "hosts")
o.template = "cbi/tvalue"
o.rows = 5
o.description = translate("Path") .. ":/usr/share/coredns/hosts"

function o.cfgvalue(self, section)
    return fs.readfile("/usr/share/coredns/hosts")
end

function o.write(self, section, value)
    value = value:gsub("\r\n?", "\n")
    fs.writefile("/usr/share/coredns/hosts", value)
end

return m
