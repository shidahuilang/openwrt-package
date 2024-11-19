local api = require "luci.model.cbi.sakurafrp.api"
local fs = api.fs
local prog = api.prog

m = Map(prog, translate("Manual Edit frpc.ini"))
s = m:section(NamedSection, "manual")

manual_edit = s:option(Flag, "enable", translate("Enable Manual Edit"), translate("<font color=red>Note. Manual edited configuration may conflict with luci-app-sakurafrp configurations.<br>Thus by enabling manual edit, luci custom config options will be disabled</font>"))

conf_view = s:option(TextValue, "conf_view", "", "<font color='red'>" .. translate("Please note. frpc.ini will be overwritten once you changed tunnel config and then run frpc!") .. "</font>")
conf_view.readonly = true
conf_view.rows = 25
conf_view.wrap = "off"
conf_view.cfgvalue = function(self, section)
    return fs.readfile(api.conf_file) or ""
end
conf_view:depends("enable", 0)

conf_edit = s:option(TextValue, "conf_edit", "", "<font color='red'>" .. translate("Please note. frpc.ini will be overwritten once you changed tunnel config and then run frpc!") .. "</font>")
conf_edit.rows = 25
conf_edit.wrap = "off"
conf_edit.cfgvalue = function(self, section)
    return fs.readfile(api.conf_file) or ""
end
conf_edit.write = function(self, section, value)
    fs.writefile(api.conf_file, value:gsub("\r\n", "\n"))
end
conf_edit.remove = function(self, section, value)
    fs.writefile(api.conf_file, "")
end
conf_edit:depends("enable", 1)

return m