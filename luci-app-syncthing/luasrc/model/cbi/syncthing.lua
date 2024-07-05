require("nixio.fs")

m = Map("syncthing", translate("Syncthing同步工具"))

m:section(SimpleSection).template = "syncthing/syncthing_status"

s = m:section(TypedSection, "syncthing")

s.anonymous = true

o = s:option(Flag, "enabled", translate("启用"))
o.default = 0
o.rmempty = false

gui_address = s:option(Value, "gui_address", translate("GUI访问地址"))
gui_address.description = translate("使用0.0.0.0以监控所有访问。")
gui_address.default = "http://0.0.0.0:8384"
gui_address.placeholder = "http://0.0.0.0:8384"
gui_address.rmempty = false

home = s:option(Value, "home", translate("配置文件目录"))
home.description = translate("只有保存在/etc/syncthing中的配置会自动备份！")
home.default = "/etc/syncthing"
home.placeholder = "/etc/syncthing"
home.rmempty = false

user = s:option(ListValue, "user", translate("用户"))
user.description = translate("默认是syncthing，但这可能会导致权限被拒绝。Syncthing官方不建议以root身份运行。")
user:value("", translate("syncthing"))
for u in luci.util.execi("cat /etc/passwd | cut -d ':' -f1") do
	user:value(u)
end

macprocs = s:option(Value, "macprocs", translate("线程限制"))
macprocs.description = translate("0表示匹配CPU数量（默认），>0表示显式指定并发数。")
macprocs.default = "0"
macprocs.placeholder = "0"
macprocs.datatype = "range(0,32)"
macprocs.rmempty = false

nice = s:option(Value, "nice", translate("优先级"))
nice.description = translate("显式指定优先级值。0是最高，19是最低。（暂时不允许设置负值）")
nice.default = "19"
nice.placeholder = "19"
nice.datatype = "range(0,19)"
nice.rmempty = false

return m
