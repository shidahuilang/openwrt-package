-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.
local m, s, o, kcp_enable
local vssr = 'vssr'
local uci = luci.model.uci.cursor()

local fs = require 'nixio.fs'
local sys = require 'luci.sys'
local sid = arg[1]
local uuid = luci.sys.exec('cat /proc/sys/kernel/random/uuid')

local function isKcptun(file)
    if not fs.access(file, 'rwx', 'rx', 'rx') then
        fs.chmod(file, 755)
    end

    local str = sys.exec(file .. " -v | awk '{printf $1}'")
    return (str:lower() == 'kcptun')
end

local server_table = {}
local encrypt_methods = {
    'none',
    'table',
    'rc4',
    'rc4-md5-6',
    'rc4-md5',
    'aes-128-cfb',
    'aes-192-cfb',
    'aes-256-cfb',
    'aes-128-ctr',
    'aes-192-ctr',
    'aes-256-ctr',
    'bf-cfb',
    'camellia-128-cfb',
    'camellia-192-cfb',
    'camellia-256-cfb',
    'cast5-cfb',
    'des-cfb',
    'idea-cfb',
    'rc2-cfb',
    'seed-cfb',
    'salsa20',
    'chacha20',
    'chacha20-ietf'
}

local encrypt_methods_ss = {
    -- aead
    'aes-128-gcm',
    'aes-192-gcm',
    'aes-256-gcm',
    'chacha20-ietf-poly1305',
    'xchacha20-ietf-poly1305', -- stream
    'table',
    'rc4',
    'rc4-md5',
    'aes-128-cfb',
    'aes-192-cfb',
    'aes-256-cfb',
    'aes-128-ctr',
    'aes-192-ctr',
    'aes-256-ctr',
    'bf-cfb',
    'camellia-128-cfb',
    'camellia-192-cfb',
    'camellia-256-cfb',
    'salsa20',
    'chacha20',
    'chacha20-ietf'
}

local protocol = {
    'origin',
    'verify_deflate',
    'auth_sha1_v4',
    'auth_aes128_sha1',
    'auth_aes128_md5',
    'auth_chain_a',
    'auth_chain_b',
    'auth_chain_c',
    'auth_chain_d',
    'auth_chain_e',
    'auth_chain_f'
}

obfs = {
    'plain',
    'http_simple',
    'http_post',
    'random_head',
    'tls1.2_ticket_auth'
}
local securitys = {
    'auto',
    'none',
    'aes-128-gcm',
    'chacha20-poly1305'
}

local flows = {
    'xtls-rprx-origin',
    'xtls-rprx-origin-udp443',
    'xtls-rprx-direct',
    'xtls-rprx-direct-udp443',
    'xtls-rprx-splice',
    'xtls-rprx-splice-udp443'
}

m = Map(vssr, translate('Edit vssr Server'))
m.redirect = luci.dispatcher.build_url('admin/services/vssr/servers')
if m.uci:get(vssr, sid) ~= 'servers' then
    luci.http.redirect(m.redirect)
    return
end

-- [[ Servers Setting ]]--
s = m:section(NamedSection, sid, 'servers')
s.anonymous = true
s.addremove = false

o = s:option(DummyValue, 'ssr_url', translate('Configuration Url'))
o.rawhtml = true
o.template = 'vssr/ssrurl'
o.value = sid

o = s:option(ListValue, 'type', translate('Server Node Type'))
o:value('ssr', translate('ShadowsocksR'))
if nixio.fs.access('/usr/bin/ss-redir') then
    o:value('ss', translate('Shadowsocks New Version'))
end
if nixio.fs.access('/usr/bin/v2ray/v2ray') or nixio.fs.access('/usr/bin/v2ray') or nixio.fs.access('/usr/bin/xray') or nixio.fs.access('/usr/bin/xray/xray') then
    o:value('v2ray', translate('V2Ray'))
    o:value('vless', translate('VLESS'))
end

if nixio.fs.access('/usr/sbin/trojan') then
    o:value('trojan', translate('Trojan'))
end

o.description = translate('Using incorrect encryption mothod may causes service fail to start')

o = s:option(Value, 'alias', translate('Alias(optional)'))

o = s:option(Value, 'flag', translate('Area'))
o.description = translate('请自己指定。格式：cn us hk 等')
o.rmempty = true

o = s:option(Value, 'server', translate('Server Address'))
o.datatype = 'host'
o.rmempty = false

o = s:option(Value, 'server_port', translate('Server Port'))
o.datatype = 'port'
o.rmempty = false

o = s:option(Value, 'password', translate('Password'))
o.password = true
o.rmempty = true
o:depends('type', 'ssr')
o:depends('type', 'ss')
o:depends('type', 'trojan')

o = s:option(Value, 'peer', translate('Peer'))
o.datatype = 'host'
o.rmempty = true
o:depends('type', 'trojan')

o = s:option(ListValue, 'encrypt_method', translate('Encrypt Method'))
for _, v in ipairs(encrypt_methods) do
    o:value(v)
end
o.rmempty = true
o:depends('type', 'ssr')

o = s:option(ListValue, 'encrypt_method_ss', translate('Encrypt Method'))
for _, v in ipairs(encrypt_methods_ss) do
    o:value(v)
end
o.rmempty = true
o:depends('type', 'ss')

-- Shadowsocks Plugin
o = s:option(Value, 'plugin', translate('Plugin'))
o.rmempty = true
o:depends('type', 'ss')

o = s:option(Value, 'plugin_opts', translate('Plugin Opts'))
o.rmempty = true
o:depends('type', 'ss')

o = s:option(ListValue, 'protocol', translate('Protocol'))
for _, v in ipairs(protocol) do
    o:value(v)
end
o.rmempty = true
o:depends('type', 'ssr')

o = s:option(Value, 'protocol_param', translate('Protocol param(optional)'))
o:depends('type', 'ssr')

o = s:option(ListValue, 'obfs', translate('Obfs'))
for _, v in ipairs(obfs) do
    o:value(v)
end
o.rmempty = true
o:depends('type', 'ssr')

o = s:option(Value, 'obfs_param', translate('Obfs param(optional)'))
o:depends('type', 'ssr')

-- AlterId
o = s:option(Value, 'alter_id', translate('AlterId'))
o.datatype = 'port'
o.default = 16
o.rmempty = true
o:depends('type', 'v2ray')

-- VmessId
o = s:option(Value, 'vmess_id', translate('VMESS/VLESS ID (UUID)'))
o.rmempty = true
o.default = uuid
o:depends('type', 'v2ray')
o:depends('type', 'vless')
o:depends('type', 'xray')

-- VLESS 加密方式
o = s:option(Value, 'vless_encryption', translate('VLESS Encryption'))
o.rmempty = true
o.default = 'none'
o:depends('type', 'vless')
o:depends('type', 'xray')

-- 加密方式
o = s:option(ListValue, 'security', translate('Encrypt Method'))
for _, v in ipairs(securitys) do
    o:value(v, v:upper())
end
o.rmempty = true
o:depends('type', 'v2ray')

-- 传输协议
o = s:option(ListValue, 'transport', translate('Transport'))
o:value('tcp', 'TCP')
o:value('kcp', 'mKCP')
o:value('ws', 'WebSocket')
o:value('h2', 'HTTP/2')
o:value('quic', 'QUIC')
o.rmempty = true
o:depends('type', 'v2ray')
o:depends('type', 'vless')
o:depends('type', 'xray')

-- [[ TCP部分 ]]--

-- TCP伪装
o = s:option(ListValue, 'tcp_guise', translate('Camouflage Type'))
o:depends('transport', 'tcp')
o:value('none', translate('None'))
o:value('http', 'HTTP')
o.rmempty = true

-- HTTP域名
o = s:option(DynamicList, 'http_host', translate('HTTP Host'))
o:depends('tcp_guise', 'http')
o.rmempty = true

-- HTTP路径
o = s:option(DynamicList, 'http_path', translate('HTTP Path'))
o:depends('tcp_guise', 'http')
o.rmempty = true

-- [[ WS部分 ]]--

-- WS域名
o = s:option(Value, 'ws_host', translate('WebSocket Host'))
o:depends('transport', 'ws')
o.rmempty = true

-- WS路径
o = s:option(Value, 'ws_path', translate('WebSocket Path'))
o:depends('transport', 'ws')
o.rmempty = true

-- [[ H2部分 ]]--

-- H2域名
o = s:option(DynamicList, 'h2_host', translate('HTTP/2 Host'))
o:depends('transport', 'h2')
o.rmempty = true

-- H2路径
o = s:option(Value, 'h2_path', translate('HTTP/2 Path'))
o:depends('transport', 'h2')
o.rmempty = true

-- [[ QUIC部分 ]]--

o = s:option(ListValue, 'quic_security', translate('QUIC Security'))
o:depends('transport', 'quic')
o.rmempty = true
o:value('none', translate('None'))
o:value('aes-128-gcm', translate('aes-128-gcm'))
o:value('chacha20-poly1305', translate('chacha20-poly1305'))

o = s:option(Value, 'quic_key', translate('QUIC Key'))
o:depends('transport', 'quic')
o.rmempty = true

o = s:option(ListValue, 'quic_guise', translate('Header'))
o:depends('transport', 'quic')
o.rmempty = true
o:value('none', translate('None'))
o:value('srtp', translate('VideoCall (SRTP)'))
o:value('utp', translate('BitTorrent (uTP)'))
o:value('wechat-video', translate('WechatVideo'))
o:value('dtls', 'DTLS 1.2')
o:value('wireguard', 'WireGuard')
-- [[ mKCP部分 ]]--

o = s:option(ListValue, 'kcp_guise', translate('Camouflage Type'))
o:depends('transport', 'kcp')
o:value('none', translate('None'))
o:value('srtp', translate('VideoCall (SRTP)'))
o:value('utp', translate('BitTorrent (uTP)'))
o:value('wechat-video', translate('WechatVideo'))
o:value('dtls', 'DTLS 1.2')
o:value('wireguard', 'WireGuard')
o.rmempty = true

o = s:option(Value, 'mtu', translate('MTU'))
o.datatype = 'uinteger'
o:depends('transport', 'kcp')
o.default = 1350
o.rmempty = true

o = s:option(Value, 'tti', translate('TTI'))
o.datatype = 'uinteger'
o:depends('transport', 'kcp')
o.default = 50
o.rmempty = true

o = s:option(Value, 'uplink_capacity', translate('Uplink Capacity'))
o.datatype = 'uinteger'
o:depends('transport', 'kcp')
o.default = 5
o.rmempty = true

o = s:option(Value, 'downlink_capacity', translate('Downlink Capacity'))
o.datatype = 'uinteger'
o:depends('transport', 'kcp')
o.default = 20
o.rmempty = true

o = s:option(Value, 'read_buffer_size', translate('Read Buffer Size'))
o.datatype = 'uinteger'
o:depends('transport', 'kcp')
o.default = 2
o.rmempty = true

o = s:option(Value, 'write_buffer_size', translate('Write Buffer Size'))
o.datatype = 'uinteger'
o:depends('transport', 'kcp')
o.default = 2
o.rmempty = true

o = s:option(Value, 'seed', translate('Seed'))
o:depends('transport', 'kcp')
o.default = ''
o.rmempty = true

o = s:option(Flag, 'congestion', translate('Congestion'))
o:depends('transport', 'kcp')
o.rmempty = true

-- [[ allowInsecure ]]--
o = s:option(Flag, 'insecure', translate('allowInsecure'))
o.rmempty = false
o:depends('type', 'v2ray')
o:depends('type', 'trojan')
o:depends('type', 'vless')
o:depends('type', 'xray')

-- [[ TLS ]]--
o = s:option(Flag, 'tls', translate('TLS'))
o.rmempty = true
o.default = '0'
o:depends('type', 'v2ray')
o:depends('type', 'trojan')
o:depends('type', 'vless')
o:depends('type', 'xray')

o = s:option(Value, 'tls_host', translate('TLS Host'))
--o:depends("type", "trojan")
o:depends('tls', '1')
o.rmempty = true

-- XTLS
o = s:option(Flag, 'xtls', translate('XTLS'))
o.rmempty = true
o.default = '0'
o:depends({type = 'vless', tls = '1'})
o:depends({type = 'xray', tls = '1'})

-- Flow
o = s:option(ListValue, 'vless_flow', translate('Flow'))
for _, v in ipairs(flows) do
    o:value(v, v)
end
o.rmempty = true
o.default = 'xtls-rprx-origin'
o:depends('xtls', '1')

-- [[ Mux ]]--
o = s:option(Flag, 'mux', translate('Mux'))
o.rmempty = true
o.default = '0'
o:depends('type', 'v2ray')
o:depends('type', 'vless')

o = s:option(Value, 'concurrency', translate('Concurrency'))
o.datatype = 'uinteger'
o.rmempty = true
o.default = '8'
o:depends('mux', '1')

-- [[NO self cert]]

o = s:option(Flag, 'fast_open', translate('TCP Fast Open'))
o.rmempty = true
o.default = '0'
o:depends('type', 'ssr')
o:depends('type', 'ss')
o:depends('type', 'trojan')

o = s:option(Flag, 'switch_enable', translate('Enable Auto Switch'))
o.rmempty = false
o.default = '1'

o = s:option(Value, 'local_port', translate('Local Port'))
o.datatype = 'port'
o.default = 1234
o.rmempty = false

if nixio.fs.access('/usr/bin/kcptun-client') then
    kcp_enable = s:option(Flag, 'kcp_enable', translate('KcpTun Enable'), translate('bin:/usr/bin/kcptun-client'))
    kcp_enable.rmempty = true
    kcp_enable.default = '0'
    kcp_enable:depends('type', 'ssr')
    kcp_enable:depends('type', 'ss')

    o = s:option(Value, 'kcp_port', translate('KcpTun Port'))
    o.datatype = 'port'
    o.default = 4000
    function o.validate(self, value, section)
        local kcp_file = '/usr/bin/kcptun-client'
        local enable = kcp_enable:formvalue(section) or kcp_enable.disabled
        if enable == kcp_enable.enabled then
            if not fs.access(kcp_file) then
                return nil, translate("Haven't a Kcptun executable file")
            elseif not isKcptun(kcp_file) then
                return nil, translate('Not a Kcptun executable file')
            end
        end

        return value
    end
    o:depends('type', 'ssr')
    o:depends('type', 'ss')

    o = s:option(Value, 'kcp_password', translate('KcpTun Password'))
    o.password = true
    o:depends('type', 'ssr')
    o:depends('type', 'ss')

    o = s:option(Value, 'kcp_param', translate('KcpTun Param'))
    o.default = '--nocomp'
    o:depends('type', 'ssr')
    o:depends('type', 'ss')
end

return m
