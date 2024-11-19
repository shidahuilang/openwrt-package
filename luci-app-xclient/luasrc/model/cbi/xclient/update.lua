
m = Map("xclient")

s = m:section(TypedSection, "xclient")
s.anonymous = true
s.addremove=false

s:append(Template("xclient/version"))

return m
