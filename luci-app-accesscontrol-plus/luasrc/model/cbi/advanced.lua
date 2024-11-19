local ds = require "luci.dispatcher"

a = Map("miaplus")

t = a:section(TypedSection, "templates")
t.template = "cbi/tblsection"
t.anonymous = true
t.addremove = true
t.sortable  = true
t.extedit   = ds.build_url("admin/services/miaplus/template/%s")

e = t:option(Flag, "enable", translate("Enabled"))
e.rmempty = false
e.default = "1"

e = t:option(Value, "title", translate("Template"))
e.width = "40%"
e.optional = false
e.default = "default"

return a
