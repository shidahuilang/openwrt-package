local api = require "luci.model.cbi.passwall.api.api"
local uci = api.uci
local jsonc = api.jsonc

local var = api.get_args(arg)
local node_section = var["-node"]
if not node_section then
    print("-node 不能为空")
    return
end
local local_addr = var["-local_addr"]
local local_port = var["-local_port"]
local server_host = var["-server_host"]
local server_port = var["-server_port"]
local protocol = var["-protocol"]
local mode = var["-mode"]
local node = uci:get_all("passwall", node_section)

local config = {
    server = server_host or node.address,
    server_port = tonumber(server_port) or tonumber(node.port),
    local_address = local_addr,
    local_port = tonumber(local_port),
    password = node.password,
    method = node.method,
    timeout = tonumber(node.timeout),
    fast_open = (node.tcp_fast_open and node.tcp_fast_open == "true") and true or false,
    reuse_port = true,
    tcp_tproxy = var["-tcp_tproxy"] and true or nil
}

if node.type == "SS" then
    if node.plugin and node.plugin ~= "none" then
        config.plugin = node.plugin
        config.plugin_opts = node.plugin_opts or nil
    end

    config.protocol = protocol
    config.mode = mode
elseif node.type == "SSR" then
    config.protocol = node.protocol
    config.protocol_param = node.protocol_param
    config.obfs = node.obfs
    config.obfs_param = node.obfs_param
end

print(jsonc.stringify(config, 1))
