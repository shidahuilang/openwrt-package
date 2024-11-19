--[[
LuCI - Lua Configuration Interface

Copyright 2015 Aleksandr Kolesnik <neryba@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0
]]--

local map, section, net = ...

local apn, service, pincode, username, password
local ipv6, maxwait, defaultroute, metric, peerdns, dns,
      keepalive_failure, keepalive_interval, demand

apn = section:taboption("general", Value, "apn", translate("APN"))


pincode = section:taboption("general", Value, "pincode", translate("PIN"))


username = section:taboption("general", Value, "username", translate("PAP/CHAP username"))


password = section:taboption("general", Value, "password", translate("PAP/CHAP password"))
password.password = true


if luci.model.network:has_ipv6() then

 ipv6 = section:taboption("advanced", Flag, "ipv6",
 translate("Enable IPv6 negotiation on the PPP link"))

 ipv6.default = ipv6.disabled
 ipv6.rmempty = false

end


maxwait = section:taboption("advanced", Value, "maxwait",
 translate("Modem init timeout"),
 translate("Maximum amount of seconds to wait for the modem to become ready"))

maxwait.placeholder = "20"
maxwait.datatype    = "min(1)"


defaultroute = section:taboption("advanced", Flag, "defaultroute",
 translate("Use default gateway"),
 translate("If unchecked, no default route is configured"))

defaultroute.default = defaultroute.enabled


metric = section:taboption("advanced", Value, "metric",
 translate("Use gateway metric"))

metric.placeholder = "0"
metric.datatype    = "uinteger"
metric:depends("defaultroute", defaultroute.enabled)


peerdns = section:taboption("advanced", Flag, "peerdns",
 translate("Use DNS servers advertised by peer"),
 translate("If unchecked, the advertised DNS server addresses are ignored"))

peerdns.default = peerdns.enabled


dns = section:taboption("advanced", DynamicList, "dns",
 translate("Use custom DNS servers"))

dns:depends("peerdns", "")
dns.datatype = "ipaddr"
dns.cast     = "string"


keepalive_failure = section:taboption("advanced", Value, "_keepalive_failure",
 translate("LCP echo failure threshold"),
 translate("Presume peer to be dead after given amount of LCP echo failures, use 0 to ignore failures"))

function keepalive_failure.cfgvalue(self, section)
 local v = m:get(section, "keepalive")
 if v and #v > 0 then
 return tonumber(v:match("^(%d+)[ ,]+%d+") or v)
 end
end

function keepalive_failure.write() end
function keepalive_failure.remove() end

keepalive_failure.placeholder = "0"
keepalive_failure.datatype    = "uinteger"


keepalive_interval = section:taboption("advanced", Value, "_keepalive_interval",
 translate("LCP echo interval"),
 translate("Send LCP echo requests at the given interval in seconds, only effective in conjunction with failure threshold"))

function keepalive_interval.cfgvalue(self, section)
 local v = m:get(section, "keepalive")
 if v and #v > 0 then
 return tonumber(v:match("^%d+[ ,]+(%d+)"))
 end
end

function keepalive_interval.write(self, section, value)
 local f = tonumber(keepalive_failure:formvalue(section)) or 0
 local i = tonumber(value) or 5
 if i < 1 then i = 1 end
 if f > 0 then
 m:set(section, "keepalive", "%d %d" %{ f, i })
 else
 m:del(section, "keepalive")
 end
end

keepalive_interval.remove      = keepalive_interval.write
keepalive_interval.placeholder = "5"
keepalive_interval.datatype    = "min(1)"


demand = section:taboption("advanced", Value, "demand",
 translate("Inactivity timeout"),
 translate("Close inactive connection after the given amount of seconds, use 0 to persist connection"))

demand.placeholder = "0"
demand.datatype    = "uinteger"
