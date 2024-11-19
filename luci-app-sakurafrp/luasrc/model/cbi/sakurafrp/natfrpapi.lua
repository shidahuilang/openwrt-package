module("luci.model.cbi.sakurafrp.natfrpapi", package.seeall)

local api = require "luci.model.cbi.sakurafrp.api"
local prog = api.prog

nodeTable = {}

function curlRequest(url, method, ...)
    if ... ~= nil then
        local args = { ... }
        args = table.concat(args, "&")
        url = url .. "?" .. args
    end

    return api.exec("curl -X %s %s", method, url)
end

function fetch_nodes(token)
    local response = curlRequest("https://api.natfrp.com/launcher/get_nodes", "GET", "token=" .. token)
    return luci.jsonc.parse(response).data
end

function fetch_tunnels(token)
    local response = curlRequest("https://api.natfrp.com/launcher/get_tunnels", "GET", "token=" .. token)
    return luci.jsonc.parse(response).data
end

function verify_token(token)
    api.output_log("Verifying token=%s", tostring(token))
    local response = curlRequest("https://api.natfrp.com/launcher/get_tunnels", "GET", "token=" .. token)
    return luci.jsonc.parse(response).success == true
end

function apply_nodes(token)
    local data = fetch_nodes(token)
    for _, v in pairs(data) do
        nodeTable[v.id] = v.name
    end
end

function local_remote_wrapper(tunnel_data)
    local result = {
        ["local_port"] = "",
        ["local_host"] = "",
        ["remote"] = ""
    }
    function map_port(port)
        if (port == "HTTP") then
            return "80", true
        elseif (port == "HTTPS") then
            return "443", true
        else
            return port, false
        end
    end

    local node = string.format("[%s]", nodeTable[tunnel_data.node])
    local type = tunnel_data.type
    local description = tunnel_data.description
    local local_str = ""

    if (type == "wol") then
        result["local_host"] = ""
        result["local_port"] = ""
        result["remote"] = node
    elseif (type == "etcp" or type == "eudp") then
        local_str = description
        result["remote"] = node
    else
        description = string.gsub(description, " ", "")
        local position = string.find(description, "→")

        local remote_port = string.sub(description, 1, position-1)
        local remote_host = "NotProvided"
        local remote_ip = "NotProvided"
        remote_port, http_tunnel = map_port(remote_port)

        if http_tunnel then
            result["remote"] = string.format("%s<br>%s:%s", node, remote_host, remote_port)
        else
            result["remote"] = string.format("%s<br>%s:%s<br>%s:%s", node, remote_host, remote_port, remote_ip, remote_port)
        end

        local_str = string.sub(description, position+3)
    end

    if (local_str ~= "") then
        local sp_loc = string.find(local_str, ":")
        result["local_host"] = string.sub(local_str, 1, sp_loc-1)
        result["local_port"] = string.sub(local_str, sp_loc+1)
    end

    return result
end

function apply_tunnels(token)
    local data = fetch_tunnels(token)
    for _, v in pairs(data) do
        local wrapped = local_remote_wrapper(v)
        api.output_log("Setting up tunnel{id=%s, name=%s}", v.id, v.name)

        local tunnel = {
            ["id"] = v.id,
            ["name"] = v.name,
            ["note"] = v.note,
            ["type"] = v.type,
            ["local_host"] = wrapped["local_host"],
            ["local_port"] = wrapped["local_port"],
            ["remote"] = wrapped["remote"]
        }

        api.uci_create_type_id(v.id, "tunnel")
        api.uci_set_type_id_batch(v.id, tunnel)
    end
end

function remove_tunnels()
    api.uci_remove_all_type("tunnel")
end

function refresh_tunnels()
    token = api.uci_get_type_id("config", "token", "")
    return refresh_tunnels_token(token)
end

function refresh_tunnels_token(token)
    remove_tunnels()
    if token == nil or token == "" or type(token) ~= "string" then return end

    api.output_log("Refreshing with token %s.", token)
    if verify_token(token) then
        apply_nodes(token)
        apply_tunnels(token)
    end
end