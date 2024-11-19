local api = require "luci.model.cbi.sakurafrp.api"
local natfrpapi = require "luci.model.cbi.sakurafrp.natfrpapi"
local prog = api.prog

m = Map(prog, "Luci Support for SakuraFrp")

banner = m:section(NamedSection, "other")
banner.template = prog .. "/index_banner"

frpc = m:section(NamedSection, "other", "", api.frpc_status())
frpc:append(Template(prog .. "/frpc_banner"))

user = m:section(NamedSection, "config", "", translate("User Config"))
user.addremove = false
user.anonymous = true
enable = user:option(Flag, "enable", translate("Run SakuraFrp"))
token = user:option(Value, "token", translate("Access Token"))
token.validate = function(self, value, t)
    if natfrpapi.verify_token(value) then
        return value
    else
        return nil, translate("Invalid Token!")
    end
end

ssl = m:section(TypedSection, "config_ssl", translate("Auto SSL"))
ssl.addremove = false
ssl.anonymous = true
ssl.template = "cbi/tblsection"

ssl_list = ssl:option(Value, "domain", translate("Domain"))
ssl_list.readonly = true
ssl_list.editable = false

for i, domain in pairs(api.get_available_ssl_domains()) do
    ssl_list:value(i, domain)
end

uploader = ssl:option(Button, "", translate("Add"))
uploader.write = function()
    luci.template.render(prog .. "/upload_ssl")
    luci.http.write("<script>window.onload = function() {activeOverlay()}</script>")
end


local apply = luci.http.formvalue("cbi.apply")
if apply then
    api.frpc_restart()
    --luci.dispatcher.build_url("admin", "services", "sakurafrp", "frpc_restart")
end
return m


