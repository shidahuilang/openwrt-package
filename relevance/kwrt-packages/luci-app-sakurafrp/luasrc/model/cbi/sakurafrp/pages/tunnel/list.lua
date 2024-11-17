local api = require "luci.model.cbi.sakurafrp.api"
local natfrpapi = require "luci.model.cbi.sakurafrp.natfrpapi"
local prog = api.prog

local m = Map(prog, translate("Tunnel List"))

banner = m:section(NamedSection, "other")
banner:append(Template(prog .. "/frpc_banner"))
banner:append(Template(prog .. "/list_banner"))

tunnels = m:section(TypedSection, "tunnel")

tunnels.template = "cbi/tblsection"
tunnels.anonymous = true
tunnels.sortable = true

enable = tunnels:option(Flag, "enable", translate("Enable"))
id = tunnels:option(DummyValue, "id", "ID")
tunnel_name = tunnels:option(DummyValue, "name", translate("Tunnel Name"))
type = tunnels:option(DummyValue, "type", translate("Tunnel Type"))
_local = tunnels:option(DummyValue, "", translate("Local"))
_local.cfgvalue = function(self, section)
    local host = api.uci_get_type_id(section, "local_host")
    local port = api.uci_get_type_id(section, "local_port")

    return string.format("%s:%s", tostring(host), tostring(port))
end
remote = tunnels:option(DummyValue, "remote", translate("Remote"))
remote.rawhtml = true
note = tunnels:option(DummyValue, "note", translate("Note"))
tunnels.extedit = api.url("tunnel_config", "%s")

return m