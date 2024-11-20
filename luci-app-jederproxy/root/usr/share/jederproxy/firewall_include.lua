#!/usr/bin/lua
local ucursor = require "luci.model.uci"

local flush = [[# firewall include file to stop transparent proxy
ip rule  del   table 100
ip route flush table 100
iptables-save -c | grep -v "JPROXY" | iptables-restore -c]]
local header = [[# firewall include file to start transparent proxy
ip route add local default dev lo table 100
ip rule  add fwmark 0x2333        table 100

iptables-restore -n <<-EOF
*mangle
:JPROXY_RULES - [0:0]
:JPROXY_MARK_CONNECTIONS - [0:0]
]]
local rules = [[
##### JPROXY_RULES #####
# ignore traffic marked by JPROXY outbound
-A JPROXY_RULES -m mark --mark 0x%x -j RETURN
# connection-mark -> packet-mark
-A JPROXY_RULES -j CONNMARK --restore-mark
# ignore established connections
-A JPROXY_RULES -m mark --mark 0x2333 -j RETURN

# ignore traffic sent to reserved addresses
-A JPROXY_RULES -m set --match-set jp_ipv4_rfc1918 dst -j RETURN

# route traffic depends on whitelist/blacklists
-A JPROXY_RULES -m set --match-set jp_ether_src_bypass src -j RETURN
-A JPROXY_RULES -m set --match-set jp_ether_src_forward src -j JPROXY_MARK_CONNECTIONS

-A JPROXY_RULES -m set --match-set jp_ipv4_dst_forward dst -j JPROXY_MARK_CONNECTIONS
-A JPROXY_RULES -m set --match-set jp_ipv4_dst_bypass dst -j RETURN
-A JPROXY_RULES -j JPROXY_MARK_CONNECTIONS

##### JPROXY_MARK_CONNECTIONS #####
# mark the first packet of the connection
-A JPROXY_MARK_CONNECTIONS -p tcp --syn                      -j MARK --set-mark 0x2333
-A JPROXY_MARK_CONNECTIONS -p udp -m conntrack --ctstate NEW -j MARK --set-mark 0x2333

# packet-mark -> connection-mark
-A JPROXY_MARK_CONNECTIONS -j CONNMARK --save-mark

##### OUTPUT #####
-A OUTPUT -p tcp -m addrtype --src-type LOCAL ! --dst-type LOCAL -j JPROXY_RULES

##### PREROUTING #####
# proxy traffic passing through this machine (other->other)
-A PREROUTING -i %s -p tcp -m addrtype ! --src-type LOCAL ! --dst-type LOCAL -j JPROXY_RULES

# hand over the marked package to TPROXY for processing
-A PREROUTING -p tcp -m mark --mark 0x2333 -j TPROXY --on-ip 127.0.0.1 --on-port %d
]]

local rules_udp = [[
##### OUTPUT #####
-A OUTPUT -p udp -m addrtype --src-type LOCAL ! --dst-type LOCAL -j JPROXY_RULES

##### PREROUTING #####
# proxy traffic passing through this machine (other->other)
-A PREROUTING -i %s -p udp -m addrtype ! --src-type LOCAL ! --dst-type LOCAL -j JPROXY_RULES

# hand over the marked package to TPROXY for processing
-A PREROUTING -p udp -m mark --mark 0x2333 -j TPROXY --on-ip 127.0.0.1 --on-port %d
]]

local footer = [[
COMMIT
EOF]]

local proxy_section = ucursor:get_first("jederproxy", "general")
local proxy = ucursor:get_all("jederproxy", proxy_section)

print(flush)
if proxy.transparent_proxy_enable ~= "1" then
    do
        return
    end
end
if arg[1] == "enable" then
    print(header)
    print(string.format(rules, tonumber(proxy.mark),
        proxy.lan_interface, proxy.tproxy_port))
    if proxy.tproxy_enable_udp ~= "1" then
        print(string.format(rules_udp
            proxy.lan_interface, proxy.tproxy_port))
    end
    print(footer)
    else
    print("# arg[1] == " .. arg[1] .. ", not enable")
end
