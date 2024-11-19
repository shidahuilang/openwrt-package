local api = require "luci.model.cbi.sakurafrp.api"
local prog = api.prog

f = Form(prog, translate("View Log"))
f.reset = false
f.submit = false
f:append(Template(prog .. "/frpc_banner"))
f:append(Template(prog .. "/log"))
return f
