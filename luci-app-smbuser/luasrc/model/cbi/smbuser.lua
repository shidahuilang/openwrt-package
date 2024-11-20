-- Copyright 2024 sbwml <admin@cooluc.com>
-- Licensed to the public under the GPL-3.0 License.

local sys  = require "luci.sys"
local util = require "luci.util"

local m, s ,o

m = Map("smbuser", translate("Samba4 User Management"), translate("This LuCI is a basic user management for Samba4."))
s = m:section(TypedSection, "smbuser", translate("User List"))
s.template = "cbi/tblsection"
s.anonymous = true
s.addremove = true

o = s:option(Value, "username", translate("Username"))
local username
for username in util.execi("awk -F: '{print $1}' /etc/passwd") do
	o:value(username)
end

o = s:option(Value, "password", translate("Password"))
o.datatype = "string"
o.password = true

m.apply_on_parse = true
m.on_after_apply = function(self,map)
	sys.exec("/usr/share/smbuser/add_smbuser.sh")
end

return m
