
local m

m = Map("xclient")
s = m:section(TypedSection, "log")
m.pageaction = false
s.anonymous = true
s.addremove=false

l = s:option(TextValue, "log")
l.template = "xclient/logs"

return m

