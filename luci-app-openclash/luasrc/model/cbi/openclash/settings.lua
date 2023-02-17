
local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local fs = require "luci.openclash"
local uci = require "luci.model.uci".cursor()
local json = require "luci.jsonc"

font_green = [[<b style=color:green>]]
font_red = [[<b style=color:red>]]
font_off = [[</b>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]

local op_mode = string.sub(luci.sys.exec('uci get openclash.config.operation_mode 2>/dev/null'),0,-2)
if not op_mode then op_mode = "redir-host" end
local lan_ip = SYS.exec("uci -q get network.lan.ipaddr |awk -F '/' '{print $1}' 2>/dev/null |tr -d '\n' || ip address show $(uci -q -p /tmp/state get network.lan.ifname || uci -q -p /tmp/state get network.lan.device) | grep -w 'inet'  2>/dev/null |grep -Eo 'inet [0-9\.]+' | awk '{print $2}' | tr -d '\n' || ip addr show 2>/dev/null | grep -w 'inet' | grep 'global' | grep 'brd' | grep -Eo 'inet [0-9\.]+' | awk '{print $2}' | head -n 1 | tr -d '\n'")

m = Map("openclash", translate("Global Settings(Will Modify The Config File Or Subscribe According To The Settings On This Page)"))
m.pageaction = false
m.description = translate("Note: To restore the default configuration, try accessing:").." <a href='javascript:void(0)' onclick='javascript:restore_config(this)'>http://"..lan_ip.."/cgi-bin/luci/admin/services/openclash/restore</a>"..
"<br/>"..translate("Note: It is not recommended to enable IPv6 and related services for routing. Most of the network connection problems reported so far are related to it")..
"<br/>"..font_green..translate("Note: Turning on secure DNS in the browser will cause abnormal shunting, please be careful to turn it off")..font_off..
"<br/>"..font_green..translate("Note: Some software will modify the device HOSTS, which will cause abnormal shunt, please pay attention to check")..font_off..
"<br/>"..font_green..translate("Note: Game proxy please use nodes except Vmess")..font_off..
"<br/>"..translate("Note: The default proxy routes local traffic, BT, PT download, etc., please use redir mode as much as possible and pay attention to traffic avoidance")..
"<br/>"..translate("Note: If the connection is abnormal, please follow the steps on this page to check first")..": ".."<a href='javascript:void(0)' onclick='javascript:return winOpen(\"https://github.com/vernesong/OpenClash/wiki/%E7%BD%91%E7%BB%9C%E8%BF%9E%E6%8E%A5%E5%BC%82%E5%B8%B8%E6%97%B6%E6%8E%92%E6%9F%A5%E5%8E%9F%E5%9B%A0\")'>"..translate("Click to the page").."</a>"

s = m:section(TypedSection, "openclash")
s.anonymous = true

s:tab("op_mode", translate("Operation Mode"))
s:tab("settings", translate("General Settings"))
s:tab("dns", "DNS "..translate("Settings"))
s:tab("meta", translate("Meta Settings"))
s:tab("stream_enhance", translate("Streaming Enhance"))
s:tab("lan_ac", translate("Access Control"))
if op_mode == "fake-ip" then
s:tab("rules", translate("Rules Setting(Access Control)"))
else
s:tab("rules", translate("Rules Setting"))
end
s:tab("dashboard", translate("Dashboard Settings"))
s:tab("ipv6", translate("IPv6 Settings"))
s:tab("rules_update", translate("Rules Update"))
s:tab("geo_update", translate("GEO Update"))
s:tab("chnr_update", translate("Chnroute Update"))
s:tab("auto_restart", translate("Auto Restart"))
s:tab("version_update", translate("Version Update"))
s:tab("developer", translate("Developer Settings"))
s:tab("debug", translate("Debug Logs"))
s:tab("dlercloud", translate("Dler Cloud"))

o = s:taboption("op_mode", ListValue, "en_mode", font_red..bold_on..translate("Select Mode")..bold_off..font_off)
o.description = translate("Select Mode For OpenClash Work, Try Flush DNS Cache If Network Error")
if op_mode == "redir-host" then
o:value("redir-host", translate("redir-host"))
o:value("redir-host-tun", translate("redir-host(tun mode)"))
o:value("redir-host-mix", translate("redir-host-mix(tun mix mode)"))
o.default = "redir-host"
else
o:value("fake-ip", translate("fake-ip"))
o:value("fake-ip-tun", translate("fake-ip(tun mode)"))
o:value("fake-ip-mix", translate("fake-ip-mix(tun mix mode)"))
o.default = "fake-ip"
end

o = s:taboption("op_mode", Flag, "enable_udp_proxy", font_red..bold_on..translate("Proxy UDP Traffics")..bold_off..font_off)
o.description = translate("The Servers Must Support UDP forwarding").."<br>"..font_red..bold_on.."1."..translate("If Docker is Installed, UDP May Not Forward Normally").."<br>2."..translate("In Fake-ip Mode, Even If This Option is Turned Off, Domain Type Connections Still Pass Through The Core For The Availability")..bold_off..font_off
o:depends("en_mode", "redir-host")
o:depends("en_mode", "fake-ip")
o.default = 1

o = s:taboption("op_mode", ListValue, "stack_type", translate("Select Stack Type"))
o.description = translate("Select Stack Type For TUN Mode, According To The Running Speed on Your Machine")
o:depends("en_mode", "redir-host-tun")
o:depends("en_mode", "fake-ip-tun")
o:depends("en_mode", "redir-host-mix")
o:depends("en_mode", "fake-ip-mix")
o:value("system", translate("System　"))
o:value("gvisor", translate("Gvisor"))
o.default = "system"

o = s:taboption("op_mode", ListValue, "proxy_mode", font_red..bold_on..translate("Proxy Mode")..bold_off..font_off)
o.description = translate("Select Proxy Mode, Use Script Mode Could Prevent Proxy BT traffics If Rules Support, eg.lhie1's")
o:value("rule", translate("Rule Proxy Mode"))
o:value("global", translate("Global Proxy Mode"))
o:value("direct", translate("Direct Proxy Mode"))
o:value("script", translate("Script Proxy Mode (Tun Core Only)"))
o.default = "rule"

o = s:taboption("op_mode", Flag, "router_self_proxy", font_red..bold_on..translate("Router-Self Proxy")..bold_off..font_off)
o.description = translate("Only Supported for Rule Mode")..", "..font_red..bold_on..translate("ALL Functions In Stream Enhance Tag Will Not Work After Disable")..bold_off..font_off
o.default = 1
o:depends("proxy_mode", "rule")

o = s:taboption("op_mode", Flag, "disable_udp_quic", font_red..bold_on..translate("Disable QUIC")..bold_off..font_off)
o.description = translate("Prevent YouTube and Others To Use QUIC Transmission")..", "..font_red..bold_on..translate("REJECT UDP Traffic(Not Include CN) On Port 443")..bold_off..font_off
o.default = 1

o = s:taboption("op_mode", Flag, "enable_rule_proxy", font_red..bold_on..translate("Rule Match Proxy Mode")..bold_off..font_off)
o.description = translate("Only Proxy Rules Match, Prevent BT/P2P Passing")
o.default = 0

o = s:taboption("op_mode", Flag, "common_ports", font_red..bold_on..translate("Common Ports Proxy Mode")..bold_off..font_off)
o.description = translate("Only Common Ports, Prevent BT/P2P Passing")
o.default = 0
o:depends("en_mode", "redir-host")
o:depends("en_mode", "redir-host-tun")
o:depends("en_mode", "redir-host-mix")

if op_mode == "redir-host" then
	o = s:taboption("op_mode", Flag, "china_ip_route", translate("China IP Route"))
	o.description = translate("Bypass The China Network Flows, Improve Performance")
	o.default = 0
else
	o = s:taboption("op_mode", Flag, "china_ip_route", translate("China IP Route"))
	o.description = translate("Bypass The China Network Flows, Improve Performance, Depend on Dnsmasq")
	o.default = 0
	o:depends("enable_redirect_dns", "1")

	o = s:taboption("op_mode", Value, "custom_china_domain_dns_server", translate("Specify CN DNS Server"))
	o.description = translate("Specify DNS Server For CN Domain Lists, Only One IP Server Address Support")
	o.default = "114.114.114.114"
	o.placeholder = translate("114.114.114.114 or 127.0.0.1#5300")
	o:depends("china_ip_route", "1")
end

o = s:taboption("op_mode", Flag, "intranet_allowed", translate("Only intranet allowed"))
o.description = translate("When Enabled, The Control Panel And The Connection Broker Port Will Not Be Accessible From The Public Network")
o.default = 1

o = s:taboption("op_mode", Flag, "bypass_gateway_compatible", translate("Bypass Gateway Compatible"))
o.description = translate("If The Network Cannot be Connected in Bypass Gateway Mode, Please Try to Enable.")..font_red..bold_on..translate("Suggestion: If The Device Does Not Have WLAN, Please Disable The Lan Interface's Bridge Option")..bold_off..font_off
o.default = 0

o = s:taboption("op_mode", Flag, "small_flash_memory", translate("Small Flash Memory"))
o.description = translate("Move Core And GEOIP Data File To /tmp/etc/openclash For Small Flash Memory Device")
o.default = 0

---- Operation Mode
switch_mode = s:taboption("op_mode", DummyValue, "", nil)
switch_mode.template = "openclash/switch_mode"

---- General Settings
o = s:taboption("settings", ListValue, "interface_name", font_red..bold_on..translate("Bind Network Interface")..bold_off..font_off)
local de_int = SYS.exec("ip route |grep 'default' |awk '{print $5}' 2>/dev/null") or SYS.exec("/usr/share/openclash/openclash_get_network.lua 'dhcp'")
o.description = translate("Default Interface Name:").." "..font_green..bold_on..de_int..bold_off..font_off..translate(",Try Enable If Network Loopback")
local interfaces = SYS.exec("ls -l /sys/class/net/ 2>/dev/null |awk '{print $9}' 2>/dev/null")
for interface in string.gmatch(interfaces, "%S+") do
   o:value(interface)
end
o:value("0", translate("Disable"))
o.default = "0"

o = s:taboption("settings", Value, "tolerance", font_red..bold_on..translate("Url-Test Group Tolerance (ms)")..bold_off..font_off)
o.description = translate("Switch To The New Proxy When The Delay Difference Between Old and The Fastest Currently is Greater Than This Value")
o:value("0", translate("Disable"))
o:value("100")
o:value("150")
o.datatype = "uinteger"
o.default = "0"

o = s:taboption("settings", Value, "github_address_mod", font_red..bold_on..translate("Github Address Modify")..bold_off..font_off)
o.description = translate("Modify The Github Address In The Config And OpenClash With Proxy(CDN) To Prevent File Download Faild. Format Reference:").." ".."<a href='javascript:void(0)' onclick='javascript:return winOpen(\"https://ghproxy.com/\")'>https://ghproxy.com/</a>"
o:value("0", translate("Disable"))
o:value("https://fastly.jsdelivr.net/")
o:value("https://testingcf.jsdelivr.net/")
o:value("https://raw.fastgit.org/")
o:value("https://cdn.jsdelivr.net/")
o.default = "0"

o = s:taboption("settings", Value, "urltest_address_mod", translate("Url-Test Address Modify"))
o.description = translate("Modify The Url-Test Address In The Config")
o:value("0", translate("Disable"))
o:value("http://www.gstatic.com/generate_204")
o:value("http://cp.cloudflare.com/generate_204")
o:value("https://cp.cloudflare.com/generate_204")
o:value("http://captive.apple.com/generate_204")
o.default = "0"

o = s:taboption("settings", Value, "delay_start", translate("Delay Start (s)"))
o.description = translate("Delay Start On Boot")
o.default = "0"
o.datatype = "uinteger"

o = s:taboption("settings", ListValue, "log_level", translate("Log Level"))
o.description = translate("Select Core's Log Level")
o:value("info", translate("Info Mode"))
o:value("warning", translate("Warning Mode"))
o:value("error", translate("Error Mode"))
o:value("debug", translate("Debug Mode"))
o:value("silent", translate("Silent Mode"))
o.default = "silent"

o = s:taboption("settings", Value, "log_size", translate("Log Size (KB)"))
o.description = translate("Set Log File Size (KB)")
o.default = "1024"

o = s:taboption("settings", Value, "dns_port")
o.title = translate("DNS Port")
o.default = "7874"
o.datatype = "port"
o.rmempty = false
o.description = translate("Please Make Sure Ports Available")

o = s:taboption("settings", Value, "proxy_port")
o.title = translate("Redir Port")
o.default = "7892"
o.datatype = "port"
o.rmempty = false
o.description = translate("Please Make Sure Ports Available")

o = s:taboption("settings", Value, "tproxy_port")
o.title = translate("TProxy Port")
o.default = "7895"
o.datatype = "port"
o.rmempty = false
o.description = translate("Please Make Sure Ports Available")

o = s:taboption("settings", Value, "http_port")
o.title = translate("HTTP(S) Port")
o.default = "7890"
o.datatype = "port"
o.rmempty = false
o.description = translate("Please Make Sure Ports Available")

o = s:taboption("settings", Value, "socks_port")
o.title = translate("SOCKS5 Port")
o.default = "7891"
o.datatype = "port"
o.rmempty = false
o.description = translate("Please Make Sure Ports Available")

o = s:taboption("settings", Value, "mixed_port")
o.title = translate("Mixed Port")
o.default = "7893"
o.datatype = "port"
o.rmempty = false
o.description = translate("Please Make Sure Ports Available")

---- DNS Settings
o = s:taboption("dns", ListValue, "enable_redirect_dns", font_red..bold_on..translate("Redirect Local DNS Setting")..bold_off..font_off)
o.description = translate("Set Local DNS Redirect")
o.default = 1
o:value("0", translate("Disable"))
o:value("1", translate("Dnsmasq Redirect"))
o:value("2", translate("Firewall Redirect"))

o = s:taboption("dns", Flag, "enable_custom_dns", font_red..bold_on..translate("Custom DNS Setting")..bold_off..font_off)
o.description = font_red..bold_on..translate("Set OpenClash Upstream DNS Resolve Server")..bold_off..font_off
o.default = 0

o = s:taboption("dns", Flag, "append_wan_dns", translate("Append Upstream DNS"))
o.description = translate("Append The Upstream Assigned DNS And Gateway IP To The Nameserver")
o.default = 1

o = s:taboption("dns", Flag, "append_default_dns", translate("Append Default DNS"))
o.description = translate("Automatically Append Compliant DNS to default-nameserver")
o.default = 1

if op_mode == "fake-ip" then
o = s:taboption("dns", Value, "fakeip_range", translate("Fake-IP Range (IPv4 Cidr)"))
o.description = translate("Set Fake-IP Range (IPv4 Cidr)")
o.datatype = "cidr4"
o.default = "198.18.0.1/16"
o.placeholder = "198.18.0.1/16"

o = s:taboption("dns", Flag, "store_fakeip", font_red..bold_on..translate("Persistence Fake-IP")..bold_off..font_off)
o.description = font_red..bold_on..translate("Cache Fake-IP DNS Resolution Records To File, Improve The Response Speed After Startup")..bold_off..font_off
o.default = 1

o = s:taboption("dns", DummyValue, "flush_fakeip_cache", translate("Flush Fake-IP Cache"))
o.template = "openclash/flush_fakeip_cache"
end

o = s:taboption("dns", Flag, "disable_masq_cache", translate("Disable Dnsmasq's DNS Cache"))
o.description = translate("Recommended Enabled For Avoiding Some Connection Errors")..font_red..bold_on..translate("(Maybe Incompatible For Your Firmware)")..bold_off..font_off
o.default = 0
o:depends("enable_redirect_dns", "1")

o = s:taboption("dns", Flag, "custom_fallback_filter", translate("Custom Fallback-Filter"))
o.description = translate("Take Effect If Fallback DNS Setted, Prevent DNS Pollution")
o.default = 0

custom_fallback_filter = s:taboption("dns", Value, "custom_fallback_fil")
custom_fallback_filter.template = "cbi/tvalue"
custom_fallback_filter.rows = 20
custom_fallback_filter.wrap = "off"
custom_fallback_filter:depends("custom_fallback_filter", "1")

function custom_fallback_filter.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_fallback_filter.yaml") or ""
end
function custom_fallback_filter.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_fallback_filter.yaml")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_fallback_filter.yaml", value)
		end
	end
end

o = s:taboption("dns", Flag, "dns_advanced_setting", translate("Advanced Setting"))
o.description = translate("DNS Advanced Settings")..font_red..bold_on..translate("(Please Don't Modify it at Will)")..bold_off..font_off
o.default = 0

if op_mode == "fake-ip" then

custom_fake_black = s:taboption("dns", Value, "custom_fake_filter")
custom_fake_black.template = "cbi/tvalue"
custom_fake_black.description = translate("Domain Names In The List Do Not Return Fake-IP, One rule per line")
custom_fake_black.rows = 20
custom_fake_black.wrap = "off"
custom_fake_black:depends("dns_advanced_setting", "1")

function custom_fake_black.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_fake_filter.list") or ""
end
function custom_fake_black.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_fake_filter.list")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_fake_filter.list", value)
		end
	end
end
end

o = s:taboption("dns", Value, "custom_domain_dns_server", translate("Specify DNS Server"))
o.description = translate("Specify DNS Server For List and Server Nodes With Fake-IP Mode, Only One IP Server Address Support")
o.default = "114.114.114.114"
o.placeholder = translate("114.114.114.114 or 127.0.0.1#5300")
o:depends({dns_advanced_setting = "1", enable_redirect_dns = "1"})

custom_domain_dns = s:taboption("dns", Value, "custom_domain_dns")
custom_domain_dns.template = "cbi/tvalue"
custom_domain_dns.description = translate("Domain Names In The List Use The Custom DNS Server, One rule per line, Depend on Dnsmasq")
custom_domain_dns.rows = 20
custom_domain_dns.wrap = "off"
custom_domain_dns:depends({dns_advanced_setting = "1", enable_redirect_dns = "1"})

function custom_domain_dns.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_domain_dns.list") or ""
end
function custom_domain_dns.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_domain_dns.list")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_domain_dns.list", value)
		end
	end
end

custom_domain_dns_policy = s:taboption("dns", Value, "custom_domain_dns_core")
custom_domain_dns_policy.template = "cbi/tvalue"
custom_domain_dns_policy.description = translate("Domain Names In The List Use The Custom DNS Server, But Still Return Fake-IP Results, One rule per line")
custom_domain_dns_policy.rows = 20
custom_domain_dns_policy.wrap = "off"
custom_domain_dns_policy:depends("dns_advanced_setting", "1")

function custom_domain_dns_policy.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_domain_dns_policy.list") or ""
end
function custom_domain_dns_policy.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_domain_dns_policy.list")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_domain_dns_policy.list", value)
		end
	end
end

-- Meta
o = s:taboption("meta", Flag, "enable_meta_core", font_red..bold_on..translate("Enable Meta Core")..bold_off..font_off)
o.description = font_red..bold_on..translate("Some Premium Core Features are Unavailable, For Other More Useful Functions Go Wiki:")..bold_off..font_off.." ".."<a href='javascript:void(0)' onclick='javascript:return winOpen(\"https://clashmeta.gitbook.io/meta/\")'>https://clashmeta.gitbook.io/meta/</a>"
o.default = 0

o = s:taboption("meta", Flag, "enable_tcp_concurrent", font_red..bold_on..translate("Enable Tcp Concurrent")..bold_off..font_off)
o.description = font_red..bold_on..translate("TCP Concurrent Request IPs, Choose The Lowest Latency One To Connection")..bold_off..font_off
o.default = 1
o:depends("enable_meta_core", "1")

o = s:taboption("meta", ListValue, "find_process_mode", translate("Enable Process Rule"))
o.description = translate("Whether to Enable Process Rules, If You Are Not Sure, Please Choose off Which Useful in Router Environment")
o:value("always")
o:value("strict")
o:value("off", translate("off　"))
o.default = "off"
o:depends("enable_meta_core", "1")

o = s:taboption("meta", ListValue, "global_client_fingerprint", translate("Client Fingerprint"))
o.description = translate("Change The Client Fingerprint, Only Support TLS Transport in TCP/GRPC/WS/HTTP For Vless/Vmess and Trojan")
o:value("none", translate("None"))
o:value("random", translate("Random"))
o:value("chrome", translate("Chrome"))
o:value("firefox", translate("Firefox"))
o:value("safari", translate("Safari"))
o:value("ios", translate("IOS"))
o.default = "none"
o:depends("enable_meta_core", "1")

o = s:taboption("meta", Flag, "enable_meta_sniffer", font_red..bold_on..translate("Enable Sniffer")..bold_off..font_off)
o.description = font_red..bold_on..translate("Sniffer Will Prevent Domain Name Proxy and DNS Hijack Failure")..bold_off..font_off
o.default = 1
o:depends("enable_meta_core", "1")

o = s:taboption("meta", Flag, "enable_meta_sniffer_pure_ip", translate("Forced Sniff Pure IP"))
o.description = translate("Forced Sniff Pure IP Connections")
o.default = 1
o:depends("enable_meta_sniffer", "1")

o = s:taboption("meta", Flag, "enable_meta_sniffer_custom", translate("Custom Sniffer Settings"))
o.description = translate("Custom The Force and Skip Sniffing Doamin Lists")
o.default = 0
o:depends("enable_meta_sniffer", "1")

sniffing_domain_force = s:taboption("meta", Value, "sniffing_domain_force", translate("Force Sniffing Domains Lists"))
sniffing_domain_force:depends("enable_meta_sniffer_custom", "1")
sniffing_domain_force.template = "cbi/tvalue"
sniffing_domain_force.description = translate("Will Override Dns Queries If Domains in The List")
sniffing_domain_force.rows = 20
sniffing_domain_force.wrap = "off"

function sniffing_domain_force.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_force_sniffing_domain.yaml") or ""
end
function sniffing_domain_force.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_force_sniffing_domain.yaml")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_force_sniffing_domain.yaml", value)
		end
	end
end

sniffing_port_filter = s:taboption("meta", Value, "sniffing_port_filter", translate("Sniffing Ports Filter"))
sniffing_port_filter:depends("enable_meta_sniffer_custom", "1")
sniffing_port_filter.template = "cbi/tvalue"
sniffing_port_filter.description = translate("Will Only Sniffing If Ports in The List")
sniffing_port_filter.rows = 20
sniffing_port_filter.wrap = "off"

function sniffing_port_filter.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_sniffing_ports_filter.yaml") or ""
end
function sniffing_port_filter.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_sniffing_ports_filter.yaml")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_sniffing_ports_filter.yaml", value)
		end
	end
end

sniffing_domain_filter = s:taboption("meta", Value, "sniffing_domain_filter", translate("Force Sniffing Domains(sni) Filter"))
sniffing_domain_filter:depends("enable_meta_sniffer_custom", "1")
sniffing_domain_filter.template = "cbi/tvalue"
sniffing_domain_filter.description = translate("Will Disable Sniffing If Domains(sni) in The List")
sniffing_domain_filter.rows = 20
sniffing_domain_filter.wrap = "off"

function sniffing_domain_filter.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_sniffing_domain_filter.yaml") or ""
end
function sniffing_domain_filter.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_sniffing_domain_filter.yaml")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_sniffing_domain_filter.yaml", value)
		end
	end
end

o = s:taboption("meta", ListValue, "geodata_loader", translate("Geodata Loader Mode"))
o:value("memconservative", translate("Memconservative"))
o:value("standard", translate("Standard"))
o.default = "memconservative"
o:depends("enable_meta_core", "1")

o = s:taboption("meta", Flag, "enable_geoip_dat", translate("Enable GeoIP Dat"))
o.description = translate("Replace GEOIP MMDB With GEOIP Dat, Large Size File")..", "..font_red..bold_on..translate("Need Download First")..bold_off..font_off
o.default = 0
o:depends("enable_meta_core", "1")

o = s:taboption("meta", Flag, "geoip_auto_update", translate("Auto Update GeoIP Dat"))
o.default = 0
o:depends("enable_geoip_dat", "1")

o = s:taboption("meta", ListValue, "geoip_update_week_time", translate("Update Time (Every Week)"))
o:value("*", translate("Every Day"))
o:value("1", translate("Every Monday"))
o:value("2", translate("Every Tuesday"))
o:value("3", translate("Every Wednesday"))
o:value("4", translate("Every Thursday"))
o:value("5", translate("Every Friday"))
o:value("6", translate("Every Saturday"))
o:value("0", translate("Every Sunday"))
o.default = "1"
o:depends("geoip_auto_update", "1")

o = s:taboption("meta", ListValue, "geoip_update_day_time", translate("Update time (every day)"))
for t = 0,23 do
o:value(t, t..":00")
end
o.default = "0"
o:depends("geoip_auto_update", "1")

o = s:taboption("meta", Value, "geoip_custom_url")
o.title = translate("Custom GeoIP Dat URL")
o.rmempty = true
o.description = translate("Custom GeoIP Dat URL, Click Button Below To Refresh After Edit")
o:value("https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat", translate("Loyalsoldier-testingcf-jsdelivr-Version")..translate("(Default)"))
o:value("https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat", translate("Loyalsoldier-fastly-jsdelivr-Version"))
o:value("https://ftp.jaist.ac.jp/pub/sourceforge.jp/storage/g/v/v2/v2raya/dists/v2ray-rules-dat/geoip.dat", translate("OSDN-Version")..translate("(Default)"))
o.default = "https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat"
o:depends("geoip_auto_update", "1")

o = s:taboption("meta", Button, translate("GEOIP Dat Update")) 
o.title = translate("Update GeoIP Dat")
o.inputtitle = translate("Check And Update")
o.inputstyle = "reload"
o.write = function()
  m.uci:set("openclash", "config", "enable", 1)
  m.uci:commit("openclash")
  SYS.call("/usr/share/openclash/openclash_geoip.sh >/dev/null 2>&1 &")
  HTTP.redirect(DISP.build_url("admin", "services", "openclash"))
end
o:depends("geoip_auto_update", "1")

o = s:taboption("meta", Flag, "geosite_auto_update", translate("Auto Update GeoSite Database"))
o.default = 0
o:depends("enable_meta_core", "1")

o = s:taboption("meta", ListValue, "geosite_update_week_time", translate("Update Time (Every Week)"))
o:value("*", translate("Every Day"))
o:value("1", translate("Every Monday"))
o:value("2", translate("Every Tuesday"))
o:value("3", translate("Every Wednesday"))
o:value("4", translate("Every Thursday"))
o:value("5", translate("Every Friday"))
o:value("6", translate("Every Saturday"))
o:value("0", translate("Every Sunday"))
o.default = "1"
o:depends("geosite_auto_update", "1")

o = s:taboption("meta", ListValue, "geosite_update_day_time", translate("Update time (every day)"))
for t = 0,23 do
o:value(t, t..":00")
end
o.default = "0"
o:depends("geosite_auto_update", "1")

o = s:taboption("meta", Value, "geosite_custom_url")
o.title = translate("Custom GeoSite URL")
o.rmempty = true
o.description = translate("Custom GeoSite Data URL, Click Button Below To Refresh After Edit")
o:value("https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat", translate("Loyalsoldier-testingcf-jsdelivr-Version")..translate("(Default)"))
o:value("https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat", translate("Loyalsoldier-fastly-jsdelivr-Version"))
o:value("https://ftp.jaist.ac.jp/pub/sourceforge.jp/storage/g/v/v2/v2raya/dists/v2ray-rules-dat/geosite.dat", translate("OSDN-Version")..translate("(Default)"))
o.default = "https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat"
o:depends("geosite_auto_update", "1")

o = s:taboption("meta", Button, translate("GEOSITE Update")) 
o.title = translate("Update GeoSite Database")
o.inputtitle = translate("Check And Update")
o.inputstyle = "reload"
o.write = function()
  m.uci:set("openclash", "config", "enable", 1)
  m.uci:commit("openclash")
  SYS.call("/usr/share/openclash/openclash_geosite.sh >/dev/null 2>&1 &")
  HTTP.redirect(DISP.build_url("admin", "services", "openclash"))
end
o:depends("geosite_auto_update", "1")

---- Access Control
o = s:taboption("lan_ac", ListValue, "lan_ac_mode", translate("LAN Access Control Mode"))
o:value("0", translate("Black List Mode"))
o:value("1", translate("White List Mode"))
o.default = "0"
o:depends("enable_redirect_dns", "2")
o:depends("en_mode", "redir-host")
o:depends("en_mode", "redir-host-tun")
o:depends("en_mode", "redir-host-mix")

ip_b = s:taboption("lan_ac", DynamicList, "lan_ac_black_ips", translate("LAN Bypassed Host List"))
ip_b.datatype = "ipaddr"
ip_b:depends({lan_ac_mode = "0", enable_redirect_dns = "2"})
ip_b:depends({lan_ac_mode = "0", en_mode = "redir-host"})
ip_b:depends({lan_ac_mode = "0", en_mode = "redir-host-tun"})
ip_b:depends({lan_ac_mode = "0", en_mode = "redir-host-mix"})

mac_b = s:taboption("lan_ac", DynamicList, "lan_ac_black_macs", translate("LAN Bypassed Mac List"))
mac_b.datatype = "list(macaddr)"
mac_b.rmempty  = true
mac_b:depends("lan_ac_mode", "0")

ip_w = s:taboption("lan_ac", DynamicList, "lan_ac_white_ips", translate("LAN Proxied Host List"))
ip_w.datatype = "ipaddr"
ip_w:depends({lan_ac_mode = "1", enable_redirect_dns = "2"})
ip_w:depends({lan_ac_mode = "1", en_mode = "redir-host"})
ip_w:depends({lan_ac_mode = "1", en_mode = "redir-host-tun"})
ip_w:depends({lan_ac_mode = "1", en_mode = "redir-host-mix"})

mac_w = s:taboption("lan_ac", DynamicList, "lan_ac_white_macs", translate("LAN Proxied Mac List"))
mac_w.datatype = "list(macaddr)"
mac_w.rmempty  = true
mac_w:depends("lan_ac_mode", "1")

luci.ip.neighbors({ family = 4 }, function(n)
	if n.mac and n.dest then
		ip_b:value(n.dest:string())
		ip_w:value(n.dest:string())
		mac_b:value(n.mac, "%s (%s)" %{ n.mac, n.dest:string() })
		mac_w:value(n.mac, "%s (%s)" %{ n.mac, n.dest:string() })
	end
end)

if string.len(SYS.exec("/usr/share/openclash/openclash_get_network.lua 'gateway6'")) ~= 0 then
luci.ip.neighbors({ family = 6 }, function(n)
	if n.mac and n.dest then
		ip_b:value(n.dest:string())
		ip_w:value(n.dest:string())
		mac_b:value(n.mac, "%s (%s)" %{ n.mac, n.dest:string() })
		mac_w:value(n.mac, "%s (%s)" %{ n.mac, n.dest:string() })
	end
end)
end

o = s:taboption("lan_ac", DynamicList, "wan_ac_black_ips", translate("WAN Bypassed Host List"))
o.datatype = "ipaddr"
o.description = translate("In The Fake-IP Mode, Only Pure IP Requests Are Supported")

o = s:taboption("lan_ac", DynamicList, "lan_ac_black_ports", translate("Lan Bypassed Port List"))
o.datatype = "port"
o.placeholder = translate("5000 or 1234-2345")
o:value("5000", translate("5000(NAS)"))
o.description = "1."..translate("The Traffic From The Local Specified Port Will Not Pass The Core, Try To Set When The Bypass Gateway Forwarding Fails").."<br>".."2."..translate("In The Fake-IP Mode, Only Pure IP Requests Are Supported")

o = s:taboption("lan_ac", Value, "local_network_pass", translate("Local IPv4 Network Bypassed List"))
o.template = "cbi/tvalue"
o.description = translate("The Traffic of The Destination For The Specified Address Will Not Pass The Core")
o.rows = 20
o.wrap = "off"

function o.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_localnetwork_ipv4.list") or ""
end
function o.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_localnetwork_ipv4.list")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_localnetwork_ipv4.list", value)
		end
	end
end

o = s:taboption("lan_ac", Value, "chnroute_pass", translate("Chnroute Bypassed List"))
o.template = "cbi/tvalue"
o.description = translate("Domains or IPs in The List Will Not be Affected by The China IP Route Option, Depend on Dnsmasq")
o.rows = 20
o.wrap = "off"
o:depends("enable_redirect_dns", "1")

function o.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_chnroute_pass.list") or ""
end
function o.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_chnroute_pass.list")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_chnroute_pass.list", value)
		end
	end
end

---- Rules Settings
o = s:taboption("rules", Flag, "rule_source", translate("Enable Other Rules"))
o.description = translate("Use Other Rules")
o.default = 0

if op_mode == "fake-ip" then
o = s:taboption("rules", Flag, "enable_custom_clash_rules", font_red..bold_on..translate("Custom Clash Rules(Access Control)")..bold_off..font_off)
else
o = s:taboption("rules", Flag, "enable_custom_clash_rules", font_red..bold_on..translate("Custom Clash Rules")..bold_off..font_off)
end
o.description = translate("Use Custom Rules")
o.default = 0

custom_rules = s:taboption("rules", Value, "custom_rules")
custom_rules:depends("enable_custom_clash_rules", 1)
custom_rules.template = "cbi/tvalue"
custom_rules.description = translate("Custom Priority Rules Here, For More Go:").." ".."<a href='javascript:void(0)' onclick='javascript:return winOpen(\"https://lancellc.gitbook.io/clash/clash-config-file/rules\")'>https://lancellc.gitbook.io/clash/clash-config-file/rules</a>".." ,"..translate("IP To CIDR:").." ".."<a href='javascript:void(0)' onclick='javascript:return winOpen(\"http://ip2cidr.com\")'>http://ip2cidr.com</a>"
custom_rules.rows = 20
custom_rules.wrap = "off"

function custom_rules.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_rules.list") or ""
end
function custom_rules.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_rules.list")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_rules.list", value)
		end
	end
end

custom_rules_2 = s:taboption("rules", Value, "custom_rules_2")
custom_rules_2:depends("enable_custom_clash_rules", 1)
custom_rules_2.template = "cbi/tvalue"
custom_rules_2.description = translate("Custom Extended Rules Here, For More Go:").." ".."<a href='javascript:void(0)' onclick='javascript:return winOpen(\"https://lancellc.gitbook.io/clash/clash-config-file/rules\")'>https://lancellc.gitbook.io/clash/clash-config-file/rules</a>".." ,"..translate("IP To CIDR:").." ".."<a href='javascript:void(0)' onclick='javascript:return winOpen(\"http://ip2cidr.com\")'>http://ip2cidr.com</a>"
custom_rules_2.rows = 20
custom_rules_2.wrap = "off"

function custom_rules_2.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_rules_2.list") or ""
end
function custom_rules_2.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_rules_2.list")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_rules_2.list", value)
		end
	end
end

--Stream Enhance
se_dns_ip = s:taboption("stream_enhance", DynamicList, "lan_block_google_dns_ips", font_red..bold_on..translate("LAN Block Google DNS IP List")..bold_off..font_off)
se_dns_ip:depends("proxy_mode", "global")
se_dns_ip:depends("proxy_mode", "direct")
se_dns_ip:depends("proxy_mode", "script")
se_dns_ip:depends({router_self_proxy = "1", proxy_mode = "rule"})
se_dns_ip.datatype = "ipaddr"
se_dns_ip.rmempty  = true

se_dns_mac = s:taboption("stream_enhance", DynamicList, "lan_block_google_dns_macs", font_red..bold_on..translate("LAN Block Google DNS Mac List")..bold_off..font_off)
se_dns_mac.datatype = "list(macaddr)"
se_dns_mac.rmempty  = true
se_dns_mac:depends("proxy_mode", "global")
se_dns_mac:depends("proxy_mode", "direct")
se_dns_mac:depends("proxy_mode", "script")
se_dns_mac:depends({router_self_proxy = "1", proxy_mode = "rule"})

luci.ip.neighbors({ family = 4 }, function(n)
	if n.mac and n.dest then
		se_dns_ip:value(n.dest:string())
		se_dns_mac:value(n.mac, "%s (%s)" %{ n.mac, n.dest:string() })
	end
end)

if string.len(SYS.exec("/usr/share/openclash/openclash_get_network.lua 'gateway6'")) ~= 0 then
luci.ip.neighbors({ family = 6 }, function(n)
	if n.mac and n.dest then
		se_dns_ip:value(n.dest:string())
		se_dns_mac:value(n.mac, "%s (%s)" %{ n.mac, n.dest:string() })
	end
end)
end

o = s:taboption("stream_enhance", Flag, "stream_domains_prefetch", font_red..bold_on..translate("Prefetch Netflix, Disney Plus Domains")..bold_off..font_off)
o.description = translate("Prevent Some Devices From Directly Using IP Access To Cause Unlocking Failure, Recommend Use meta Sniffer Function")
o.default = 0
o:depends({router_self_proxy = "1", proxy_mode = "rule"})
o:depends("proxy_mode", "global")
o:depends("proxy_mode", "direct")
o:depends("proxy_mode", "script")

o = s:taboption("stream_enhance", Value, "stream_domains_prefetch_interval", translate("Domains Prefetch Interval(min)"))
o.default = "1440"
o.datatype = "uinteger"
o.description = translate("Will Run Once Immediately After Started, The Interval Does Not Need To Be Too Short (Take Effect Immediately After Commit)")
o:depends("stream_domains_prefetch", "1")

o = s:taboption("stream_enhance", DummyValue, "stream_domains_update", translate("Update Preset Domains List"))
o:depends("stream_domains_prefetch", "1")
o.template = "openclash/download_stream_domains"

o = s:taboption("stream_enhance", Flag, "stream_auto_select", font_red..bold_on..translate("Auto Select Unlock Proxy")..bold_off..font_off)
o.description = translate("Auto Select Proxy For Streaming Unlock, Support Netflix, Disney Plus, HBO And YouTube Premium, etc")
o.default = 0
o:depends({router_self_proxy = "1", proxy_mode = "rule"})
o:depends("proxy_mode", "global")
o:depends("proxy_mode", "direct")
o:depends("proxy_mode", "script")

o = s:taboption("stream_enhance", Value, "stream_auto_select_interval", translate("Auto Select Interval(min)"))
o.default = "30"
o.datatype = "uinteger"
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", ListValue, "stream_auto_select_logic", font_red..bold_on..translate("Auto Select Logic")..bold_off..font_off)
o.default = "urltest"
o:value("urltest", translate("Urltest"))
o:value("random", translate("Random"))
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Flag, "stream_auto_select_expand_group", font_red..bold_on..translate("Expand Group")..bold_off..font_off)
o.description = translate("Automatically Expand The Group When Selected")
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Flag, "stream_auto_select_close_con", translate("Close Old Connections"))
o.description = translate("Automatically Close Old Connections When New Unlock Node Selected")
o.default = 1
o:depends("stream_auto_select", "1")

--Netflix
o = s:taboption("stream_enhance", Flag, "stream_auto_select_netflix", font_red..translate("Netflix")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_netflix", translate("Group Filter"))
o.default = "Netflix|奈飞"
o.placeholder = "Netflix|奈飞"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_netflix", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_netflix", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "HK|SG|TW"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_netflix", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_netflix") then
		fs.unlink("/tmp/openclash_Netflix_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_netflix", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_netflix", "1")

o = s:taboption("stream_enhance", DummyValue, "Netflix", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "Netflix"
o:depends("stream_auto_select_netflix", "1")

--Disney Plus
o = s:taboption("stream_enhance", Flag, "stream_auto_select_disney", font_red..translate("Disney Plus")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_disney", translate("Group Filter"))
o.default = "Disney|迪士尼"
o.placeholder = "Disney|迪士尼"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_disney", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_disney", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "HK|SG|TW"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_disney", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_disney") then
		fs.unlink("/tmp/openclash_Disney Plus_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_disney", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_disney", "1")

o = s:taboption("stream_enhance", DummyValue, "Disney Plus", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "Disney Plus"
o:depends("stream_auto_select_disney", "1")

--YouTube Premium
o = s:taboption("stream_enhance", Flag, "stream_auto_select_ytb", font_red..translate("YouTube Premium")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_ytb", translate("Group Filter"))
o.default = "YouTube|油管"
o.placeholder = "YouTube|油管"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_ytb", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_ytb", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "HK|US"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_ytb", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_ytb") then
		fs.unlink("/tmp/openclash_YouTube Premium_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_ytb", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_ytb", "1")

o = s:taboption("stream_enhance", DummyValue, "YouTube Premium", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "YouTube Premium"
o:depends("stream_auto_select_ytb", "1")

--Amazon Prime Video
o = s:taboption("stream_enhance", Flag, "stream_auto_select_prime_video", font_red..translate("Amazon Prime Video")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_prime_video", translate("Group Filter"))
o.default = "Amazon|Prime Video"
o.placeholder = "Amazon|Prime Video"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_prime_video", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_prime_video", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "HK|US|SG"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_prime_video", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_prime_video") then
		fs.unlink("/tmp/openclash_Amazon Prime Video_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_prime_video", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_prime_video", "1")

o = s:taboption("stream_enhance", DummyValue, "Amazon Prime Video", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "Amazon Prime Video"
o:depends("stream_auto_select_prime_video", "1")

--HBO Now
o = s:taboption("stream_enhance", Flag, "stream_auto_select_hbo_now", font_red..translate("HBO Now")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_hbo_now", translate("Group Filter"))
o.default = "HBO|HBONow|HBO Now"
o.placeholder = "HBO|HBONow|HBO Now"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_hbo_now", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_hbo_now", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_hbo_now", "1")

o = s:taboption("stream_enhance", DummyValue, "HBO Now", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "HBO Now"
o:depends("stream_auto_select_hbo_now", "1")

--HBO Max
o = s:taboption("stream_enhance", Flag, "stream_auto_select_hbo_max", font_red..translate("HBO Max")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_hbo_max", translate("Group Filter"))
o.default = "HBO|HBOMax|HBO Max"
o.placeholder = "HBO|HBOMax|HBO Max"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_hbo_max", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_hbo_max", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "US"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_hbo_max", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_hbo_max") then
		fs.unlink("/tmp/openclash_HBO Max_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_hbo_max", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_hbo_max", "1")

o = s:taboption("stream_enhance", DummyValue, "HBO Max", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "HBO Max"
o:depends("stream_auto_select_hbo_max", "1")

--HBO GO Asia
o = s:taboption("stream_enhance", Flag, "stream_auto_select_hbo_go_asia", font_red..translate("HBO GO Asia")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_hbo_go_asia", translate("Group Filter"))
o.default = "HBO|HBOGO|HBO GO"
o.placeholder = "HBO|HBOGO|HBO GO"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_hbo_go_asia", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_hbo_go_asia", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "HK|SG|TW"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_hbo_go_asia", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_hbo_go_asia") then
		fs.unlink("/tmp/openclash_HBO GO Asia_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_hbo_go_asia", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_hbo_go_asia", "1")

o = s:taboption("stream_enhance", DummyValue, "HBO GO Asia", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "HBO GO Asia"
o:depends("stream_auto_select_hbo_go_asia", "1")

--TVB Anywhere+
o = s:taboption("stream_enhance", Flag, "stream_auto_select_tvb_anywhere", font_red..translate("TVB Anywhere+")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_tvb_anywhere", translate("Group Filter"))
o.default = "TVB"
o.placeholder = "TVB"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_tvb_anywhere", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_tvb_anywhere", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "HK|SG|TW"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_tvb_anywhere", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_tvb_anywhere") then
		fs.unlink("/tmp/openclash_TVB Anywhere+_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_tvb_anywhere", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_tvb_anywhere", "1")

o = s:taboption("stream_enhance", DummyValue, "TVB Anywhere+", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "TVB Anywhere+"
o:depends("stream_auto_select_tvb_anywhere", "1")

--DAZN
o = s:taboption("stream_enhance", Flag, "stream_auto_select_dazn", font_red..translate("DAZN")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_dazn", translate("Group Filter"))
o.default = "DAZN"
o.placeholder = "DAZN"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_dazn", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_dazn", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "DE"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_dazn", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_dazn") then
		fs.unlink("/tmp/openclash_DAZN_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_dazn", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_dazn", "1")

o = s:taboption("stream_enhance", DummyValue, "DAZN", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "DAZN"
o:depends("stream_auto_select_dazn", "1")

--Paramount Plus
o = s:taboption("stream_enhance", Flag, "stream_auto_select_paramount_plus", font_red..translate("Paramount Plus")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_paramount_plus", translate("Group Filter"))
o.default = "Paramount"
o.placeholder = "Paramount"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_paramount_plus", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_paramount_plus", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "US"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_paramount_plus", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_paramount_plus") then
		fs.unlink("/tmp/openclash_Paramount Plus_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_paramount_plus", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_paramount_plus", "1")

o = s:taboption("stream_enhance", DummyValue, "Paramount Plus", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "Paramount Plus"
o:depends("stream_auto_select_paramount_plus", "1")

--Discovery Plus
o = s:taboption("stream_enhance", Flag, "stream_auto_select_discovery_plus", font_red..translate("Discovery Plus")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_discovery_plus", translate("Group Filter"))
o.default = "Discovery"
o.placeholder = "Discovery"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_discovery_plus", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_region_key_discovery_plus", translate("Unlock Region Filter"))
o.default = ""
o.placeholder = "US"
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_discovery_plus", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_discovery_plus") then
		fs.unlink("/tmp/openclash_Discovery Plus_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_discovery_plus", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_discovery_plus", "1")

o = s:taboption("stream_enhance", DummyValue, "Discovery Plus", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "Discovery Plus"
o:depends("stream_auto_select_discovery_plus", "1")

--Bilibili
o = s:taboption("stream_enhance", Flag, "stream_auto_select_bilibili", font_red..translate("Bilibili")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_bilibili", translate("Group Filter"))
o.default = "Bilibili"
o.placeholder = "Bilibili"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_bilibili", "1")

o = s:taboption("stream_enhance", ListValue, "stream_auto_select_region_key_bilibili", translate("Unlock Region Filter"))
o.default = "CN"
o:value("CN", translate("China Mainland Only"))
o:value("HK/MO/TW", translate("Hongkong/Macau/Taiwan"))
o:value("TW", translate("Taiwan Only"))
o.description = translate("It Will Be Selected Region(Country Shortcode) According To The Regex")
o:depends("stream_auto_select_bilibili", "1")
function o.validate(self, value)
	if value ~= m.uci:get("openclash", "config", "stream_auto_select_region_key_bilibili") then
		fs.unlink("/tmp/openclash_Bilibili_region")
	end
	return value
end

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_bilibili", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_bilibili", "1")

o = s:taboption("stream_enhance", DummyValue, "Bilibili", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "Bilibili"
o:depends("stream_auto_select_bilibili", "1")

--Google not cn
o = s:taboption("stream_enhance", Flag, "stream_auto_select_google_not_cn", font_red..translate("Google Not CN")..font_off)
o.default = 0
o:depends("stream_auto_select", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_group_key_google_not_cn", translate("Group Filter"))
o.default = "Google"
o.placeholder = "Google"
o.description = translate("It Will Be Searched According To The Regex When Auto Search Group Fails")
o:depends("stream_auto_select_google_not_cn", "1")

o = s:taboption("stream_enhance", Value, "stream_auto_select_node_key_google_not_cn", translate("Unlock Nodes Filter"))
o.default = ""
o.description = translate("It Will Be Selected Nodes According To The Regex")
o:depends("stream_auto_select_google_not_cn", "1")

o = s:taboption("stream_enhance", DummyValue, "Google", translate("Manual Test"))
o.rawhtml = true
o.template = "openclash/other_stream_option"
o.value = "Google"
o:depends("stream_auto_select_google_not_cn", "1")

---- update Settings
o = s:taboption("rules_update", Flag, "other_rule_auto_update", translate("Auto Update"))
o.description = font_red..bold_on..translate("Auto Update Other Rules")..bold_off..font_off
o.default = 0

o = s:taboption("rules_update", ListValue, "other_rule_update_week_time", translate("Update Time (Every Week)"))
o:value("*", translate("Every Day"))
o:value("1", translate("Every Monday"))
o:value("2", translate("Every Tuesday"))
o:value("3", translate("Every Wednesday"))
o:value("4", translate("Every Thursday"))
o:value("5", translate("Every Friday"))
o:value("6", translate("Every Saturday"))
o:value("0", translate("Every Sunday"))
o.default = "1"

o = s:taboption("rules_update", ListValue, "other_rule_update_day_time", translate("Update time (every day)"))
for t = 0,23 do
o:value(t, t..":00")
end
o.default = "0"

o = s:taboption("rules_update", Button, translate("Other Rules Update")) 
o.title = translate("Update Other Rules")
o.inputtitle = translate("Check And Update")
o.description = translate("Other Rules Update(Only in Use)")
o.inputstyle = "reload"
o.write = function()
  m.uci:set("openclash", "config", "enable", 1)
  m.uci:commit("openclash")
  SYS.call("/usr/share/openclash/openclash_rule.sh >/dev/null 2>&1 &")
  HTTP.redirect(DISP.build_url("admin", "services", "openclash"))
end

o = s:taboption("geo_update", Flag, "geo_auto_update", translate("Auto Update"))
o.description = translate("Auto Update GEOIP Database")
o.default = 0
o:depends("enable_geoip_dat", 0)

o = s:taboption("geo_update", ListValue, "geo_update_week_time", translate("Update Time (Every Week)"))
o:value("*", translate("Every Day"))
o:value("1", translate("Every Monday"))
o:value("2", translate("Every Tuesday"))
o:value("3", translate("Every Wednesday"))
o:value("4", translate("Every Thursday"))
o:value("5", translate("Every Friday"))
o:value("6", translate("Every Saturday"))
o:value("0", translate("Every Sunday"))
o.default = "1"
o:depends("enable_geoip_dat", 0)

o = s:taboption("geo_update", ListValue, "geo_update_day_time", translate("Update time (every day)"))
for t = 0,23 do
o:value(t, t..":00")
end
o.default = "0"
o:depends("enable_geoip_dat", 0)

o = s:taboption("geo_update", Value, "geo_custom_url")
o.title = translate("Custom GEOIP URL")
o.rmempty = true
o.description = translate("Custom GEOIP Data URL, Click Button Below To Refresh After Edit")
o:value("https://testingcf.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/lite/Country.mmdb", translate("Alecthw-lite-Version")..translate("(Default mmdb)"))
o:value("https://testingcf.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/Country.mmdb", translate("Alecthw-Version")..translate("(All Info mmdb)"))
o:value("https://testingcf.jsdelivr.net/gh/Hackl0us/GeoIP2-CN@release/Country.mmdb", translate("Hackl0us-Version")..translate("(Only CN)"))
o:value("https://geolite.clash.dev/Country.mmdb", translate("Geolite.clash.dev"))
o.default = "http://www.ideame.top/mmdb/Country.mmdb"
o:depends("enable_geoip_dat", 0)

o = s:taboption("geo_update", Button, translate("GEOIP Update")) 
o.title = translate("Update GEOIP Database")
o.inputtitle = translate("Check And Update")
o.inputstyle = "reload"
o.write = function()
  m.uci:set("openclash", "config", "enable", 1)
  m.uci:commit("openclash")
  SYS.call("/usr/share/openclash/openclash_ipdb.sh >/dev/null 2>&1 &")
  HTTP.redirect(DISP.build_url("admin", "services", "openclash"))
end
o:depends("enable_geoip_dat", 0)

o = s:taboption("chnr_update", Flag, "chnr_auto_update", translate("Auto Update"))
o.description = translate("Auto Update Chnroute Lists")
o.default = 0

o = s:taboption("chnr_update", ListValue, "chnr_update_week_time", translate("Update Time (Every Week)"))
o:value("*", translate("Every Day"))
o:value("1", translate("Every Monday"))
o:value("2", translate("Every Tuesday"))
o:value("3", translate("Every Wednesday"))
o:value("4", translate("Every Thursday"))
o:value("5", translate("Every Friday"))
o:value("6", translate("Every Saturday"))
o:value("0", translate("Every Sunday"))
o.default = "1"

o = s:taboption("chnr_update", ListValue, "chnr_update_day_time", translate("Update time (every day)"))
for t = 0,23 do
o:value(t, t..":00")
end
o.default = "0"

o = s:taboption("chnr_update", Value, "chnr_custom_url")
o.title = translate("Custom Chnroute Lists URL")
o.rmempty = false
o.description = translate("Custom Chnroute Lists URL, Click Button Below To Refresh After Edit")
o:value("https://ispip.clang.cn/all_cn.txt", translate("Clang-CN")..translate("(Default)"))
o:value("https://ispip.clang.cn/all_cn_cidr.txt", translate("Clang-CN-CIDR"))
o:value("https://fastly.jsdelivr.net/gh/Hackl0us/GeoIP2-CN@release/CN-ip-cidr.txt", translate("Hackl0us-CN-CIDR-fastly-jsdelivr")..translate("(Large Size)"))
o:value("https://testingcf.jsdelivr.net/gh/Hackl0us/GeoIP2-CN@release/CN-ip-cidr.txt", translate("Hackl0us-CN-CIDR-testingcf-jsdelivr")..translate("(Large Size)"))
o.default = "https://ispip.clang.cn/all_cn.txt"

o = s:taboption("chnr_update", Value, "chnr6_custom_url")
o.title = translate("Custom Chnroute6 Lists URL")
o.rmempty = false
o.description = translate("Custom Chnroute6 Lists URL, Click Button Below To Refresh After Edit")
o:value("https://ispip.clang.cn/all_cn_ipv6.txt", translate("Clang-CN-IPV6")..translate("(Default)"))
o.default = "https://ispip.clang.cn/all_cn_ipv6.txt"

o = s:taboption("chnr_update", Value, "cndomain_custom_url")
o.title = translate("Custom CN Doamin Lists URL")
o.rmempty = false
o.description = translate("Custom CN Doamin Dnsmasq Conf URL, Click Button Below To Refresh After Edit")
o:value("https://testingcf.jsdelivr.net/gh/felixonmars/dnsmasq-china-list@master/accelerated-domains.china.conf", translate("dnsmasq-china-list-testingcf-jsdelivr")..translate("(Default)"))
o:value("https://fastly.jsdelivr.net/gh/felixonmars/dnsmasq-china-list@master/accelerated-domains.china.conf", translate("dnsmasq-china-list-fastly-jsdelivr"))
o:value("https://raw.fastgit.org/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf", translate("dnsmasq-china-list-fastgit"))
o:value("https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf", translate("dnsmasq-china-list-github"))
o.default = "https://testingcf.jsdelivr.net/gh/felixonmars/dnsmasq-china-list@master/accelerated-domains.china.conf"

o = s:taboption("chnr_update", Button, translate("Chnroute Lists Update")) 
o.title = translate("Update Chnroute Lists")
o.inputtitle = translate("Check And Update")
o.inputstyle = "reload"
o.write = function()
  m.uci:set("openclash", "config", "enable", 1)
  m.uci:commit("openclash")
  SYS.call("/usr/share/openclash/openclash_chnroute.sh >/dev/null 2>&1 &")
  HTTP.redirect(DISP.build_url("admin", "services", "openclash"))
end

o = s:taboption("auto_restart", Flag, "auto_restart", translate("Auto Restart"))
o.description = translate("Auto Restart OpenClash")
o.default = 0

o = s:taboption("auto_restart", ListValue, "auto_restart_week_time", translate("Restart Time (Every Week)"))
o:value("*", translate("Every Day"))
o:value("1", translate("Every Monday"))
o:value("2", translate("Every Tuesday"))
o:value("3", translate("Every Wednesday"))
o:value("4", translate("Every Thursday"))
o:value("5", translate("Every Friday"))
o:value("6", translate("Every Saturday"))
o:value("0", translate("Every Sunday"))
o.default = "1"

o = s:taboption("auto_restart", ListValue, "auto_restart_day_time", translate("Restart time (every day)"))
for t = 0,23 do
o:value(t, t..":00")
end
o.default = "0"

---- Dashboard Settings
local cn_port=SYS.exec("uci get openclash.config.cn_port 2>/dev/null |tr -d '\n'")
o = s:taboption("dashboard", Value, "cn_port")
o.title = translate("Dashboard Port")
o.default = "9090"
o.datatype = "port"
o.rmempty = false
o.description = translate("Dashboard Address Example:").." "..font_green..bold_on..lan_ip..':'..cn_port..'/ui/yacd'..'、'..lan_ip..':'..cn_port..'/ui/dashboard'..bold_off..font_off

o = s:taboption("dashboard", Value, "dashboard_password")
o.title = translate("Dashboard Secret")
o.rmempty = true
o.description = translate("Set Dashboard Secret")

o = s:taboption("dashboard", Value, "dashboard_forward_domain")
o.title = translate("Public Dashboard Address")
o.datatype = "or(host, string)"
o.placeholder = "example.com"
o.rmempty = true
o.description = translate("Domain Name For Dashboard Login From Public Network")

o = s:taboption("dashboard", Value, "dashboard_forward_port")
o.title = translate("Public Dashboard Port")
o.datatype = "port"
o.rmempty = true
o.description = translate("Port For Dashboard Login From Public Network")

o = s:taboption("dashboard", Flag, "dashboard_forward_ssl")
o.title = translate("Public Dashboard SSL enabled")
o.default = 0
o.description = translate("Is SSL enabled For Dashboard Login From Public Network")

o = s:taboption("dashboard", DummyValue, "Dashboard", translate("Switch(Update) Dashboard Version"))
o.template="openclash/switch_dashboard"
o.rawhtml = true

o = s:taboption("dashboard", DummyValue, "Yacd", translate("Switch(Update) Yacd Version"))
o.template="openclash/switch_dashboard"
o.rawhtml = true

---- ipv6
o = s:taboption("ipv6", Flag, "ipv6_enable", font_red..bold_on..translate("Proxy IPv6 Traffic")..bold_off..font_off)
o.description = font_red..bold_on..translate("The Gateway and DNS of The Connected Device Must be The Router IP, Disable IPv6 DHCP To Avoid Abnormal Connection If You Do Not Use")..bold_off..font_off
o.default = 0

o = s:taboption("ipv6", Flag, "ipv6_dns", translate("IPv6 DNS Resolve"))
o.description = translate("Enable to Resolve IPv6 DNS Requests")
o.default = 0

o = s:taboption("ipv6", Flag, "china_ip6_route", translate("China IPv6 Route"))
o.description = translate("Bypass The China Network Flows, Improve Performance")
o.default = 0
o:depends("ipv6_enable", "1")

o = s:taboption("ipv6", Value, "local_network6_pass", translate("Local IPv6 Network Bypassed List"))
o.template = "cbi/tvalue"
o.description = translate("The Traffic of The Destination For The Specified Address Will Not Pass The Core")
o.rows = 20
o.wrap = "off"
o:depends("ipv6_enable", "1")

function o.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_localnetwork_ipv6.list") or ""
end
function o.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_localnetwork_ipv6.list")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_localnetwork_ipv6.list", value)
		end
	end
end

o = s:taboption("ipv6", Value, "chnroute6_pass", translate("Chnroute6 Bypassed List"))
o.template = "cbi/tvalue"
o.description = translate("Domains or IPs in The List Will Not be Affected by The China IP Route Option, Depend on Dnsmasq")
o.rows = 20
o.wrap = "off"
o:depends({ipv6_enable = "1", enable_redirect_dns = "1"})

function o.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_chnroute6_pass.list") or ""
end
function o.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_chnroute6_pass.list")
		if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_chnroute6_pass.list", value)
		end
	end
end

---- version update
core_update = s:taboption("version_update", DummyValue, "", nil)
core_update.template = "openclash/update"

---- developer
o = s:taboption("developer", Value, "firewall_custom")
o.template = "cbi/tvalue"
o.description = translate("Custom Firewall Rules, Support IPv4 and IPv6, All Rules Will Be Added After The OpenClash Rules Completely")
o.rows = 30
o.wrap = "off"

function o.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_firewall_rules.sh") or ""
end
function o.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_firewall_rules.sh")
		if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_firewall_rules.sh", value)
		end
	end
end

o = s:taboption("developer", Value, "ymchange_custom")
o.template = "cbi/tvalue"
o.description = translate("Custom Config Override Script, Any Changes Will Be Restored After The Install of the OC, Please Be Careful, The Wrong Changes May Lead to Exceptions")
o.rows = 30
o.wrap = "off"

function o.cfgvalue(self, section)
	return NXFS.readfile("/usr/share/openclash/yml_change.sh") or ""
end
function o.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/usr/share/openclash/yml_change.sh")
		if value ~= old_value then
			NXFS.writefile("/usr/share/openclash/yml_change.sh", value)
		end
	end
end

o = s:taboption("developer", Button, translate("Restore Override Script"))
o.title = translate("Restore Override Script")
o.inputtitle = translate("Restore")
o.inputstyle = "reload"
o.write = function()
  SYS.call("cp /usr/share/openclash/backup/yml_change.sh /usr/share/openclash/yml_change.sh >/dev/null 2>&1")
  HTTP.redirect(DISP.build_url("admin", "services", "openclash", "settings"))
end

---- debug
o = s:taboption("debug", DummyValue, "", nil)
o.template = "openclash/debug"

---- dlercloud
o = s:taboption("dlercloud", Value, "dler_email")
o.title = translate("Account Email Address")
o.rmempty = true

o = s:taboption("dlercloud", Value, "dler_passwd")
o.title = translate("Account Password")
o.password = true
o.rmempty = true

if m.uci:get("openclash", "config", "dler_token") then
	o = s:taboption("dlercloud", Flag, "dler_checkin")
	o.title = translate("Checkin")
	o.default = 0
	o.rmempty = true
end

o = s:taboption("dlercloud", Value, "dler_checkin_interval")
o.title = translate("Checkin Interval (hour)")
o:depends("dler_checkin", "1")
o.default = "1"
o.rmempty = true

o = s:taboption("dlercloud", Value, "dler_checkin_multiple")
o.title = translate("Checkin Multiple")
o.datatype = "uinteger"
o.default = "1"
o:depends("dler_checkin", "1")
o.rmempty = true
o.description = font_green..bold_on..translate("Multiple Must Be a Positive Integer and No More Than 50")..bold_off..font_off
function o.validate(self, value)
	if tonumber(value) < 1 then
		return "1"
	end
	if tonumber(value) > 50 then
		return "50"
	end
	return value
end

o = s:taboption("dlercloud", DummyValue, "dler_login", translate("Account Login"))
o.template = "openclash/dler_login"
if m.uci:get("openclash", "config", "dler_token") then
	o.value = font_green..bold_on..translate("Account logged in")..bold_off..font_off
else
	o.value = font_red..bold_on..translate("Account not logged in")..bold_off..font_off
end

-- [[ Edit Custom DNS ]] --
ds = m:section(TypedSection, "dns_servers", translate("Add Custom DNS Servers")..translate("(Take Effect After Choose Above)"))
ds.anonymous = true
ds.addremove = true
ds.sortable = true
ds.template = "cbi/tblsection"
ds.extedit = luci.dispatcher.build_url("admin/services/openclash/custom-dns-edit/%s")
function ds.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(ds.extedit % sid)
		return
	end
end

---- enable flag
o = ds:option(Flag, "enabled", translate("Enable"))
o.rmempty     = false
o.default     = o.enabled
o.cfgvalue    = function(...)
    return Flag.cfgvalue(...) or "1"
end

---- group
o = ds:option(ListValue, "group", translate("DNS Server Group"))
o:value("nameserver", translate("NameServer "))
o:value("fallback", translate("FallBack "))
o:value("default", translate("Default-NameServer"))
o.default     = "nameserver"
o.rempty      = false

---- IP address
o = ds:option(Value, "ip", translate("DNS Server Address"))
o.placeholder = translate("Not Null")
o.datatype = "or(host, string)"
o.rmempty = true

---- port
o = ds:option(Value, "port", translate("DNS Server Port"))
o.datatype    = "port"
o.rempty      = true

---- type
o = ds:option(ListValue, "type", translate("DNS Server Type"))
o:value("udp", translate("UDP"))
o:value("tcp", translate("TCP"))
o:value("tls", translate("TLS"))
o:value("https", translate("HTTPS"))
o:value("quic", translate("QUIC ")..translate("(Only Meta Core)"))
o.default     = "udp"
o.rempty      = false

-- [[ Other Rules Manage ]]--
ss = m:section(TypedSection, "other_rules", translate("Other Rules Edit")..translate("(Take Effect After Choose Above)"))
ss.anonymous = true
ss.addremove = true
ss.sortable = true
ss.template = "cbi/tblsection"
ss.extedit = luci.dispatcher.build_url("admin/services/openclash/other-rules-edit/%s")
function ss.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(ss.extedit % sid)
		return
	end
end

o = ss:option(Flag, "enabled", translate("Enable"))
o.rmempty     = false
o.default     = o.enabled
o.cfgvalue    = function(...)
    return Flag.cfgvalue(...) or "1"
end

o = ss:option(DummyValue, "config", translate("Config File"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = ss:option(DummyValue, "rule_name", translate("Other Rules Name"))
function o.cfgvalue(...)
	if Value.cfgvalue(...) == "lhie1" then
		return translate("lhie1 Rules")
	elseif Value.cfgvalue(...) == "ConnersHua" then
		return translate("ConnersHua(Provider-type) Rules")
	elseif Value.cfgvalue(...) == "ConnersHua_return" then
		return translate("ConnersHua Return Rules")
	else
		return translate("None")
	end
end

o = ss:option(DummyValue, "Note", translate("Note"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

-- [[ Edit Authentication ]] --
s = m:section(TypedSection, "authentication", translate("Set Authentication of SOCKS5/HTTP(S)"))
s.anonymous = true
s.addremove = true
s.sortable = false
s.template = "cbi/tblsection"
s.rmempty = false

---- enable flag
o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty     = false
o.default     = o.enabled
o.cfgvalue    = function(...)
    return Flag.cfgvalue(...) or "1"
end

---- username
o = s:option(Value, "username", translate("Username"))
o.placeholder = translate("Not Null")
o.rempty      = true

---- password
o = s:option(Value, "password", translate("Password"))
o.placeholder = translate("Not Null")
o.rmempty = true

s = m:section(NamedSection, "config")
s.title=translate("Set Custom Hosts (Does Not Override Config Settings)")
s.anonymous = true
s.addremove = false

custom_hosts = s:option(Value, "custom_hosts")
custom_hosts.template = "cbi/tvalue"
custom_hosts.description = translate("Custom Hosts Here, For More Go:").." ".."<a href='javascript:void(0)' onclick='javascript:return winOpen(\"https://lancellc.gitbook.io/clash/clash-config-file/dns/host\")'>https://lancellc.gitbook.io/clash/clash-config-file/dns/host</a>"
custom_hosts.rows = 20
custom_hosts.wrap = "off"

function custom_hosts.cfgvalue(self, section)
	return NXFS.readfile("/etc/openclash/custom/openclash_custom_hosts.list") or ""
end
function custom_hosts.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		local old_value = NXFS.readfile("/etc/openclash/custom/openclash_custom_hosts.list")
	  if value ~= old_value then
			NXFS.writefile("/etc/openclash/custom/openclash_custom_hosts.list", value)
		end
	end
end

local t = {
    {Commit, Apply}
}

a = m:section(Table, t)

o = a:option(Button, "Commit", " ")
o.inputtitle = translate("Commit Settings")
o.inputstyle = "apply"
o.write = function()
  m.uci:commit("openclash")
end

o = a:option(Button, "Apply", " ")
o.inputtitle = translate("Apply Settings")
o.inputstyle = "apply"
o.write = function()
  m.uci:set("openclash", "config", "enable", 1)
  m.uci:commit("openclash")
  SYS.call("/etc/init.d/openclash restart >/dev/null 2>&1 &")
  HTTP.redirect(DISP.build_url("admin", "services", "openclash"))
end

m:append(Template("openclash/config_editor"))
m:append(Template("openclash/toolbar_show"))

return m


