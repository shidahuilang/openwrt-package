local api = require "luci.coredns.api"
local fs   = require "nixio.fs"
local sys  = require "luci.sys"

m = Map("coredns")
m.redirect = api.url("rule_list")

s = m:section(NamedSection, arg[1], "","DNS " .. translate("Redir Rule") .. " - " .. translate("Subscribe"))
s.addremove = false
s.dynamic = false

o = s:option(Value, "name", translate("Name"))
o.rmempty = false
o.optional = false

o = s:option(Value, "url", translate("Subscribe URL"))
o.rmempty = false
o.optional = false
local str = translate("Please refer to") .. "<a href='https://github.com/leiless/dnsredir' target='_blank'>https://github.com/leiless/dnsredir</a>"
str = str .. "<br> - " .. translate("DOMAIN, which the whole line is the domain name")
str = str .. "<br> - " .. translate("server=/DOMAIN/DNS, which is the format of dnsmasq config file, note that only the DOMAIN will be honored, other fields will be simply discarded")
str = str .. "<br> - " .. translate("Text after # character will be treated as comment")
str = str .. "<br> - " .. translate("Unparsable lines(including whitespace-only line) are therefore just ignored")
o.description = translate(str)

function o.validate(self, value)
    result = string.match(value, '[a-z]*://[^ >,;]*')
	if result == true then
		return true;
	else
		return nil, translate("Please input a valid Subscribe URL!")
	end
end

o = s:option(Value, "file", translate("File"), translate("Path") .. ":/usr/share/coredns/")
o.rmempty = false
o.optional = false
o.default = arg[1] .. ".conf"
function o.write(self, section, value)
	luci.sys.call("lua /usr/share/coredns/update_rule.lua " .. arg[1] .. " > /dev/null 2>&1 &")
	-- luci.http.redirect(api.url("log"))
end

o = s:option(DynamicList, "dns", translate("DNS"))
o.rmempty = false
o.optional = false
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
o.default="119.29.29.29"

o = s:option(ListValue, "policy", translate("Policy"))
o.rmempty = false
o.optional = false
o:value("random", translate("Randomly select a healthy upstream host"))
o:value("round_robin", translate("Select a healthy upstream host in round robin order"))
o:value("sequential", translate("Select a healthy upstream host in sequential order"))
o.default = "random"

o = s:option(DynamicList, "bootstrap_dns", translate("Bootstrap DNS servers"), translate("Bootstrap DNS servers are used to resolve IP addresses of the DoH/DoT resolvers you specify as upstreams"))
o.rmempty = true
-- o.optional = true
o:value("119.29.29.29", "119.29.29.29 (DNSPod Primary)")
o:value("119.28.28.28", "119.28.28.28 (DNSPod Secondary)")
o:value("223.5.5.5", "223.5.5.5 (AliDNS Primary)")
o:value("223.6.6.6", "223.6.6.6 (AliDNS Secondary)")
o:value("114.114.114.114", "114.114.114.114 (114DNS Primary)")
o:value("114.114.115.115", "114.114.115.115 (114DNS Secondary)")
o:value("180.76.76.76", "180.76.76.76 (Baidu DNS)")

o = s:option(Value, "path_reload", translate("Path Reload"),translate("changes the reload interval between each path in FROM, Default is 2s, minimal is 1s"))
o.rmempty = false
o.optional = false
o.default = "2s"

o = s:option(Value, "expire", translate("Expire"), translate("will expire (cached) connections after this time interval, Default is 15s, minimal is 1s"))
o.rmempty = false
o.optional = false
o.default = "15s"

o = s:option(Value, "max_fails", translate("Max Fails"), translate("is the maximum number of consecutive health checking failures that are needed before considering an upstream as down. 0 to disable this feature(which the upstream will never be marked as down), Default is 3"))
o.default = "3"

o = s:option(Value, "health_check", translate("Health Check"), translate("configure the behaviour of health checking of the upstream hosts, Default is 2s, minimal is 1s"))
o.rmempty = false
o.optional = false
o.default = "2s"

return m
