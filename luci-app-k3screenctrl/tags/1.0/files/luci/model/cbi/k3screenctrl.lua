-- Copyright (C) 2017 XiaoShan https://www.mivm.cn

local m, s ,o
m = Map("k3screenctrl", translate("Screen"), translate("Customize your device screen"))

s = m:section(TypedSection, "general", translate("General Setting") ,translate("If it does not take effect immediately, please reboot the system."))
s.anonymous = true

o = s:option(ListValue, "screen_time", translate("Screen time :"), translate("This time no action, the screen will close."))
o:value("10",translate("10 s"))
o:value("30",translate("30 s"))
o:value("60",translate("60 s"))
o:value("300",translate("5 m"))
o:value("600",translate("10 m"))
o:value("900",translate("15 m"))
o:value("1800",translate("30 m"))
o:value("3600",translate("60 m"))
o.default = 10
o.rmempty = false

o = s:option(ListValue, "refresh_time", translate("Refresh interval :"), translate("Screen refresh interval."))
o:value("2",translate("2 s"))
o:value("5",translate("5 s"))
o:value("10",translate("10 s"))
o.default = 2
o.rmempty = false

o = s:option(Flag, "pawd_hide", translate("Hide Wireless password"), translate("The fourth page of the wireless password."))
o.rmempty = false

o = s:option(Flag, "disp_cputemp", translate("Display CPU temperature"), translate("The first page shows the CPU temperature."))
o.rmempty = false

local apply = luci.http.formvalue("cbi.apply")
if apply then
	io.popen("/etc/init.d/k3screenctrl restart")
end

return m
