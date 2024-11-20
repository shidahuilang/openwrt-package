local m, s, o

m = Map("gpioled")
m.title = translate("GPIO LED Settings")
m.description = translate("Customize device GPIO LED behavior.<br><br>"..
"1. Internet Detector: Functions for detect whether internet is running or not.<br>" ..
"2. Application Detector: Functions for detect whether desired application is running or not with a notification using IR Blaster LED.<br>"..
"3. Power LED: Function for set Power LED blink mode.<br>"..
[[<br/><br/><a href="https://github.com/animegasan" target="_blank">Powered by animegasan</a>]])

--- global
s = m:section(TypedSection, "global", translate("Global Setting"))
s.addremove = false
s.anonymous = true
---- status
o = s:option(DummyValue, "status", translate("Internet Detector"))
o.template = "gpioled/id-status"
o.value = translate("Collecting data...")
o = s:option(DummyValue, "status", translate("Application Detector"))
o.template = "gpioled/ad-status"
o.value = translate("Collecting data...")
o = s:option(DummyValue, "status", translate("Power LED Blink Mode"))
o.template = "gpioled/pwr-status"
o.value = translate("Collecting data...")
---- enable
o = s:option(MultiValue, "enable", translate("Enable Service"))
o:value("id",translate("Internet Detector"))
o:value("ad",translate("Application Detector"))
o.widget = "checkbox"
o.default = nil
---- device
o = s:option(ListValue, "device", translate("Device"))
o:value("HG680PR1", translate("HG680P RAM 1GB"))
o:value("HG680PR2", translate("HG680P RAM 2GB"))
o.default = nil
--- service
s = m:section(TypedSection, "service", translate("Service Setting"))
s.addremove = false
s.anonymous = true
--- internet detector service
s:tab("id", translate("Internet Detector"))
---- color led on
o = s:taboption("id", ListValue, "id_il", translate("Internet On"),
    translate("LED color when internet is running"))
o:value("green", translate("Green"))
o:value("red", translate("Red"))
o:value("yellow", translate("Yellow"))
o.default = "green"
---- color led off
o = s:taboption("id", ListValue, "id_io", translate("Internet Off"),
    translate("LED color when internet is not running"))
o:value("green", translate("Green"))
o:value("red", translate("Red"))
o:value("yellow", translate("Yellow"))
o.default = "red"
---- mode
o = s:taboption("id", ListValue, "id_mode", translate("Blink Mode"))
o:value("0.1", translate("Fast"))
o:value("1", translate("Normal"))
o:value("2", translate("Slow"))
o:value("0", translate("Static"))
o.default = "1"
--- application detector service
s:tab("ad", translate("Application Detector"))
---- application
o = s:taboption("ad", ListValue, "ad_app", translate("Application"),
    translate("Application want to monitoring"))
o:value("cloudflared.config.enabled", translate("Cloudflare"))
o:value("openclash.config.enabled", translate("OpenClash"))
o:value("zerotier.sample_config.enabled", translate("ZeroTier"))
o.default = nil
---- status application
o = s:taboption("ad", DummyValue, "status", translate("Status"), translate("Status of application being monitored"))
o.template = "gpioled/ad-mon"
o.value = translate("Collecting data...")
---- mode
o = s:taboption("ad", ListValue, "ad_mode", translate("Blink Mode"))
o:value("0.1", translate("Fast"))
o:value("1", translate("Normal"))
o:value("2", translate("Slow"))
o:value("0", translate("Static"))
o.default = "1"
--- power led
s:tab("pwr", translate("Power LED"))
---- color
o = s:taboption("pwr", ListValue, "pwr_color", translate("LED Color"))
o:value("green", translate("Green"))
o:value("red", translate("Red"))
o:value("yellow", translate("Yellow"))
o.default = "green"
---- mode
o = s:taboption("pwr", ListValue, "pwr_mode", translate("Blink Mode"))
o:value("0.1", translate("Fast"))
o:value("1", translate("Normal"))
o:value("2", translate("Slow"))
o:value("0", translate("Static"))
o.default = "0"

m.apply_on_parse = true
m.on_after_apply = function(map)
    luci.sys.exec("/etc/init.d/gpioled restart")
end

return m
