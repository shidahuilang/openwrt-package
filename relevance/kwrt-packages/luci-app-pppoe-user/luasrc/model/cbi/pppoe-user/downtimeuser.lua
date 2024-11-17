local o = require "luci.dispatcher"
local fs = require "nixio.fs"
local jsonc = require "luci.jsonc"

f = SimpleForm("")
f.reset = false
f.submit = false

local count = luci.sys.exec("uci show pppoe-user | grep enabled | cut -d '=' -sf 2 | grep '0' | wc -l")
t = f:section(Table, sessions, translate("Downtime User [ " .. count .. "]"))
t:option(DummyValue, "username", translate("Username"))
t:option(DummyValue, "macaddr", translate("MAC address"))
t:option(DummyValue, "package", translate("Broadband Package"))
t:option(DummyValue, "password", translate("Registration Date"))
t:option(DummyValue, "renewaldate", translate("Renewal Date"))
t:option(DummyValue, "downtime", translate("Down Time"))

return f
