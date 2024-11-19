local api = require "luci.model.cbi.sakurafrp.api"
local prog = api.prog

f = Form(prog, translate("Node Status"))
f.reset = false
f.submit = false
f:append(Template(prog .. "/node_status"))
return f