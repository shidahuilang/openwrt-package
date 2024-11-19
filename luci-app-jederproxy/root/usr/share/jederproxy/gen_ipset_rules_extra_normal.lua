#!/usr/bin/lua

local special_purpose_rules = [[add jp_ipv4_rfc1918 255.255.255.255
add jp_ipv4_rfc1918 0.0.0.0/8
add jp_ipv4_rfc1918 10.0.0.0/8
add jp_ipv4_rfc1918 100.64.0.0/10
add jp_ipv4_rfc1918 127.0.0.0/8
add jp_ipv4_rfc1918 169.254.0.0/16
add jp_ipv4_rfc1918 172.16.0.0/12
add jp_ipv4_rfc1918 192.0.0.0/24
add jp_ipv4_rfc1918 192.0.2.0/24
add jp_ipv4_rfc1918 192.88.99.0/24
add jp_ipv4_rfc1918 192.168.0.0/16
add jp_ipv4_rfc1918 198.18.0.0/15
add jp_ipv4_rfc1918 198.51.100.0/24
add jp_ipv4_rfc1918 203.0.113.0/24
add jp_ipv4_rfc1918 224.0.0.0/4
add jp_ipv4_rfc1918 233.252.0.0/24
add jp_ipv4_rfc1918 240.0.0.0/4]]

return function(proxy)
    print(special_purpose_rules)
end
