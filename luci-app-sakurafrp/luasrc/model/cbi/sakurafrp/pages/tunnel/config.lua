local api = require "luci.model.cbi.sakurafrp.api"
local natfrpapi = require "luci.model.cbi.sakurafrp.natfrpapi"
local prog = api.prog

if not arg[1] or not api.uci:get(prog, arg[1]) then
    luci.http.redirect(api.url("tunnel_list"))
end

api.read_frpc_config_tunnel(arg[1])

m = Map(prog, translate("Tunnel Config"), translate("Refer to <a href='https://doc.natfrp.com/frpc/manual.html#advanced-env'>Frpc Manual</a>"))
m.redirect = api.url()
manual_enable = api.uci_get_type_id("manual", "enable", 0)
if (tonumber(manual_enable) == 1) then
    disabled = s:option(DummyValue, "", translate("Disabled due to Manual Edit Enabled"))
    return m
end


tunnel = m:section(NamedSection, arg[1])

--Remote config
tunnel:append(Template(prog .. "/config_title_remote"))
id = tunnel:option(Value, "id", translate("Tunnel ID"))
tunnel_name = tunnel:option(Value, "tunnel_name", translate("Tunnel Name"))
type = tunnel:option(Value, "type", translate("Tunnel Type"))
remote = tunnel:option(Value, "remote", translate("Remote"))
remote.rawhtml = true

id.readonly = true
tunnel_name.readonly = true
remote.readonly = true
type.readonly = true

--Local config
tunnel:append(Template(prog .. "/config_title_local"))
local_host = tunnel:option(Value, "local_host", translate("Host"))
local_port = tunnel:option(Value, "local_port", translate("Port"))
note = tunnel:option(Value, "note", translate("Note"))

--Tcp config
tunnel:append(Template(prog .. "/config_title_tcp"))

return m