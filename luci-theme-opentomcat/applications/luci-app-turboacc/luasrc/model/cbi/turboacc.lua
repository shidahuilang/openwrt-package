local fs = require "nixio.fs"

local boardinfo = luci.util.ubus("system", "board") or {}
local m, s, o

m = Map("turboacc")
m.title	= translate("Turbo ACC Acceleration Settings")
m.description = translate("Opensource Flow Offloading driver (Fast Path or Hardware NAT)")

m:append(Template("turboacc/status"))

s = m:section(TypedSection, "turboacc", "")
s.addremove = false
s.anonymous = true

if fs.access("/lib/modules/" .. boardinfo.kernel .. "/xt_FLOWOFFLOAD.ko") then
	o = s:option(Flag, "sw_flow", translate("Software flow offloading"))
	o.default = 0
	o.description = translate("Software based offloading for routing/NAT")
	o:depends("sfe_flow", 0)

	if boardinfo.release.target:match("(mt762[0-9])$") then
		o = s:option(Flag, "hw_flow", translate("Hardware flow offloading"))
		o.default = 0
		o.description = translate("Requires hardware NAT support. Implemented at least for mt762x")
		o:depends("sw_flow", 1)
	end
end

if fs.access("/lib/modules/" .. boardinfo.kernel .. "/fast-classifier.ko") then
	o = s:option(Flag, "sfe_flow", translate("Shortcut-FE flow offloading"))
	o.default = 0
	o.description = translate("Shortcut-FE based offloading for routing/NAT")
	o:depends("sw_flow", 0)

	o = s:option(Flag, "sfe_bridge", translate("Bridge Acceleration"))
	o.default = 0
	o.description = translate("Enable Bridge Acceleration (may be functional conflict with bridge-mode VPN server)")
	o:depends("sfe_flow", 1)

	if fs.access("/proc/sys/net/ipv6") then
		o = s:option(Flag, "sfe_ipv6", translate("IPv6 Acceleration"))
		o.default = 0
		o.description = translate("Enable IPv6 Acceleration")
		o:depends("sfe_flow", 1)
	end
end

if fs.access("/lib/modules/" .. boardinfo.kernel .. "/tcp_bbr.ko") then
	o = s:option(Flag, "bbr_cca", translate("BBR CCA"))
	o.default = 0
	o.description = translate("Using BBR CCA can improve TCP network performance effectively")
end 

if fs.access("/lib/modules/" .. boardinfo.kernel .. "/xt_FULLCONENAT.ko") then
	o = s:option(Flag, "fullcone_nat", translate("FullCone NAT"))
	o.default = 0
	o.description = translate("Using FullCone NAT can improve gaming performance effectively")
end 

o = s:option(Flag, "dns_caching", translate("DNS Caching"))
o.default = 0
o.rmempty = false
o.description = translate("Enable DNS Caching and anti ISP DNS pollution")

o = s:option(ListValue, "dns_caching_mode", translate("Resolve DNS Mode"), translate("DNS Program"))
o:value("1", translate("Using PDNSD to query and cache"))
if fs.access("/usr/bin/dnsforwarder") then
	o:value("2", translate("Using DNSForwarder to query and cache"))
end
if fs.access("/usr/bin/dnsproxy") then
	o:value("3", translate("Using DNSProxy to query and cache"))
end
o.default = 1
o:depends("dns_caching", 1)

o = s:option(Value, "dns_caching_dns", translate("Upsteam DNS Server"))
o.default = "114.114.114.114,114.114.115.115,223.5.5.5,223.6.6.6,180.76.76.76,119.29.29.29,119.28.28.28,1.2.4.8,210.2.4.8"
o.description = translate("Muitiple DNS server can saperate with ','")
o:depends("dns_caching", 1)

return m
