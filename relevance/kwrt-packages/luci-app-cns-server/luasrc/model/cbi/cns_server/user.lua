local d = require "luci.dispatcher"
local appname = "cns_server"
local sys = require "luci.sys"


m = Map(appname, translate("Server Config"))
m.redirect = d.build_url("admin", "services", appname)

s = m:section(NamedSection, arg[1], "user", "")
s.addremove = false
s.dynamic = false


-- 设置开关
enable = s:option(Flag, "enable", translate("Enabled"))

-- 备注
remark = s:option(Value, "remarks", translate("Remarks"))

-- 监听端口
port = s:option(DynamicList, "port", translate("ports"))
port.default = "2222"
port.datatype = "range(1,65535)"

-- 设定请求头中获取的HOST的KEY，默认HOST
proxy_host = s:option(Value, "proxy_key", translate("Proxy Key"), translate("Set the KEY of the HOST obtained in the request header, the default HOST"))
proxy_host.default = "Host"

-- 加密密码
encrypt_password = s:option(Value, "encrypt_password", translate("Password"))
encrypt_password.default = "password"

-- Tls
tls = s:option(Flag, "tls", translate("TLS"))
tls.default = 0
tls.validate = function(self, value, t)
    if value then
        if value == "1" then
            local ca = tls_certificateFile:formvalue(t) or ""
            local key = tls_keyFile:formvalue(t) or ""
            if ca == "" or key == "" then
                return nil, translate("Public key and Private key path can not be empty!")
            end
        end
        return value
    end
end

-- 自动生成指定host的ssl/tls证书(如果留空则所有host都可以连接)
auto_cert_hosts = s:option(DynamicList,'tls_auto_cert_host','指定Host',"")
auto_cert_hosts:depends('tls',1)

-- 手动指定cert和key文件, 两者必须同时存在
cert_file = s:option(Value, "tls_cert_file", "Public key absolute path",translate('example')..":/etc/ssl/cert.pem")
cert_file:depends('tls',1)

key_file = s:option(Value,'tls_key_file','Private key absolute path',translate('example')..":/etc/ssl/key.pem")
key_file:depends('tls',1)

-- Tcp超时时间
tcp_timeout = s:option(Value,'Tcp_timeout',translate("Tcp timeout"))
tcp_timeout.default = 600

-- udp超时时间
udp_timeout = s:option(Value,'Udp_timeout',translate("UDP超时时间"))
udp_timeout.default = 30


-- 开启tcpDNS转udpDNS, 可稍微加快DNS解析速度, 默认关闭
enable_dns_tcpOverUdp  = s:option(Flag,'Enable_dns_tcpOverUdp', translate("tcpDNS to udpDNS"),translate("Turn on tcpDNS to udpDNS, which can slightly speed up the DNS resolution speed, and it is disabled by default"))
enable_dns_tcpOverUdp.default = 0

-- 开启TcpDNS,HTTPDNS无需http_tunnel握手，可以稍微加快DNS解析速度，默认关闭
enable_httpDNS = s:option(Flag,"Enable_httpDNS",translate("Enable tcpDNS"), translate("Enable TcpDNS, HTTPDNS does not require http_tunnel handshake, which can slightly speed up DNS resolution, and is disabled by default"))
enable_httpDNS.default = 0

-- 开启tcpFastOpen, 可稍微加快创建连接速度(免流可能不适用), 默认关闭
Enable_TFO = s:option(Flag,"Enable_TFO",translate("Enable tcpFastOpen"),translate("Turn on tcpFastOpen, which can slightly speed up the connection creation speed (free flow may not be applicable), and it is closed by default"))
Enable_TFO.default = false

-- 保存动作
m.on_after_commit = function (self)
    if self.changed then
        -- 执行配置文件的生成
        sys.exec("/etc/init.d/cns_server restart")
    end
end

return m