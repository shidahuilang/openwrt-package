local api = require "luci.passwall2.api"
local appname = api.appname
local uci = api.uci
local datatypes = api.datatypes
local has_v2ray = api.is_finded("v2ray")
local has_xray = api.is_finded("xray")

m = Map(appname)

local nodes_table = {}
for k, e in ipairs(api.get_valid_nodes()) do
    nodes_table[#nodes_table + 1] = e
end

local doh_validate = function(self, value, t)
    if value ~= "" then
        local flag = 0
        local util = require "luci.util"
        local val = util.split(value, ",")
        local url = val[1]
        val[1] = nil
        for i = 1, #val do
            local v = val[i]
            if v then
                if not datatypes.ipmask4(v) then
                    flag = 1
                end
            end
        end
        if flag == 0 then
            return value
        end
    end
    return nil, translate("DoH request address") .. " " .. translate("Format must be:") .. " URL,IP"
end

m:append(Template(appname .. "/global/status"))

s = m:section(TypedSection, "global")
s.anonymous = true
s.addremove = false

s:tab("Main", translate("Main"))

-- [[ Global Settings ]]--
o = s:taboption("Main", Flag, "enabled", translate("Main switch"))
o.rmempty = false

---- Node
node = s:taboption("Main", ListValue, "node", "<a style='color: red'>" .. translate("Node") .. "</a>")
node.description = ""
local current_node = luci.sys.exec(string.format("[ -f '/tmp/etc/%s/id/TCP' ] && echo -n $(cat /tmp/etc/%s/id/TCP)", appname, appname))
if current_node and current_node ~= "" and current_node ~= "nil" then
    local n = uci:get_all(appname, current_node)
    if n then
        if tonumber(m:get("@auto_switch[0]", "enable") or 0) == 1 then
            local remarks = api.get_full_node_remarks(n)
            local url = api.url("node_config", current_node)
            node.description = node.description .. translatef("Current node: %s", string.format('<a href="%s">%s</a>', url, remarks)) .. "<br />"
        end
    end
end
node:value("nil", translate("Close"))

-- 分流
if (has_v2ray or has_xray) and #nodes_table > 0 then
    local normal_list = {}
    local shunt_list = {}
    for k, v in pairs(nodes_table) do
        if v.node_type == "normal" then
            normal_list[#normal_list + 1] = v
        end
        if v.protocol and v.protocol == "_shunt" then
            shunt_list[#shunt_list + 1] = v
        end
    end
    for k, v in pairs(shunt_list) do
        uci:foreach(appname, "shunt_rules", function(e)
            local id = e[".name"]
            if id and e.remarks then
                o = s:taboption("Main", ListValue, v.id .. "." .. id .. "_node", string.format('* <a href="%s" target="_blank">%s</a>', api.url("shunt_rules", id), e.remarks))
                o:depends("node", v.id)
                o:value("nil", translate("Close"))
                o:value("_default", translate("Default"))
                o:value("_direct", translate("Direct Connection"))
                o:value("_blackhole", translate("Blackhole"))
                for k1, v1 in pairs(normal_list) do
                    o:value(v1.id, v1["remark"])
                end
                o.cfgvalue = function(self, section)
                    return m:get(v.id, id) or "nil"
                end
                o.write = function(self, section, value)
                    m:set(v.id, id, value)
                end
            end
        end)

        local id = "default_node"
        o = s:taboption("Main", ListValue, v.id .. "." .. id, string.format('* <a style="color:red">%s</a>', translate("Default")))
        o:depends("node", v.id)
        o:value("_direct", translate("Direct Connection"))
        o:value("_blackhole", translate("Blackhole"))
        for k1, v1 in pairs(normal_list) do
            o:value(v1.id, v1["remark"])
        end
        o.cfgvalue = function(self, section)
            return m:get(v.id, id) or "nil"
        end
        o.write = function(self, section, value)
            m:set(v.id, id, value)
        end
        
        local id = "main_node"
        o = s:taboption("Main", ListValue, v.id .. "." .. id, string.format('* <a style="color:red">%s</a>', translate("Default Preproxy")), translate("When using, localhost will connect this node first and then use this node to connect the default node."))
        o:depends("node", v.id)
        o:value("nil", translate("Close"))
        for k1, v1 in pairs(normal_list) do
            o:value(v1.id, v1["remark"])
        end
        o.cfgvalue = function(self, section)
            return m:get(v.id, id) or "nil"
        end
        o.write = function(self, section, value)
            m:set(v.id, id, value)
        end
    end
end

o = s:taboption("Main", Flag, "localhost_proxy", translate("Localhost Proxy"), translate("When selected, localhost can transparent proxy."))
o.default = "1"
o.rmempty = false

node_socks_port = s:taboption("Main", Value, "node_socks_port", translate("Node") .. " Socks " .. translate("Listen Port"))
node_socks_port.default = 1070
node_socks_port.datatype = "port"

--[[
if has_v2ray or has_xray then
    node_http_port = s:taboption("Main", Value, "node_http_port", translate("Node") .. " HTTP " .. translate("Listen Port") .. " " .. translate("0 is not use"))
    node_http_port.default = 0
    node_http_port.datatype = "port"
end
]]--

s:tab("DNS", translate("DNS"))

o = s:taboption("DNS", ListValue, "direct_dns_protocol", translate("Direct DNS Protocol"))
o.default = "auto"
o:value("auto", translate("Auto"))
o:value("udp", "UDP")
o:value("tcp", "TCP")
o:value("doh", "DoH")

---- DNS Forward
o = s:taboption("DNS", Value, "direct_dns", translate("Direct DNS"))
o.datatype = "or(ipaddr,ipaddrport)"
o.default = "119.29.29.29"
o:value("114.114.114.114", "114.114.114.114 (114DNS)")
o:value("119.29.29.29", "119.29.29.29 (DNSPod)")
o:value("223.5.5.5", "223.5.5.5 (AliDNS)")
o:depends("direct_dns_protocol", "udp")
o:depends("direct_dns_protocol", "tcp")

---- DoH
o = s:taboption("DNS", Value, "direct_dns_doh", translate("Direct DNS DoH"))
o.default = "https://223.5.5.5/dns-query"
o:value("https://1.12.12.12/dns-query", "DNSPod 1")
o:value("https://120.53.53.53/dns-query", "DNSPod 2")
o:value("https://223.5.5.5/dns-query", "AliDNS")
o.validate = doh_validate
o:depends("direct_dns_protocol", "doh")

o = s:taboption("DNS", Value, "direct_dns_client_ip", translate("Direct DNS EDNS Client Subnet"))
o.description = translate("Notify the DNS server when the DNS query is notified, the location of the client (cannot be a private IP address).") .. "<br />" ..
                translate("This feature requires the DNS server to support the Edns Client Subnet (RFC7871).")
o.datatype = "ipaddr"
o:depends("direct_dns_protocol", "tcp")
o:depends("direct_dns_protocol", "doh")

o = s:taboption("DNS", ListValue, "direct_dns_query_strategy", translate("Direct Query Strategy"))
o.default = "UseIP"
o:value("UseIP")
o:value("UseIPv4")
o:value("UseIPv6")

o = s:taboption("DNS", ListValue, "remote_dns_protocol", translate("Remote DNS Protocol"))
o:value("tcp", "TCP")
o:value("doh", "DoH")
o:value("udp", "UDP")
o:value("fakedns", "FakeDNS")

o = s:taboption("DNS", Flag, "only_proxy_fakedns", translate("Only Proxy FakeDNS"), translate("When selected, only FakeDNS domain to proxy."))
o.default = "0"
o:depends("remote_dns_protocol", "fakedns")

---- DNS Forward
o = s:taboption("DNS", Value, "remote_dns", translate("Remote DNS"))
o.datatype = "or(ipaddr,ipaddrport)"
o.default = "1.1.1.1"
o:value("1.1.1.1", "1.1.1.1 (CloudFlare)")
o:value("1.1.1.2", "1.1.1.2 (CloudFlare-Security)")
o:value("8.8.4.4", "8.8.4.4 (Google)")
o:value("8.8.8.8", "8.8.8.8 (Google)")
o:value("9.9.9.9", "9.9.9.9 (Quad9-Recommended)")
o:value("208.67.220.220", "208.67.220.220 (OpenDNS)")
o:value("208.67.222.222", "208.67.222.222 (OpenDNS)")
o:depends("remote_dns_protocol", "tcp")
o:depends("remote_dns_protocol", "udp")

---- DoH
o = s:taboption("DNS", Value, "remote_dns_doh", translate("Remote DNS DoH"))
o.default = "https://1.1.1.1/dns-query"
o:value("https://1.1.1.1/dns-query", "CloudFlare")
o:value("https://1.1.1.2/dns-query", "CloudFlare-Security")
o:value("https://8.8.4.4/dns-query", "Google 8844")
o:value("https://8.8.8.8/dns-query", "Google 8888")
o:value("https://9.9.9.9/dns-query", "Quad9-Recommended")
o:value("https://208.67.222.222/dns-query", "OpenDNS")
o:value("https://dns.adguard.com/dns-query,176.103.130.130", "AdGuard")
o:value("https://doh.libredns.gr/dns-query,116.202.176.26", "LibreDNS")
o:value("https://doh.libredns.gr/ads,116.202.176.26", "LibreDNS (No Ads)")
o.validate = doh_validate
o:depends("remote_dns_protocol", "doh")

o = s:taboption("DNS", Value, "remote_dns_client_ip", translate("Remote DNS EDNS Client Subnet"))
o.description = translate("Notify the DNS server when the DNS query is notified, the location of the client (cannot be a private IP address).") .. "<br />" ..
                translate("This feature requires the DNS server to support the Edns Client Subnet (RFC7871).")
o.datatype = "ipaddr"
o:depends("remote_dns_protocol", "tcp")
o:depends("remote_dns_protocol", "doh")

o = s:taboption("DNS", ListValue, "remote_dns_query_strategy", translate("Remote Query Strategy"))
o.default = "UseIPv4"
o:value("UseIP")
o:value("UseIPv4")
o:value("UseIPv6")

hosts = s:taboption("DNS", TextValue, "dns_hosts", translate("Domain Override"))
hosts.rows = 5
hosts.wrap = "off"

s:tab("log", translate("Log"))
o = s:taboption("log", Flag, "close_log", translate("Close Node Log"))
o.rmempty = false

loglevel = s:taboption("log", ListValue, "loglevel", translate("Log Level"))
loglevel.default = "warning"
loglevel:value("debug")
loglevel:value("info")
loglevel:value("warning")
loglevel:value("error")

s:tab("faq", "FAQ")

o = s:taboption("faq", DummyValue, "")
o.template = appname .. "/global/faq"

-- [[ Socks Server ]]--
o = s:taboption("Main", Flag, "socks_enabled", "Socks " .. translate("Main switch"))
o.rmempty = false

s = m:section(TypedSection, "socks", translate("Socks Config"))
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"
function s.create(e, t)
    TypedSection.create(e, api.gen_uuid())
end

o = s:option(DummyValue, "status", translate("Status"))
o.rawhtml = true
o.cfgvalue = function(t, n)
    return string.format('<div class="_status" socks_id="%s"></div>', n)
end

---- Enable
o = s:option(Flag, "enabled", translate("Enable"))
o.default = 1
o.rmempty = false

socks_node = s:option(ListValue, "node", translate("Socks Node"))

local n = 1
uci:foreach(appname, "socks", function(s)
    if s[".name"] == section then
        return false
    end
    n = n + 1
end)

o = s:option(Value, "port", "Socks " .. translate("Listen Port"))
o.default = n + 1080
o.datatype = "port"
o.rmempty = false

if has_v2ray or has_xray then
    o = s:option(Value, "http_port", "HTTP " .. translate("Listen Port") .. " " .. translate("0 is not use"))
    o.default = 0
    o.datatype = "port"
end

for k, v in pairs(nodes_table) do
    node:value(v.id, v["remark"])
    if v.type == "Socks" then
        if has_v2ray or has_xray then
            socks_node:value(v.id, v["remark"])
        end
    else
        socks_node:value(v.id, v["remark"])
    end
end

m:append(Template(appname .. "/global/footer"))

return m
