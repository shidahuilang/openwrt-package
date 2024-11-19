#!/usr/bin/lua

local io = require("io")
local ucursor = require "luci.model.uci"
local proxy_section = ucursor:get_first("jederproxy", "general")
local proxy = ucursor:get_all("jederproxy", proxy_section)
local gen_ipset_rules_extra = dofile("/usr/share/jederproxy/gen_ipset_rules_extra.lua")

local create_ipset_rules = [[create jp_ether_src_bypass hash:mac hashsize 64
create jp_ether_src_forward hash:mac hashsize 64
create jp_ipv4_rfc1918 hash:net hashsize 64
create jp_ipv4_dst_bypass hash:net hashsize 64
create jp_ipv4_dst_forward hash:net hashsize 64]]

local function create_ipset()
    print(create_ipset_rules)
end

local function split_ipv4_host_port(val, port_default)
    local found, _, ip, port = val:find("([%d.]+):(%d+)")
    if found == nil then
        return val, tonumber(port_default)
    else
        return ip, tonumber(port)
    end
end

local function lan_access_control()
    ucursor:foreach("xray", "lan_hosts", function(v)
        if v.bypassed == '0' then
            print(string.format("add jp_ether_src_forward %s", v.macaddr))
        else
            print(string.format("add jp_ether_src_bypass %s", v.macaddr))
        end
    end)
end

local function iterate_list(ln, set_name)
    local ip_list = proxy[ln]
    if ip_list == nil then
        return
    end
    for _, line in ipairs(ip_list) do
        print(string.format("add %s %s", set_name, line))
    end
end

local function iterate_file(fn, set_name)
    if fn == nil then
        return
    end
    local f = io.open(fn)
    if f == nil then
        return
    end
    for line in io.lines(fn) do
        if line ~= "" then
            print(string.format("add %s %s", set_name, line))
        end
    end
    f:close()
end

local function dns_ips()
    local fast_dns_ip, fast_dns_port = split_ipv4_host_port(proxy.fast_dns, 53)
    local secure_dns_ip, secure_dns_port = split_ipv4_host_port(proxy.secure_dns, 53)
    print(string.format("add jp_ipv4_dst_bypass %s", fast_dns_ip))
    print(string.format("add jp_ipv4_dst_forward %s", secure_dns_ip))
end

create_ipset()
dns_ips()
lan_access_control()
iterate_list("wan_bypass_rules", "jp_ipv4_dst_bypass")
iterate_file(proxy.wan_bypass_rule_file or "/dev/null", "jp_ipv4_dst_bypass")
iterate_list("wan_forward_rules", "jp_ipv4_dst_forward")
iterate_file(proxy.wan_forward_rule_file or "/dev/null", "jp_ipv4_dst_forward")
gen_ipset_rules_extra(proxy)
