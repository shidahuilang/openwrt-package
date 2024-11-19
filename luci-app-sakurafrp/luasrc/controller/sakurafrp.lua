module("luci.controller.sakurafrp", package.seeall)

local natfrpapi = require "luci.model.cbi.sakurafrp.natfrpapi"
local api = require "luci.model.cbi.sakurafrp.api"
local prog = api.prog

get_log = api.get_log
clear_log = api.clear_log
refresh_tunnels = natfrpapi.refresh_tunnels
reset_plugin = api.reset_plugin

frpc_install = api.frpc_install
frpc_restart = api.frpc_restart
frpc_stop = api.frpc_stop
frpc_force_stop = api.frpc_force_stop
frpc_fetch_config = api.frpc_fetch_config
frpc_uninstall = api.frpc_uninstall
function frpc_status()
        api.output_screen(api.frpc_status())
end

function index()
        prog = require("luci.model.cbi.sakurafrp.api").prog
        entry({"admin", "services", prog}, alias("admin", "services", prog, "config"), _("SakuraFrp")).dependent = true

        entry({"admin", "services", prog, "config"},
                cbi(prog .. "/pages/index"), translate("Config"), 1).dependent = true

        entry({"admin", "services", prog, "advanced"},
                cbi(prog .. "/pages/advanced"), translate("Advanced Config"), 2).dependent = true

        entry({"admin", "services", prog, "tunnel_list"},
                cbi(prog .. "/pages/tunnel/list"), translate("Tunnels"), 3).dependent = true

        entry({"admin", "services", prog, "tunnel_config"},
                cbi(prog .. "/pages/tunnel/config")).leaf = true

        entry({"admin", "services", prog, "node_status"},
                template(prog .. "/node_status"), translate("Node Status"), 4).dependent = true

        entry({"admin", "services", prog, "log"},
                cbi(prog .. "/pages/log"), translate("Log"), 5).dependent = true

        entry({"admin", "services", prog, "manual_edit"},
                cbi(prog .. "/pages/manual_edit"), translate("Manual Edit"), 6).dependent = true

        entry({"admin", "services", prog, "get_log"},
                call("get_log")).leaf = true
        entry({"admin", "services", prog, "clear_log"},
                call("clear_log")).leaf = true
        entry({"admin", "services", prog, "refresh_tunnels"},
                call("refresh_tunnels")).leaf = true
        entry({"admin", "services", prog, "reset_plugin"},
                call("reset_plugin")).leaf = true

        entry({"admin", "services", prog, "frpc_install"},
                call("frpc_install")).leaf = true
        entry({"admin", "services", prog, "frpc_restart"},
                call("frpc_restart")).leaf = true
        entry({"admin", "services", prog, "frpc_stop"},
                call("frpc_stop")).leaf = true
        entry({"admin", "services", prog, "frpc_force_stop"},
                call("frpc_force_stop")).leaf = true
        entry({"admin", "services", prog, "frpc_status"},
                call("frpc_status")).leaf = true
        entry({"admin", "services", prog, "frpc_uninstall"},
                call("frpc_uninstall")).leaf = true


        entry({"admin", "services", prog, "frpc_fetch_config"},
                call("frpc_fetch_config")).leaf = true

        entry({prog, "upload_cert"}, post("upload_cert"))
end

function endswith(str, substr)
    if str == nil or substr == nil then
        return nil, "the string or the sub-string parameter is nil"
    end
    str_tmp = string.reverse(str)
    substr_tmp = string.reverse(substr)
    if string.find(str_tmp, substr_tmp) ~= 1 then
        return false
    else
        return true
    end
end

function upload_cert()
    local fp
    require "luci.sys"
    local path = "/usr/share/sakurafrp"
    local domain = luci.http.formvalue("domain")
    local cert = luci.http.formvalue("cert")
    local key = luci.http.formvalue("key")
    local file_path
    api.output_screen(domain)
    -- FILE UPLOAD
    luci.http.setfilehandler(
            function(meta, chunk, eof)
                if not fp then
                    api.output_screen(meta.name)
                    if (meta.name == "cert") then
                        file_path = path .. "/" .. domain .. ".crt"
                        api.output_screen(file_path)
                        fp = io.open(file_path, "w")
                    elseif (meta.name == "key") then
                        file_path = path .. "/" .. domain .. ".key"
                        api.output_screen(file_path)
                        fp = io.open(file_path, "w")
                    else
                        file_path = ""
                        fp = nil
                    end
                end
                if chunk and fp then
                    fp:write(chunk)
                end
                if eof and fp then
                    fp:close()
                    fp = nil
                end
            end
    )
end