a = Map("miaplus")

local section = arg[1]

t = a:section(TypedSection, section, translate("Rules"))
t.template = "cbi/tblsection"
t.anonymous = true
t.addremove = true
t.sortable  = true

e = t:option(Flag, "enable", translate("Enabled"))
e.rmempty = false
e.default = "1"

e = t:option(Value, "timeon", translate("Start time"))
e.optional = false
e.default = "00:00"

e = t:option(Value, "timeoff", translate("End time"))
e.optional=false
e.default = "23:59"

e = t:option(Flag, "z1", translate("Mon"))
e.rmempty = true
e.default = 1

e = t:option(Flag, "z2", translate("Tue"))
e.rmempty = true
e.default=1

e = t:option(Flag, "z3", translate("Wed"))
e.rmempty = true
e.default = 1

e = t:option(Flag, "z4", translate("Thu"))
e.rmempty = true
e.default = 1

e = t:option(Flag, "z5", translate("Fri"))
e.rmempty = true
e.default = 1

e = t:option(Flag, "z6", translate("Sat"))
e.rmempty = true
e.default = 1

e = t:option(Flag, "z7", translate("Sun"))
e.rmempty = true
e.default = 1

return a
