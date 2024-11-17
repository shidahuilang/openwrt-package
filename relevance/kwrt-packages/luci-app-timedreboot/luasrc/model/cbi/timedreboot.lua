require("luci.sys")

m=Map("timedreboot",translate("Timed Reboot"),translate("Timed Reboot Setting. <a href=\"https://github.com/kongfl888/luci-app-timedreboot\">Github</a>"))

s=m:section(TypedSection,"main","")
s.addremove=false
s.anonymous=true

enable=s:option(Flag,"enable",translate("Enable"))
enable.rmempty = false
enable.default=0

hour=s:option(Value,"hour",translate("Hour"))
hour.datatype = "range(0,23)"
hour.rmempty = false

minute=s:option(Value,"minute",translate("Minute"))
minute.datatype = "range(0,59)"
minute.rmempty = false

week=s:option(ListValue,"week",translate("Week Day"))
week:value(7,translate("Everyday"))
week:value(1,translate("Monday"))
week:value(2,translate("Tuesday"))
week:value(3,translate("Wednesday"))
week:value(4,translate("Thursday"))
week:value(5,translate("Friday"))
week:value(6,translate("Saturday"))
week:value(0,translate("Sunday"))
week:value(8,translate("Someday"))
week.default=6

day=s:option(Value,"sday",translate("Days of month"),translate("You also can use like this: 2,8,16 or 5-15."))
day.default=15
day.rmempty = true
day:depends("week",8)

once=s:option(Flag,"once",translate("Only once"))
once.rmempty = false
once.default=0

return m
