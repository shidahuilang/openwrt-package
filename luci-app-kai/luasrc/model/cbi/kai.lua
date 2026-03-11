local m, s

m = Map("kai", translate("KAI"), translate("KAI is an efficient AI tool."))
m:section(SimpleSection).template  = "kai/kai_status"

s=m:section(TypedSection, "kai", translate("Global settings"))
s.addremove=false
s.anonymous=true

s:option(Flag, "enabled", translate("Enable")).rmempty=false

local kai_model = require "luci.model.kai"
local blocks = kai_model.blocks()
local home = kai_model.home()

local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.rmempty = false
data_dir.description = translate("Required. KAI session will store cwd/cache/data/config/state under this directory (subfolders: cwd, cache, data, config, state).")

local paths, default_path = kai_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
	data_dir:value(val, val)
end
data_dir.default = default_path

local port = s:option(Value, "port", translate("API port"))
port.default = "8197"
port.rmempty = false
port.datatype = "port"
port.description = translate("Port for KAI HTTP server (kai_bin). kai_session will read OPENCODE_CONFIG via 127.0.0.1:<port>.")

return m
