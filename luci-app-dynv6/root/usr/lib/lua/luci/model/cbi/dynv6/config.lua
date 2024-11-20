m = Map("dynv6", translate("Dynv6"), translate("Dynv6 ddns script for luci (powerd by luochongjun@gl-inet.com)"));

s = m:section(TypedSection, "site", translate("Site")); s.addremove = true;
v1 = s:option(Flag, "enabled", translate("Enable")); v1.optional=false; v1.rmempty = false;
v2 = s:option(Value, "token", translate("Token")); v2.optional=false; v2.rmempty = false;
v3 = s:option(Value, "zone", translate("Zone")); v3.optional=false; v3.rmempty = false;
v4 = s:option(Value, "interval", translate("Interval")); v4.optional=false; v4.rmempty = false; v4.default = "60";
l = s:option(Value, "interface", translate("Interface")); l.optional=false; l.rmempty = false;
l:value("any")
l.default = "any"
local uci = require "luci.model.uci"
local _uci = uci.cursor()
_uci:foreach("network", "interface",
        function(s)
                if s['.name'] ~= "loopback" and s['.name'] ~= "lan"  then
                        l:value(s['.name'],s['.name'])
                end
        end)                                       
return m