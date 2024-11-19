#!/usr/bin/lua
local ucursor = require "luci.model.uci"
local json = require "luci.jsonc"
local nixiofs = require "nixio.fs"

local general_section = ucursor:get_first("xjay", "general")
local general = ucursor:get_all("xjay", general_section)

local inbound_section = ucursor:get_first("xjay", "inbound")
local inbound = ucursor:get_all("xjay", inbound_section)

local outbound_section = ucursor:get_first("xjay", "outbound")
local outbound = ucursor:get_all("xjay", outbound_section)

local dns_section = ucursor:get_first("xjay", "dns")
local dns = ucursor:get_all("xjay", dns_section)

local routing_section = ucursor:get_first("xjay", "routing")
local routing = ucursor:get_all("xjay", routing_section)

local misc_section = ucursor:get_first("xjay", "misc")
local misc = ucursor:get_all("xjay", misc_section)

local function tcp_settings(data, direction)
    if data.stream_network == "tcp" then
        local acceptproxyprotocal = data.tcp_acceptproxyprotocol == "true" and true or false

        return {
            acceptProxyProtocol = direction == "inbound" and acceptproxyprotocal or nil,
            header = {
                type = data.tcp_type,
                request = data.tcp_type == "http" and {
                    version = "1.1",
                    method = "GET",
                    path = data.http_path,
                    headers = {
                        Host = data.http_host,
                        User_Agent = {
                            "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36",
                            "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46"
                        },
                        Accept_Encoding = {"gzip, deflate"},
                        Connection = {"keep-alive"},
                        Pragma = "no-cache"
                    }
                } or nil,
                response = data.tcp_type == "http" and {
                    version = "1.1",
                    status = "200",
                    reason = "OK",
                    headers = {
                        Content_Type = {"application/octet-stream", "video/mpeg"},
                        Transfer_Encoding = {"chunked"},
                        Connection = {"keep-alive"},
                        Pragma = "no-cache"
                    }
                } or nil
            } or nil
        }
    else
        return nil
    end
end

local function kcp_settings(data, direction)
    if data.stream_network == "kcp" then
        return {
            mtu = data.kcp_mtu ~= nil and tonumber(data.kcp_mtu) or nil,
            tti = data.kcp_tti ~= nil and tonumber(data.kcp_tti) or nil,
            uplinkCapacity = data.kcp_uplinkcapacity ~= nil and tonumber(data.kcp_uplinkcapacity) or nil,
            downlinkCapacity = data.kcp_downlinkcapacity ~= nil and tonumber(data.kcp_downlinkcapacity) or nil,
            congestion = data.kcp_congestion == "true" and true or false,
            readBufferSize = data.kcp_readbuffersize ~= nil and  tonumber(data.kcp_readbuffersize) or nil,
            writeBufferSize = data.kcp_writebuffersize ~= nil and tonumber(data.kcp_writebuffersize) or nil,
            seed = data.kcp_seed,
            header = {
                type = data.kcp_type
            }
        }
    else
        return nil
    end
end

local function ws_settings(data, direction)
    if data.stream_network == "ws" then
        local acceptproxyprotocal = nil

        if direction == "inbound" then
            acceptproxyprotocal = data.ws_acceptproxyprotocol == "true" and true or false
        end

        return {
            acceptProxyProtocol = acceptproxyprotocal,
            path = data.ws_path,
            headers = data.ws_host ~= nil and {
                Host = data.ws_host
            } or nil
        }
    else
        return nil
    end
end

local function http_settings(data, direction)
    if data.stream_network == "h2" then
        local readidletimeout = nil
        local healthchecktimeout = nil
        local http_settings = {}

        http_settings.host = data.http_host
        http_settings.path = data.http_path
        if direction == "outbound" then
            http_settings.read_idle_timeout = data.http_readidletimeout ~= nil and tonumber(data.http_readidletimeout) or nil
            http_settings.health_check_timeout = data.http_healthchecktimeout ~= nil and tonumber(data.http_healthchecktimeout) or nil
        end
        http_settings.method = data.http_method
        -- headers not implemented yet

        return next(http_settings) ~= nil and http_settings or nil
    else
        return nil
    end
end

local function quic_settings(data, direction)
    if data.stream_network == "quic" then
        return {
            security = data.quic_security,
            key = data.quic_key,
            header = {
                type = data.quic_type
            }
        }
    else
        return nil
    end
end

local function ds_settings(data, direction)
    if data.stream_network == "ds" and direction == "inbound" then
        return {
            path = data.ds_path,
            abstract = data.ds_abstract == "true" and true or false,
            padding = data.ds_padding == "true" and true or false
        }
    else
        return nil
    end
end

local function grpc_settings(data, direction)
    if (data.stream_network == "grpc") then
        local multimode = nil
        local idletimeout = nil
        local healthchecktimeout = nil
        local initialwindowssize = nil
        local useragent = nil

        if direction == "outbound" then
            multimode = data.grpc_multimode == "true" and true or false
            idletimeout = data.grpc_idletimeout ~= nil and tonumber(data.grpc_idletimeout) or nil
            healthchecktimeout = data.grpc_healthchecktimeout ~= nil and tonumber(data.grpc_healthchecktimeout) or nil
            permitwithoutstream = data.grpc_permitwithoutstream == "true" and true or false
            initialwindowssize = data.grpc_initialwindownsize ~= nil and tonumber(data.grpc_initialwindownsize) or nil
            useragent = data.grpc_useragent
        end

        return {
            serviceName = data.grpc_servicename,
            multiMode = multimode,
            idle_timeout = idletimeout,
            health_check_timeout = healthchecktimeout,
            permit_without_stream = permitwithoutstream,
            initial_windows_size = initialwindowssize,
            user_agent = useragent
        }
    else
        return nil
    end
end

local function tls_settings(data, direction)
    local result = {}

    if direction == "outbound" then
        local pinnedpeercertificatechainsha256 = {}

        for _, x in ipairs(data.pinnedpeercertificatechainsha256 ~= nil and data.pinnedpeercertificatechainsha256 or {}) do
            table.insert(pinnedpeercertificatechainsha256, x)
        end

        result.serverName = data.tls_servername
        result.allowInsecure = data.tls_allowinsecure == "true" and true or false
        result.disableSystemRoot = data.tls_disablesystemroot == "true" and true or false
        result.enableSessionResumption = data.tls_enablesessionresumption == "true" and true or false
        result.fingerprint = data.tls_fingerprint or ""
        result.pinnedPeerCertificateChainSha256 = next(pinnedpeercertificatechainsha256) ~= nil and pinnedpeercertificatechainsha256 or nil
    end

    if direction == "inbound" then
        local ciphersuites = {}

        for i, v in ipairs(data.tls_ciphersuites ~= nil and data.tls_ciphersuites or {}) do
            if i > 1 then v = ":" .. v end
            ciphersuites[#ciphersuites+1] = tostring(v)
        end

        result.rejectUnknownSni = data.tls_rejectnuknownsni == "true" and true or false
        result.minVersion = data.tls_minversion
        result.maxVersion = data.tls_maxversion
        result.cipherSuites = next(ciphersuites) and table.concat(ciphersuites) or nil
        result.certificates = {
            {
                ocspStapling = data.cert_ocspStapling ~= nil and tonumber(data.cert_ocspStapling) or nil,
                oneTimeLoading = data.cert_onetimeloading == "true" and true or false,
                usage = data.cert_usage,
                certificateFile = data.cert_certificatefile,
                keyFile = data.cert_certificatekeyfile
            }
        }
    end

    if data.tls_alpn ~= nil then
        local alpn = {}
        for _, x in ipairs(data.tls_alpn) do
            table.insert(alpn, x)
        end
        result.alpn = alpn
    end

    return result
end

local function reality_settings(data, direction)
    local result = {}

    result.show = data.reality_show == "true" and true or false

    if direction == "outbound" then
        result.serverName = data.reality_servername
        result.fingerprint = data.reality_fingerprint
        result.shortId = data.reality_shortid
        result.publicKey = data.reality_publickey
        result.spiderX = data.reality_spiderx or ""
    end

    if direction == "inbound" then
        local servernames = {}
        local shortids = {}

        for _, x in ipairs(data.reality_servername ~= nil and data.reality_servername or {}) do
            table.insert(servernames, x)
        end
        for _, x in ipairs(data.reality_shortid ~= nil and data.reality_shortid or {}) do
            table.insert(shortids, x)
        end

        result.dest = data.reality_dest
        result.xver = data.reality_xver ~= nil and tonumber(data.reality_xver) or nil
        result.serverNames = next(servernames) ~= nil and servernames or nil
        result.privateKey = data.reality_privatekey
        result.minClientVer = data.reality_minclientver
        result.maxClientVer = data.reality_maxclientver
        result.maxTimeDiff = data.reality_maxtimediff ~= nil and tonumber(data.reality_maxtimediff) or nil
        result.shortIds = next(shortids) ~= nil and shortids or nil
    end

    return result
end

local function sockopt_settings(data, direction)
    local tproxy = nil
    local acceptproxyprotocal = nil
    local tcpcongestion = nil
    local dialerproxy = nil
    local mark = nil
    local tcpkeepaliveinterval = nil
    local interface = nil

    if direction == "inbound" then
        tproxy = data.sockopt_tproxy
        acceptproxyprotocal = data.sockopt_acceptproxyprotocol == "true" and true or false
        tcpcongestion = data.sockopt_tcpcongestion
    elseif direction == "outbound" then
        dialerproxy = data.sockopt_dialerproxy
        mark = outbound.sockopt_mark ~= nil and tonumber(outbound.sockopt_mark) or nil
        tcpkeepaliveinterval = data.sockopt_tcpkeepaliveinterval ~= nil and tonumber(data.sockopt_tcpkeepaliveinterval) or nil
        interface = data.sockopt_interface
    end

    return {
        mark = mark,
        tcpFastOpen = data.sockopt_tcpfastopen == "true" and true or false,
        tproxy = tproxy,
        domainStrategy = data.sockopt_domainstrategy,
        dialerProxy = dialerproxy,
        acceptProxyProtocol = acceptproxyprotocal,
        tcpKeepAliveInterval =tcpkeepaliveinterval,
        tcpcongestion = tcpcongestion,
        interface = interface
    }
end

local function mux_settings(data, direction)
    if data.mux_enabled == "true" and direction == 'outbound' then
        return {
            enabled = data.mux_enabled == "true" and true or false,
            concurrency = data.mux_concurrency ~= nil and tonumber(data.mux_concurrency) or nil,
            xudpConcurrency = data.mux_xudpconcurrency ~= nil and tonumber(data.mux_xudpconcurrency) or nil,
            xudpProxyUDP443 = data.mux_xudpproxyudp443
        }
    else
        return nil
    end
end

local function stream_settings(data, direction)
    return {
        network = data.stream_network,
        security = data.stream_security,
        tlsSettings = data.stream_security == "tls" and tls_settings(data, direction) or nil,
        xtlsSettings = data.stream_security == "xtls" and tls_settings(data, direction) or nil,
        realitySettings = data.stream_security == "reality" and reality_settings(data, direction) or nil,
        tcpSettings = tcp_settings(data, direction),
        kcpSettings = kcp_settings(data, direction),
        wsSettings = ws_settings(data, direction),
        httpSettings = http_settings(data, direction),
        quicSettings = quic_settings(data, direction),
        dsSettings = ds_settings(data, direction),
        grpcSettings = grpc_settings(data, direction),
        sockopt = sockopt_settings(data, direction)
    }
end

local function sniffing(data)
    local destoverride = {}
    local domainsexcluded = {}

    for i, v in ipairs(data.sniffing_destoverride ~= nil and data.sniffing_destoverride or {}) do
        table.insert(destoverride, v)
    end

    for i, v in ipairs(data.sniffing_domainsexcluded ~= nil and data.sniffing_domainsexcluded or {}) do
        table.insert(domainsexcluded, v)
    end

    return data.sniffing_enabled == "true" and {
        enabled = true,
        destOverride = next(destoverride) and destoverride or nil,
        metadataOnly = data.sniffing_metadataonly == "true" and true or false,
        domainsExcluded = next(domainsexcluded) and domainsexcluded or nil,
        routeOnly = data.sniffing_routeonly == "true" and true or false,
    } or nil
end

local function fallback(data)
    local fallbacks = {}

    for i, v in ipairs(data.fallback ~= nil and data.fallback or {}) do
        ucursor:foreach("xjay", "fallback", function(fb)
            if fb.tag == v and fb.dest ~= nil then
                local fallback = {
                    name = fb.name,
                    alpn = fb.alpn,
                    path = fb.path,
                    xver = fb.xver ~= nil and tonumber(fb.xver) or nil
                }

                -- if the dest is only a port number, then convert it to number
                if string.match(fb.dest, "%d+") == fb.dest then
                    fallback.dest = tonumber(fb.dest)
                else
                    fallback.dest = fb.dest
                end

                table.insert(fallbacks, fallback)
            end
        end)
    end

    return next(fallbacks) ~= nil and fallbacks or nil
end

local function dokodemo_inbound(data)
    local network = {}

    for i, v in ipairs(data.dokodemo_network ~= nil and data.dokodemo_network or {}) do
        if i > 1 then v = "," .. v end
        network[#network+1] = tostring(v)
    end

    return {
        address = data.dokodemo_address or nil,
        port = data.dokodemo_port ~= nil and tonumber(data.dokodemo_port) or nil,
        network = next(network) and table.concat(network) or nil,
        timeout = data.dokodemo_timeout ~= nil and tonumber(v.dokodemo_timeout) or nil,
        followRedirect = data.dokodemo_followredirect == "true" and true or false,
        userLevel = data.dokodemo_level ~= nil and tonumber(data.dokodemo_level) or nil,
        fallbacks = fallback(data)
    }
end

local function http_inbound(data)
    local accounts = {}

    for i, v in ipairs(data.http_user ~= nil and data.http_user or {}) do
        ucursor:foreach("xjay", "user", function(u)
            if u.name == v then
                local user = {
                    user = u.name,
                    pass = u.password
                }
                table.insert(accounts, user)
            end
        end)
    end

    return {
        timeout = data.http_timeout ~= nil and tonumber(data.http_timeout) or nil,
        allowTransparent = data.http_allocatransparent == "true" and true or false,
        accounts = data.http_auth == 'password' and accounts or nil,
        userLevel = data.http_level ~= nil and tonumber(data.http_level) or nil,
        fallbacks = fallback(data)
    }
end

local function shadowsocks_inbound(data)
    local network = {}
    local clients = {}

    for i, v in ipairs(data.ss_user ~= nil and data.ss_user or {}) do
        ucursor:foreach("xjay", "user", function(u)
            if u.name == v then
                local user = {
                    password = u.password,
                    method = data.ss_method,
                    email = u.email,
                    level = u.level ~= nil and tonumber(u.level) or nil
                }
                table.insert(clients, user)
            end
        end)
    end

    for i, v in ipairs(data.ss_network == nil and {} or data.ss_network) do
        if i > 1 then v = "," .. v end
        network[#network+1] = tostring(v)
    end

    return {
        clients = next(clients) and clients or nil,
        network =  next(network) and table.concat(network) or nil,
        fallbacks = fallback(data)
    }
end

local function socks_inbound(data)
    local accounts = {}

    for i, v in ipairs(data.socks_user ~= nil and data.socks_user or {}) do
        ucursor:foreach("xjay", "user", function(u)
            if u.name == v then
                local user = {
                    user = u.name,
                    pass = u.password
                }
                table.insert(accounts, user)
            end
        end)
    end

    return {
        auth = data.socks_auth,
        accounts = data.socks_auth == 'password' and accounts or nil,
        udp = data.socks_udp == "true" and true or false,
        ip = data.socks_ip,
        userLevel = data.socks_level ~= nil and tonumber(data.socks_level) or nil,
        fallbacks = fallback(data)
    }
end

local function trojan_inbound(data)
    local clients = {}

    for i, v in ipairs(data.trojan_user ~= nil and data.trojan_user or {}) do
        ucursor:foreach("xjay", "user", function(u)
            if u.name == v then
                local user = {
                    password = u.password,
                    email = u.email,
                    level = u.level ~= nil and tonumber(u.level) or nil
                }
                table.insert(clients, user)
            end
        end)
    end

    return {
        clients = next(clients) and clients or nil,
        fallbacks = fallback(data)
    }
end

local function vless_inbound(data)
    local clients = {}

    for i, v in ipairs(data.vless_user ~= nil and data.vless_user or {}) do
        ucursor:foreach("xjay", "user", function(u)
            if u.name == v then
                local user = {
                    id = u.password,
                    flow = data.vless_flow ~= "none" and data.vless_flow or "",
                    email = u.email,
                    level = u.level ~= nil and tonumber(u.level) or nil
                }
                table.insert(clients, user)
            end
        end)
    end

    return {
        clients = next(clients) and clients or nil,
        decryption = "none",
        fallbacks = fallback(data)
    }
end

local function vmess_inbound(data)
    local clients = {}

    for i, v in ipairs(data.vmess_user ~= nil and data.vmess_user or {}) do
        ucursor:foreach("xjay", "user", function(u)
            if u.name == v then
                local user = {
                    id = u.password,
                    alterId = data.vmess_alterid ~= nil and tonumber(data.vmess_alterid) or nil,
                    email = u.email,
                    level = u.level ~= nil and tonumber(u.level) or nil
                }
                table.insert(clients, user)
            end
        end)
    end

    return {
        clients = next(clients) and clients or nil,
        default = {
            alterId = 0,
            level = 0
        },
        detour = data.vmess_detour ~= nil and {
            to = data.vmess_detour
        } or nil,
        fallbacks = fallback(data)
    }
end

local function inbound_service(data)
    local inbound_settings = {}
    if data.protocol == "dokodemo-door" then
        inbound_settings = dokodemo_inbound(data)
    elseif data.protocol == "http" then
        inbound_settings = http_inbound(data)
    elseif data.protocol == "shadowsocks" then
        inbound_settings = shadowsocks_inbound(data)
    elseif data.protocol == "socks" then
        inbound_settings = socks_inbound(data)
    elseif data.protocol == "trojan" then
        inbound_settings = trojan_inbound(data)
    elseif data.protocol == "vless" then
        inbound_settings = vless_inbound(data)
    elseif data.protocol == "vmess" then
        inbound_settings = vmess_inbound(data)
    end
    return {
        tag = data.tag,
        listen = data.listen,
        port = tonumber(data.port),
        protocol = data.protocol,
        settings = inbound_settings,
        streamSettings = stream_settings(data, "inbound"),
        sniffing = sniffing(data)
    }
end

local function blackhole_outbound()
    return {
        tag = "blackhole",
        protocol = "blackhole"
    }
end

local function dns_outbound()
    return {
        protocol = "dns",
        tag = "dns",
        streamSettings = {
            sockopt = {
                mark = outbound.sockopt_mark ~= nil and tonumber(outbound.sockopt_mark) or nil
            }
        }
    }
end

local function direct_outbound()
    return {
        protocol = "freedom",
        tag = "direct",
        streamSettings = {
            sockopt = {
                mark = outbound.sockopt_mark ~= nil and tonumber(outbound.sockopt_mark) or nil
            }
        }
    }
end

local function http_outbound(data)
    return {
        servers = {
            {
                address = data.address,
                port = tonumber(data.port),
                users = {
                    {
                        user = data.http_user,
                        pass = data.http_pass
                    }
                }
            }
        }
    }
end

local function shadowsocks_outbound(data)
    return {
        servers = {
            {
                address = data.address,
                port = tonumber(data.port),
                method = data.ss_method, -- encryption algorithim
                password = data.ss_password,
                uot = data.ss_uot == "true" and true or false, -- udp over tcp
                email = data.ss_email or nil, -- optional, for identifying a user
                level = data.ss_level ~= nil and tonumber(data.ss_level) or nil
            }
        }
    }
end

local function socks_outbound(data)
    return {
        servers = {
            {
                address = data.address,
                port = tonumber(data.port),
                users = {
                    {
                        user = data.socks_user,
                        pass = data.socks_pass,
                        level = data.socks_level ~= nil and tonumber(data.socks_level) or nil
                    }
                }
            }
        }
    }
end

local function trojan_outbound(data)
    return {
        servers = {
            {
                address = data.address,
                port = tonumber(data.port),
                password = data.trojan_password,
                email = data.trojan_email or nil, -- optional, for identifying a user
                level = data.trojan_level ~= nil and tonumber(data.trojan_level) or nil
            }
        }
    }
end

local function vless_outbound(data)
    return {
        vnext = {
            {
                address = data.address,
                port = tonumber(data.port),
                users = {
                    {
                        id = data.vless_id,
                        flow = data.vless_flow ~= "none" and data.vless_flow or "",
                        encryption = data.vless_encryption, -- encryption algorithim, for vless, currently only none
                        level = data.vless_level ~= nil and tonumber(data.vless_level) or nil
                    }
                }
            }
        }
    }
end

local function vmess_outbound(data)
    return {
        vnext = {
            {
                address = data.address,
                port = tonumber(data.port),
                users = {
                    {
                        id = data.vmess_id,
                        alterId = data.vmess_alterid ~= nil and tonumber(data.vmess_alterid) or nil,
                        security = data.vmess_security, -- encryption algorithim
                        level = data.vmess_level ~= nil and tonumber(data.vmess_level) or nil
                    }
                }
            }
        }
    }
end

local function outbound_server(data)
    local outbound_settings = {}

    if data.protocol == "http" then
        outbound_settings = http_outbound(data)
    elseif data.protocol == "shadowsocks" then
        outbound_settings =  shadowsocks_outbound(data)
    elseif data.protocol == "socks" then
        outbound_settings =  socks_outbound(data)
    elseif data.protocol == "trojan" then
        outbound_settings =  trojan_outbound(data)
    elseif data.protocol == "vless" then
        outbound_settings =  vless_outbound(data)
    elseif data.protocol == "vmess" then
        outbound_settings =  vmess_outbound(data)
    end

    return {
        tag = data.tag,
        sendThrough = data.sendthrough,
        protocol = data.protocol,
        settings = outbound_settings,
        streamSettings = stream_settings(data, "outbound"),
        mux = mux_settings(data, 'outbound')
    }
end

local function logging()
    return {
        access = misc.log_access == "true" and "" or "none",
        error = misc.log_error == "true" and "" or "none",
        loglevel = misc.log_level or "warning",
        dnsLog = misc.log_dnslog == "true" and true or false
    }
end

local function inbounds()
    local inbounds = {}
    ucursor:foreach("xjay", "inbound_service", function(data)
        table.insert(inbounds, inbound_service(data))
    end)
    return inbounds
end

local function outbounds()
    local outbounds = {}
    local function is_outbound_created(tag)
        for i, v in ipairs(outbounds) do
            if tag == v.tag then
                return true
            end
        end
        return false
    end

    -- generating outbounds based on ruouting outbound tags
    ucursor:foreach("xjay", "outbound_server", function(data)
        -- insert default oubound in the first
        if data.tag == outbound.default_outbound then table.insert(outbounds, 1, outbound_server(data)) end

        -- append other outbounds from routing rules in the last
        ucursor:foreach("xjay", "routing_rule", function(dd)
            if data.tag == dd.rule_outboundtag and not is_outbound_created(dd.rule_outboundtag) then
                table.insert(outbounds, outbound_server(data))
            end
        end)
    end)

    -- generating some pre-defined outbounds
    if outbound.default_outbound == "direct" then
        table.insert(outbounds, 1, direct_outbound())
    else
        table.insert(outbounds, direct_outbound())
    end

    if outbound.default_outbound == "blackhole" then
        table.insert(outbounds, 1, blackhole_outbound())
    else
        table.insert(outbounds, blackhole_outbound())
    end

    table.insert(outbounds, dns_outbound())

    return outbounds
end

local function dnss()
    local hosts = {}
    local servers = {}

    for i, v in ipairs(dns.host == nil and {} or dns.host) do
        -- break string "/dns.google/8.8.8.8" into table tab = { "dns.google", "8.8.8.8" }
        local tab = {}
        for w in v:gmatch("([^/]+)") do table.insert(tab, w) end
        -- then add them as key value pair into hosts table
        -- will be hosts = { dns.google = "8.8.8.8" }
        -- not elegant but working
        hosts[ tab[1] ] = tab[2]
    end

    ucursor:foreach("xjay", "dns_server", function(data)
        local domains = {}
        local expectedips = {}
        local function is_domain_inserted(domain)
            for i, v in ipairs(domains) do
                if domain == v then
                    return true
                end
            end
            return false
        end

        for i, v in ipairs(data.server_domain == nil and {} or data.server_domain) do
            table.insert(domains, v)
        end

        -- get domains from routing rules domain list
        ucursor:foreach("xjay", "routings", function(dd)
            if data.alias == dd.dns_server then
                for i, v in ipairs(dd.rule_domain == nil and {} or dd.rule_domain) do
                    if not is_domain_inserted(v) then table.insert(domains, v) end
                end
            end
        end)

        for i, v in ipairs(data.server_expectedip == nil and {} or data.server_expectedip) do
            table.insert(expectedips, v)
        end

        local server = {
            queryStrategy = data.querystrategy,
            address = data.server_address ~= nil and data.server_address or nil,
            port = data.server_port ~= nil and tonumber(data.server_port) or nil,
            skipFallback = data.server_skipfallback == "true" and true or false,
            domains = next(domains) and domains or nil,
            expectIPs = next(expectedips) and expectedips or nil,
            clientIP = data.server_clientip
        }

        table.insert(servers, server)
    end)

    for i, v in ipairs(dns.alt_dns == nil and {} or dns.alt_dns) do
        table.insert(servers, v)
    end

    return {
        tag = dns.tag,
        clientIP = dns.clientip,
        queryStrategy = dns.querystrategy,
        disableCache = dns.disablecache == "true" and true or false,
        disableFallback = dns.disablefallback == "true" and true or false,
        disableFallbackIfMatch = dns.disablefallbackifmatch == "true" and true or false,
        hosts = next(hosts) and hosts or nil,
        servers = next(servers) and servers or nil
    }
end

local function routings()
    local rules = {}

    ucursor:foreach("xjay", "routing_rule", function(data)
        local domain = {}
        local ip = {}
        local port = {}
        local source = {}
        local sourceport = {}
        local network = {}
        local protocol = {}
        local inboundtag = {}

        for i, v in ipairs(data.rule_domain == nil and {} or data.rule_domain) do
            table.insert(domain, v)
        end

        for i, v in ipairs(data.rule_ip == nil and {} or data.rule_ip) do
            table.insert(ip, v)
        end

        if data.rule_port == nil then
            port = nil
        elseif #data.rule_port == 1 then
            port = tonumber(data.rule_port[1])
        elseif #data.rule_port > 1 then
            for i, v in ipairs(data.rule_port) do
                port[#port+1] = tostring(i == 1 and v or "," .. v)
            end
            port = table.concat(port)
        end

        for i, v in ipairs(data.rule_source == nil and {} or data.rule_source) do
            table.insert(source, v)
        end

        if data.rule_sourceport == nil then
            sourceport = nil
        elseif #data.rule_sourceport == 1 then
            sourceport = tonumber(data.rule_sourceport[1])
        elseif #data.rule_sourceport > 1 then
            for i, v in ipairs(data.rule_sourceport) do
                sourceport[#sourceport+1] = tostring(i == 1 and v or "," .. v)
            end
            sourceport = table.concat(sourceport)
        end

        for i, v in ipairs(data.rule_network == nil and {} or data.rule_network) do
            if i > 1 then v = "," .. v end
            network[#network+1] = tostring(v)
        end

        for i, v in ipairs(data.rule_protocol == nil and {} or data.rule_protocol) do
            table.insert(protocol, v)
        end

        for i, v in ipairs(data.rule_inboundtag == nil and {} or data.rule_inboundtag) do
            table.insert(inboundtag, v)
        end

        local rule = {
            domainMatcher = data.domain_matcher == nil and nil or data.domain_matcher,
            type = "field",
            domain = next(domain) and domain or nil,
            ip = next(ip) and ip or nil,
            port = port,
            source = next(source) and source or nil,
            sourcePort = sourceport,
            network = next(network) and table.concat(network) or nil,
            protocol = next(protocol) and protocol or nil,
            attrs = data.rule_attrs,
            inboundTag = next(inboundtag) and inboundtag or nil,
            outboundTag = data.rule_outboundtag
        }

        table.insert(rules, rule)
    end)

    return {
        domainStrategy = routing.domainstrategy,
        domainMatcher = routing.domainmatcher,
        rules = rules
    }
end

local xray = {
    log = logging(),
    inbounds = inbounds(),
    outbounds = outbounds(),
    dns = dnss(),
    routing = routings()
}

print(json.stringify(xray, true))
