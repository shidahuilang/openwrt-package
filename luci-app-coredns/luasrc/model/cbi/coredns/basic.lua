local api = require "luci.coredns.api"
local fs   = require "nixio.fs"
local sys  = require "luci.sys"

if fs.access("/usr/share/coredns/coredns") then
    coredns_version = sys.exec("/usr/share/coredns/coredns -version")
else
    coredns_version = translate("Unknown Version, Pleaes upload a valid CoreDNS program.")
end

m = Map("coredns")
m.title = "CoreDNS"
m.description = coredns_version

m:section(SimpleSection).template = "coredns/coredns_status"

s = m:section(TypedSection, "coredns", translate("Basic Options"), translate("Please refer to") .. " <a href='https://coredns.io/' target='_blank'>https://coredns.io/</a>.")
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enabled"))

o = s:option(ListValue, "configfile", translate("Config File"))
o:value("/usr/share/coredns/Corefile", translate("Default Config"))
o:value("/usr/share/coredns/Corefile_custom", translate("Custom Config"))
o.default = "/usr/share/coredns/Corefile"

o = s:option(Value, "listen_port", translate("Listen port"))
o.datatype = "and(port,min(1))"
o.default = 5336

o = s:option(Flag, "redirect", translate("DNSMASQ Forward"), translate("Forward Dnsmasq Domain Name resolution requests to CoreDNS"))
o.default = false

o = s:option(Flag, "enabled_log", translate("Enable Log"))
o.default = true
o:depends("configfile", "/usr/share/coredns/Corefile")

o = s:option(Flag, "enabled_cache", translate("Enable Cache"), translate("Please do NOT enable cache when working with OpenClash, AdguardHome"))
o.default = false
o:depends("configfile", "/usr/share/coredns/Corefile")

o = s:option(Flag, "disable_ipv6", translate("Disable IPv6"))
o.default = false
o:depends("configfile", "/usr/share/coredns/Corefile")

o = s:option(DynamicList, "dns", translate("Default DNS"), translate("Upstream DNS server"))
o:value("119.29.29.29", "119.29.29.29 (DNSPod Primary)")
o:value("119.28.28.28", "119.28.28.28 (DNSPod Secondary)")
o:value("223.5.5.5", "223.5.5.5 (AliDNS Primary)")
o:value("223.6.6.6", "223.6.6.6 (AliDNS Secondary)")
o:value("114.114.114.114", "114.114.114.114 (114DNS Primary)")
o:value("114.114.115.115", "114.114.115.115 (114DNS Secondary)")
o:value("180.76.76.76", "180.76.76.76 (Baidu DNS)")
o:value("tls://149.112.112.112", "149.112.112.112 (Quad9 DNS)")
o:value("tls://45.11.45.11", "45.11.45.11 (DNS.SB)")
o:value("tls://208.67.222.222", "208.67.222.222 (Open DNS)")
o:value("tls://208.67.220.220", "208.67.220.220 (Open DNS)")
o:value("tls://1.1.1.1", "1.1.1.1 (CloudFlare DNS)")
o:value("tls://1.0.0.1", "1.0.0.1 (CloudFlare DNS)")
o:value("tls://8.8.8.8", "8.8.8.8 (Google DNS)")
o:value("tls://8.8.4.4", "8.8.4.4 (Google DNS)")
o:value("tls://9.9.9.9", "9.9.9.9 (Quad9 DNS)")
o:depends("configfile", "/usr/share/coredns/Corefile")
o.default = "119.29.29.29"

o = s:option(ListValue, "policy", translate("Policy"))
o:value("random", translate("Randomly select a healthy upstream host"))
o:value("round_robin", translate("Select a healthy upstream host in round robin order"))
o:value("sequential", translate("Select a healthy upstream host in sequential order"))
o.default = "random"
o:depends("configfile", "/usr/share/coredns/Corefile")

o = s:option(DynamicList, "bootstrap_dns", translate("Bootstrap DNS servers"), translate("Bootstrap DNS servers are used to resolve IP addresses of the DoH/DoT resolvers you specify as upstreams"))
o:value("119.29.29.29", "119.29.29.29 (DNSPod Primary)")
o:value("119.28.28.28", "119.28.28.28 (DNSPod Secondary)")
o:value("223.5.5.5", "223.5.5.5 (AliDNS Primary)")
o:value("223.6.6.6", "223.6.6.6 (AliDNS Secondary)")
o:value("114.114.114.114", "114.114.114.114 (114DNS Primary)")
o:value("114.114.115.115", "114.114.115.115 (114DNS Secondary)")
o:value("180.76.76.76", "180.76.76.76 (Baidu DNS)")
o:depends("configfile", "/usr/share/coredns/Corefile")
o.rmempty = true

o = s:option(Value, "path_reload", translate("Path Reload"),translate("changes the reload interval between each path in FROM, Default is 2s, minimal is 1s"))
o.default = "2s"
o:depends("configfile", "/usr/share/coredns/Corefile")

o = s:option(Value, "expire", translate("Expire"), translate("will expire (cached) connections after this time interval, Default is 15s, minimal is 1s"))
o.default = "15s"
o:depends("configfile", "/usr/share/coredns/Corefile")

o = s:option(Value, "max_fails", translate("Max Fails"), translate("is the maximum number of consecutive health checking failures that are needed before considering an upstream as down. 0 to disable this feature(which the upstream will never be marked as down), Default is 3"))
o.default = "3"
o.datatype = "range(0, 10)"
o:depends("configfile", "/usr/share/coredns/Corefile")

o = s:option(Value, "health_check", translate("Health Check"), translate("configure the behaviour of health checking of the upstream hosts, Default is 2s, minimal is 1s"))

o.default = "2s"
o:depends("configfile", "/usr/share/coredns/Corefile")

-- o = s:option(Button, "_reload", translate("Reload Service"), translate("Reload service to take effect of new configuration"))
-- o.write = function()
--     sys.exec("/etc/init.d/coredns reload")
-- end
-- o:depends("configfile", "/usr/share/coredns/Corefile_custom")

o = s:option(TextValue, "manual-config")
o.description = translate("Edit the custom Corefile in above textarea as you own need")
o.template = "cbi/tvalue"
o.rows = 25
o:depends("configfile", "/usr/share/coredns/Corefile_custom")

function o.cfgvalue(self, section)
    return fs.readfile("/usr/share/coredns/Corefile_custom")
end

function o.write(self, section, value)
    value = value:gsub("\r\n?", "\n")
    fs.writefile("/usr/share/coredns/Corefile_custom", value)
end

return m
