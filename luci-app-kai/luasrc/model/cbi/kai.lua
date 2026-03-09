local m, s

m = Map("kai", translate("KAI"), translate("KAI is an efficient AI tool."))
m:section(SimpleSection).template  = "kai/kai_status"

s=m:section(TypedSection, "kai", translate("Global settings"))
s.addremove=false
s.anonymous=true

s:option(Flag, "enabled", translate("Enable")).rmempty=false

local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.placeholder = ""
data_dir.rmempty = false
data_dir.description = translate("Required. KAI session will store cwd/cache/data/config/state under this directory (subfolders: cwd, cache, data, config, state).")

local port = s:option(Value, "port", translate("API port"))
port.default = "8197"
port.rmempty = false
port.datatype = "port"
port.description = translate("Port for KAI HTTP server (kai_bin). kai_session will read OPENCODE_CONFIG via 127.0.0.1:<port>.")

return m
