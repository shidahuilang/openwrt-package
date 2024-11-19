require "nixio.fs"
require "luci.sys"
require "luci.http"
local m, s, o
local sid = arg[1]
local uuid = luci.sys.exec("cat /proc/sys/kernel/random/uuid")

function is_finded(e)
	return luci.sys.exec('type -t -p "%s"' % e) ~= "" and true or false
end

local server_table = {}

local encrypt_methods_v2ray_ss = {
	-- xray_ss
	"none",
	"plain",
	-- aead
	"aes-128-gcm",
	"aes-256-gcm",
	"chacha20-poly1305",
	"chacha20-ietf-poly1305",
	"xchacha20-ietf-poly1305",
	"2022-blake3-aes-128-gcm",
	"2022-blake3-aes-256-gcm"
}

local securitys = {
	-- vmess
	"auto",
	"aes-128-gcm",
	"chacha20-poly1305"
}

local flows = {
	-- xlts
	"xtls-rprx-vision",
	"xtls-rprx-vision-udp443"
}

m = Map("xclient", "Add/Edit Server")
m.redirect = luci.dispatcher.build_url("admin/services/xclient/servers")
if m.uci:get("xclient", sid) ~= "servers" then
	luci.http.redirect(m.redirect)
	return
end


-- [[ Servers Setting ]]--
s = m:section(NamedSection, sid, "servers")
s.anonymous = true
s.addremove = false


o = s:option(ListValue, "protocol", "Protocol")
o:value("vmess", "Vmess")
o:value("vless", "Vless")
o:value("trojan", "Trojan")
o:value("shadowsocks", "Shadowsocks")
o:value("shadowsocks-plugin", "Shadowsocks-Plugin")

o = s:option(Value, "alias", "Remarks")

o = s:option(Value, "server", "Server Address")
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "server_port", "Server Port")
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "password", "Password")
o.password = true
o.rmempty = true
o:depends({protocol = "shadowsocks"})
o:depends({protocol = "shadowsocks-plugin"})
o:depends({protocol = "trojan"})

o = s:option(ListValue, "encrypt_method_v2ray_ss", "Encrypt Method")
for _, v in ipairs(encrypt_methods_v2ray_ss) do
	o:value(v)
end
o.rmempty = true
o:depends({protocol = "shadowsocks"})
o:depends({protocol = "shadowsocks-plugin"})


o = s:option(Flag, "ivCheck", "Bloom Filter")
o.rmempty = true
o:depends({protocol = "shadowsocks"})
o.default = "1"

-- Shadowsocks Plugin
o = s:option(ListValue, "plugin", "Plugin")
-- o:value("none", "None")
if is_finded("xray-plugin") then
 	o:value("xray-plugin", "xray-plugin")
end
o.rmempty = true
o:depends("protocol", "shadowsocks-plugin")

o = s:option(Value, "plugin_opts", "Plugin Opts")
o.rmempty = true
o:depends({protocol = "shadowsocks-plugin", plugin = "v2ray-plugin"})
o:depends({protocol = "shadowsocks-plugin", plugin = "xray-plugin"})

-- VmessId
o = s:option(Value, "vmess_id", "UUID")
o.rmempty = true
o.default = uuid
o:depends({protocol = "vmess"})
o:depends({protocol = "vless"})

-- VLESS Encryption
o = s:option(Value, "vless_encryption", "Vless Encryption")
o.rmempty = true
o.default = "none"
o:depends({protocol = "vless"})

o = s:option(ListValue, "vmess_encryption", "Encrypt Method")
for _, v in ipairs(securitys) do
	o:value(v, v:upper())
end
o.rmempty = true
o:depends({protocol = "vmess"})

-- Transport
o = s:option(ListValue, "transport", "Transport")
o:value("tcp", "TCP")
o:value("kcp", "mKCP")
o:value("ws", "WebSocket")
o:value("h2", "HTTP/2")
o:value("grpc", "gRPC")
o:value("quic", "QUIC")
o.rmempty = true

-- [[ TCP ]]--

o = s:option(ListValue, "tcp_guise", "Camouflage Type")
o:value("none", "None")
o:value("http", "HTTP")
o.rmempty = true
o:depends({protocol = "vmess",transport = "tcp"})
o:depends({protocol = "trojan" ,transport = "tcp"})
o:depends({protocol = "vless",transport = "tcp"})


o = s:option(Value, "http_host", "HTTP Host")
o:depends("tcp_guise", "http")
o.rmempty = true

o = s:option(Value, "http_path", "HTTP Path")
o:depends("tcp_guise", "http")
o.rmempty = true

-- [[ WS ]]--

o = s:option(Value, "ws_host", "WebSocket Host")
o:depends({transport = "ws"})
o.datatype = "hostname"
o.rmempty = true

o = s:option(Value, "ws_path", "WebSocket Path")
o:depends("transport", "ws")
o.rmempty = true

-- [[ H2 ]]--

o = s:option(Value, "h2_host", "HTTP/2 Host")
o:depends("transport", "h2")
o.rmempty = true

o = s:option(Value, "h2_path", "HTTP/2 Path")
o:depends("transport", "h2")
o.rmempty = true

-- gRPC
o = s:option(Value, "serviceName", "ServiceName")
o:depends("transport", "grpc")
o.rmempty = true

o = s:option(Value, "initial_windows_size", "Initial Windows Size")
o.datatype = "uinteger"
o:depends("transport", "grpc")
o.default = 0
o.rmempty = true

o = s:option(Flag, "health_check", "Health Check")
o:depends("transport", "h2")
o:depends("transport", "grpc")
o.rmempty = true

o = s:option(Value, "read_idle_timeout", "Idle Timeout")
o.datatype = "uinteger"
o:depends({health_check = true, transport = "h2"})
o.default = 60
o.rmempty = true

o = s:option(Value, "idle_timeout", "Idle Timeout")
o.datatype = "uinteger"
o:depends({health_check = true, transport = "grpc"})
o.default = 60
o.rmempty = true

o = s:option(Value, "health_check_timeout", "Health Check Timeout")
o.datatype = "uinteger"
o:depends("health_check", 1)
o.default = 20
o.rmempty = true

o = s:option(Flag, "permit_without_stream", "Permit Without Stream")
o:depends({health_check = true, transport = "grpc"})
o.rmempty = true


-- [[ mKCP ]]--
o = s:option(ListValue, "kcp_guise", "Camouflage Type")
o:depends("transport", "kcp")
o:value("none", "None")
o:value("srtp", "VideoCall (SRTP)")
o:value("utp", "BitTorrent (uTP)")
o:value("wechat-video", "WechatVideo")
o:value("dtls", "DTLS 1.2")
o:value("wireguard", "WireGuard")
o.rmempty = true

o = s:option(Value, "mtu", "MTU")
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 1350
o.rmempty = true

o = s:option(Value, "tti", "TTI")
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 50
o.rmempty = true

o = s:option(Value, "uplink_capacity", "Uplink Capacity")
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 5
o.rmempty = true

o = s:option(Value, "downlink_capacity", "Downlink Capacity")
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 20
o.rmempty = true

o = s:option(Value, "read_buffer_size", "Read Buffer Size")
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 2
o.rmempty = true

o = s:option(Value, "write_buffer_size", "Write Buffer Size")
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 2
o.rmempty = true

o = s:option(Value, "seed", "Seed (optional)")
o:depends({protocol = "vless", transport = "kcp"})
o.rmempty = true

o = s:option(Flag, "congestion", "Congestion")
o:depends("transport", "kcp")
o.rmempty = true

-- [[ QUIC ]]--
o = s.option(ListValue,"quic_security", "[quic] Security")
o:depends("transport", "quic")
o.default = "none"
o:value("none", "none")
o:value("aes-128-gcm", "aes-128-gcm")
o:value("chacha20-poly1305", "chacha20-poly1305")
o.rmempty = true


o = s.option(Value, "quic_key", "[quic] Key")
o:depends("transport", "quic")
o.rmempty = true


o = s.option(ListValue, "quic_guise", "[quic] Fake Header Type")
o:depends("transport", "quic")
o.default = "none"
o:value("none", _("None"))
o:value("srtp", _("VideoCall (SRTP)"))
o:value("utp", _("BitTorrent (uTP)"))
o:value("wechat-video", _("WechatVideo"))
o:value("dtls", "DTLS 1.2")
o:value("wireguard", "WireGuard")
o.rmempty = true

		
-- [[ security ]]--
o = s:option(ListValue, "security", "Security")
o.default = "none"
o:value("none", "none")
o:value("tls", "tls")
o:value("reality", "reality")
o.rmempty = false

-- Flow
o = s:option(Value, "vless_flow", "Flow")
for _, v in ipairs(flows) do
	o:value(v, v)
end
o.rmempty = true
o.default = "xtls-rprx-vision"
o:depends({protocol = "vless", transport = "tcp"})

o = s:option(Value, "tls_host", "TLS Host / serverName")
o.datatype = "hostname"
o:depends({security = 'tls', security = 'reality'})
o.rmempty = true

o = s:option(Flag, "rejectUnknownSni", "Reject Unknown Sni")
o:depends({security = 'tls'})
o.rmempty = true

-- [[ Alpn ]]--
o = s:option(DynamicList, "alpn", "Alpn")
o:value("h2", "h2")
o:value("http/1.1", "http/1.1")
o:depends({security = 'tls'})
o.rmempty = true

-- [[ uTLS ]]--
o = s:option(ListValue, "fingerprint", "Finger Print")
o:value("", "disable")
o:value("firefox", "firefox")
o:value("chrome", "chrome")
o:value("safari", "safari")
o:value("randomized", "randomized")
o:depends({security = 'tls', security = 'reality'})
o.default = "chrome"
o.rmempty = true

-- [[ ShortId ]]--
o = s:option(Value, "shortId", "ShortId")
o.default = ""
o:depends({security = 'reality'})
o.rmempty = true

-- [[ publicKey ]]--
o = s:option(Value, "publicKey", "publicKey")
o.default = ""
o:depends({security = 'reality'})
o.rmempty = true

-- [[ spiderX ]]--
o = s:option(Value, "spiderX", "spiderX")
o.default = ""
o:depends({security = 'reality'})
o.rmempty = true

-- [[ allowInsecure ]]--
o = s:option(Flag, "insecure", "AllowInsecure")
o.rmempty = true
o:depends({security = 'tls'})

-- [[ Mux ]]--
o = s:option(Flag, "mux", "Mux")
o.rmempty = true
o:depends({protocol = "shadowsocks"})

o = s:option(Value, "concurrency", "Concurrency")
o.datatype = "uinteger"
o.rmempty = true
o.default = "8"
o:depends("mux", "1")



return m
