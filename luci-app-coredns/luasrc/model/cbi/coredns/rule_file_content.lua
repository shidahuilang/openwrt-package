local api = require "luci.coredns.api"
local fs   = require "nixio.fs"
local sys  = require "luci.sys"

m = Map("coredns")
m.redirect = api.url("rule_list")
m.readonly = true
-- m.pageaction = false

local name = m:get(arg[1],"name")
local file = m:get(arg[1],"file")

s = m:section(NamedSection, arg[1], "", name)
s.description = "/usr/share/coredns/" .. file
s.addremove = false
s.dynamic = false

o = s:option(TextValue, "manual-input",nil)
o.template = "cbi/tvalue"
-- o.description = translate("Path") .. ":/usr/share/coredns/" .. file
o.rows = 25
function o.cfgvalue(self, section)
	local file = m:get(section,"file");
	if(file == nil) then
		return "";
	else
		return fs.readfile("/usr/share/coredns/" .. file)
	end
end

return m
