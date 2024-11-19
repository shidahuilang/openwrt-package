f = SimpleForm("vnt")
f.reset = false
f.submit = false
f:append(Template("vnt/vnts_log"))
return f
