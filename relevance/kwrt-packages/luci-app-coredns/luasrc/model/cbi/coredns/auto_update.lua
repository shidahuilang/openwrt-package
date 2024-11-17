m = Map("coredns")

s = m:section(TypedSection, "coredns_rule_update", translate("Redir Rule"))
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "rule_auto_update", translate("Enable Auto Update"))
enable.rmempty = false

o = s:option(ListValue, "rule_update_week_time", translate("Update Cycle"))
o:value("*", translate("Every Day"))
o:value("1", translate("Every Monday"))
o:value("2", translate("Every Tuesday"))
o:value("3", translate("Every Wednesday"))
o:value("4", translate("Every Thursday"))
o:value("5", translate("Every Friday"))
o:value("6", translate("Every Saturday"))
o:value("7", translate("Every Sunday"))
o.default = "*"

update_time = s:option(ListValue, "rule_update_day_time", translate("Update Time"))
for t = 0, 23 do
    update_time:value(t, t..":00")
end
update_time.default = 0

data_update = s:option(Button, "rule_update", translate("Rule Update"))
data_update.rawhtml = true
data_update.template = "coredns/rule_update"


s = m:section(TypedSection, "coredns_clear_log", translate("Clear Logs"))
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "log_auto_clear", translate("Enable Auto Clear"))
enable.rmempty = false

clear_hour = s:option(ListValue, "log_clear_hour", translate("Clear Cycle"))
for t = 1, 24 do
    clear_hour:value(t, translate("Every") .. " " .. t .. " " .. translate("hours"))
end
clear_hour.default = 12

return m
