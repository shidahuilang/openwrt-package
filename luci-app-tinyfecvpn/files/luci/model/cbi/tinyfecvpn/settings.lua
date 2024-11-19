local uci  = require "luci.model.uci".cursor()
local util = require "luci.util"
local sys  = require "luci.sys"
local fs   = require "nixio.fs"

local m, s, o

local servers = {}
uci:foreach("tinyfecvpn", "servers", function(s)
	if s.server_addr and s.server_port then
		servers[#servers+1] = {name = s[".name"], alias = s.alias or "%s:%s" %{s.server_addr, s.server_port}}
	end
end)

m = Map("tinyfecvpn","%s - %s" %{translate("tinyFecVpn"), translate("Settings")})
m:append(Template("tinyfecvpn/status"))

s = m:section(NamedSection, "general", "general", translate("General Settings"))
s.addremove = false

o = s:option(DynamicList, "server", translate("Server"))
o.template = "tinyfecvpn/dynamiclist"
o:value("nil", translate("Disable"))
for _, s in ipairs(servers) do o:value(s.name, s.alias) end
o.default = "nil"
o.rmempty = false

o = s:option(Value, "client_file", translate("Client File"))
o.rmempty  = false

o = s:option(ListValue, "daemon_user", translate("Run Daemon as User"))
for u in luci.util.execi("cat /etc/passwd | cut -d ':' -f1") do o:value(u) end
o.default = "root"
o.rmempty = false

o = s:option(Flag, "log", translate("Log"), translate("Forward stdout of the command to logd"))
o.default = "0"


return m
