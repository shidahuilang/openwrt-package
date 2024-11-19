local m, s;
m = SimpleForm("logview")
m.reset = false
m.submit = false

s = m:field(TextValue, "conf")
s.rmempty = true
s.rows = 20
s.template = "gpioled/logs"
s.readonly = "readonly"

return m