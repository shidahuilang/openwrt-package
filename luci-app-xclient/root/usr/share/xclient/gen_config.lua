#!/usr/bin/lua 
--local ucursor = require "luci.model.uci"
local ucursor = require "luci.model.uci".cursor()
local json = require "luci.jsonc"
local nixiofs = require "nixio.fs"
 
local proxy_section = ucursor:get_first("xclient", "global")
local proxy = ucursor:get_all("xclient", proxy_section)

local tcp_server_section = proxy.global_server or nil
local tcp_server = ucursor:get_all("xclient", tcp_server_section)

local udp_server_section = proxy.udp_relay_server or nil
local udp_server = ucursor:get_all("xclient", udp_server_section)

local socks5_server_section = proxy.socks5_server or nil
local socks5_server = ucursor:get_all("xclient", socks5_server_section)

local server_section = arg[1] or nil
local node = ucursor:get_all("xclient", server_section)

local geoip_existence = false
local geosite_existence = false

local xray_data_file_iterator = nixiofs.dir("/usr/share/xclient")

local proto = arg[2]
local local_port = arg[3] or "1234"
local socks_port = arg[4] or "1080"
local _protocol = arg[5] or "redir"
local _local = arg[6] or "0"

repeat
    local fn = xray_data_file_iterator()
    if fn == "geoip.dat" then
        geoip_existence = true
    end
    if fn == "geosite.dat" then
        geosite_existence = true
    end
until fn == nil


local function direct_outbound()
    return {
        protocol = "freedom",
	settings = {
          domainStrategy = "UseIP"
        },
        tag = "direct"
    }
end

local function block_outbound()
    return {
        protocol = "blackhole",
        tag = "block",
		settings = {
		  response = {
			type = "http"
		  }
		}
    }
end

local function dns_outbound()
    return {
        protocol = "dns",
        address = "1.1.1.1",
	network = "tcp,udp",
	port = 53,
        tag = "dns_outbound"
    }
end

local function stream_tcp_fake_http_request(server)
    if server.tcp_guise == "http" then
        return {
            version = "1.1",
            method = "GET",
            path = server.http_path,
            headers = {
                Host = server.http_host,
                User_Agent = {
                    "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36",
                    "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46"
                },
                Accept_Encoding = {"gzip, deflate"},
                Connection = {"keep-alive"},
                Pragma = "no-cache"
            }
        }
    else
        return nil
    end
end

local function stream_tcp_fake_http_response(server)
    if server.tcp_guise == "http" then
        return {
            version = "1.1",
            status = "200",
            reason = "OK",
            headers = {
                Content_Type = {"application/octet-stream", "video/mpeg"},
                Transfer_Encoding = {"chunked"},
                Connection = {"keep-alive"},
                Pragma = "no-cache"
            }
        }
    else
        return nil
    end
end

local function stream_tcp(server)
    if server.transport == "tcp" then
        return {
            header = {
                type = server.tcp_guise,
                request = stream_tcp_fake_http_request(server),
                response = stream_tcp_fake_http_response(server)
            }
        }
    else
        return nil
    end
end

local function stream_h2(server)
    if (server.transport == "h2") then
        return {
            path = server.h2_path,
            host = server.h2_host,
	    read_idle_timeout = tonumber(server.read_idle_timeout) or nil,
	    health_check_timeout = tonumber(server.health_check_timeout) or nil
        }
    else
        return nil
    end
end

local function stream_grpc(server)
    if (server.transport == "grpc") then
        return {
            serviceName = server.serviceName or "",
            multiMode = server.grpc_multi_mode == "1",
            initial_windows_size = tonumber(server.initial_windows_size) or nil,
            idle_timeout = tonumber(server.idle_timeout) or nil,
            health_check_timeout = tonumber(server.health_check_timeout) or nil,
            permit_without_stream = (server.permit_without_stream == "1") and true or nil
        }
    else
        return nil
    end
end


local function stream_kcp(server)
    if server.transport == "mkcp" then
        local mkcp_seed = nil
        if server.seed ~= "" then
            mkcp_seed = server.seed
        end
        return {
            mtu = tonumber(server.mtu),
            tti = tonumber(server.tti),
            uplinkCapacity = tonumber(server.uplink_capacity),
            downlinkCapacity = tonumber(server.downlink_capacity),
            congestion = (server.congestion == "1") and true or false,
            readBufferSize = tonumber(server.read_buffer_size),
            writeBufferSize = tonumber(server.write_buffer_size),
            seed = mkcp_seed,
            header = {
                type = server.kcp_guise
            }
        }
    else
        return nil
    end
end

local function stream_quic(server)
    if server.transport == "quic" then
        return {
            security = server.quic_security,
	    key = server.quic_key,
	    header = {type = server.quic_guise}
        }
    else
        return nil
    end
end

local function stream_ws(server)
    if server.transport == "ws" then
        local headers = nil
        if (server.ws_host ~= nil) then
            headers = {
                Host = server.ws_host or server.tls_host
            }
        end
        return {
            path = server.ws_path,
            headers = headers
        }
    else
        return nil
    end
end

local function tls_settings(server)
    local result = {
        fingerprint = server.fingerprint,
        rejectUnknownSni = (server.rejectUnknownSni == "1") and true or false,
        allowInsecure = (server.insecure == "1") and true or false,
        serverName = server.tls_host,
    }
    if server.alpn ~= nil then
        local alpn = {}
        for _, x in ipairs(server.alpn) do
            table.insert(alpn, x)
        end
        result["alpn"] = alpn
    end
    return result
end

local function reality_settings(server)
    local result = {
        fingerprint = server.fingerprint,
        shortId = server.shortId,
        publicKey = server.publicKey,
        serverName = server.tls_host,
        spiderX = server.spiderX,
    }
    return result
end

local function shadowsocks_outbound(server, tag)
    return {
        protocol = "shadowsocks",
        tag = tag,
        settings = {
            servers = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    password = server.password,
                    method = server.encrypt_method_v2ray_ss
                }
            }
        },
        streamSettings = {
            network = server.transport,
            security = (server.security == 'tls') and "tls" or "none",
            tlsSettings = (server.security == 'tls')  and "tls" and tls_settings(server) or nil,
            quicSettings = stream_quic(server),
            kcpSettings = stream_kcp(server),
            tcpSettings = stream_tcp(server) and server.protocol ~= "shadowsocks" or nil,
            wsSettings = stream_ws(server),
            grpcSettings = stream_grpc(server),
            httpSettings = stream_h2(server)
        },
	mux = (server.mux == "1" and server.security == 'tls' or server.security == 'none') and {
		enabled = true,
		concurrency = tonumber(server.concurrency)
	} or nil
    }
end

local function vmess_outbound(server, tag)
    return {
        protocol = "vmess",
        tag = tag,
        settings = {
            vnext = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    users = {
                        {
                            id = server.vmess_id,
                            alterId = 0,
                            security = server.vmess_encryption
                        }
                    }
                }
            }
        },
        streamSettings = {
            network = server.transport,
            security = (server.security == 'tls') and "tls" or "none",
            tlsSettings = (server.security == 'tls')  and "tls" and tls_settings(server) or nil,
            tcpSettings = stream_tcp(server),
            wsSettings = stream_ws(server),
            grpcSettings = stream_grpc(server),
            httpSettings = stream_h2(server),
            quicSettings = stream_quic(server),
            kcpSettings = stream_kcp(server),
        }
    }
end

local function vless_outbound(server, tag)
    local flow = server.flow
    if server.flow == "none" then
        flow = nil
    end
    return {
        protocol = "vless",
        tag = tag,
        settings = {
            vnext = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    users = {
                        {
                            id = server.vmess_id,
                            flow = flow,
                            encryption = server.vless_encryption
                        }
                    }
                }
            }
        },
        streamSettings = {
            network = server.transport,
            security = (server.security == 'reality')  and "reality" or (server.security == 'tls') and "tls" or "none",
            tlsSettings = (server.security == 'tls')  and "tls" and tls_settings(server) or nil,
            realitySettings = (server.security == 'reality')  and "reality" and reality_settings(server) or nil,
            tcpSettings = stream_tcp(server),
            wsSettings = stream_ws(server),
            grpcSettings = stream_grpc(server),
            httpSettings = stream_h2(server),
            quicSettings = stream_quic(server),
            kcpSettings = stream_kcp(server),
        }
    }
end

local function trojan_outbound(server, tag)
    local flow = server.flow
    if server.flow == "none" then
        flow = nil
    end
    return {
        protocol = "trojan",
        tag = tag,
        settings = {
            servers = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    password = server.password,
                    flow = flow,
                }
            }
        },
        streamSettings = {
            network = server.transport,
            security = (server.security == 'tls') and "tls" or "none",
            tlsSettings = (server.security == 'tls')  and "tls" and tls_settings(server) or nil,
            tcpSettings = stream_tcp(server) and server.protocol ~= "trojan" or nil,
            wsSettings = stream_ws(server),
            grpcSettings = stream_grpc(server),
            httpSettings = stream_h2(server),
            quicSettings = stream_quic(server),
            kcpSettings = stream_kcp(server),
        },
		mux = (server.mux == "1" and server.security == 'tls' or server.security == 'none') and {
			enabled = true,
			concurrency = tonumber(server.concurrency)
		} or nil
    }
end

local function server_outbound(server, tag)
    if server.protocol == "vmess" then
        return vmess_outbound(server, tag)
    end
    if server.protocol == "vless" then
        return vless_outbound(server, tag)
    end
    if server.protocol == "shadowsocks" then
        return shadowsocks_outbound(server, tag)
    end
    if server.protocol == "trojan" then
        return trojan_outbound(server, tag)
    end
    return nil
end


local function proxy_inbound()
	if local_port == "0" then
		return nil
	end
	
	return {
		port = local_port,
		protocol = "dokodemo-door",
		tag = "proxy_inbound",
		sniffing =  {
			enabled = true,
			destOverride = {"http", "tls"}
		} ,
		settings = {
			network = proto,
			followRedirect = true
		}
	}
end

local function socks_inbound()
	if socks_port == "0" then
		return nil
	end
	return {
		port = socks_port,
		protocol = "socks",
		tag = "socks_inbound",
		settings = {
			auth = "noauth",
			udp = true
		}
	}
end

local function dns_inbounds()
    local servers = {}
    if proxy["dns_servers"] ~= nil then
    for _, x in ipairs(proxy["dns_servers"]) do
          table.insert(servers, x)
    end
    end
    local i = 0
    ucursor:foreach("xclient", "dns", function(v)
        i = i + 1
        table.insert(servers, {
            address = v.address or nil,
            port = v.port,
            domains = v.domains or nil,
            expectIPs = v.expectIPs or nil,
            skipFallback = v.skipFallback == "1" and true or false
        })
    end)
    return servers    
end

local function dns()
	local result = {}
	for _, v in ipairs(dns_inbounds()) do
		table.insert(result, v)
	end
	return {
		server = result,
		clientIp = proxy.clientIp or nil,
		queryStrategy = proxy.queryStrategy,
		disableCache = proxy.disableCache == "1" and true or false,
		disableFallback = proxy.disableFallback == "1" and true or false,
		disableFallbackIfMatch = proxy.disableFallbackIfMatch == "1" and true or false,
		tag = "dns_inbound"
	}
end


local function inbounds()
    local i = {}
	if proxy.global_server ~= "nil" or proxy.udp_server ~= "nil" then
		i = {
			proxy_inbound(),
		}
		if proxy.socks5_server == "same" or _local == "1" then
			table.insert(i, socks_inbound())
		end
        table.insert(i, {
            listen = "127.0.0.1",
            port = 8888,
            protocol = "dokodemo-door",
            settings = {
                address = "127.0.0.1"
            },
            tag = "api"
        })
		return i
	end
end

local function api()
    return {
        tag = "api",
        services = {
            "StatsService"
        }
    }
end


local function routing()
    local rule = {}
    local i = 0
    ucursor:foreach("xclient", "rule", function(v)
        i = i + 1
        table.insert(rule, {
            type = "field",
	    domainMatcher = v.domainMatcher or nil,
            domain = v.domain or nil,
            ip = v.ip or nil,
            port = v.port or nil,
            sourcePort = v.sourcePort or nil,
            network = v.network or nil,
            source = v.source or nil,
            inboundTag = v.inboundTag or nil,
            protocol = v.protocol or nil,
            outboundTag = v.outboundTag or nil,
        })
    end)
	table.insert(rule, {
        type =  "field",
        inboundTag = {
			"api"
		},
        outboundTag = "api",
        enabled = true
    })
    return rule    
end


local function routing_rules()
	local result = {}
	for _, v in ipairs(routing()) do
		table.insert(result, v)
	end
	return {
	    domainMatcher =  proxy.domainMatcher,
		domainStrategy = proxy.routing_strategy or 'AsIs',
		rules = result
	}
end


local function outbounds()
    local result = {}
	if arg[7] == "none" then
		result = {
			server_outbound(socks5_server, "proxy_outbound"),
			dns_outbound(),
			direct_outbound(),
			block_outbound()
		}	
    elseif proto == "tcp" then
		result = {
			server_outbound(tcp_server, "proxy_outbound"),
			dns_outbound(),
			direct_outbound(),
			block_outbound()
		}	
    elseif proto == "udp" then
		result = {
			server_outbound(udp_server, "proxy_outbound"),
			dns_outbound(),
			direct_outbound(),
			block_outbound()
		}
    elseif proto == "tcp,udp" then
		result = {
			server_outbound(tcp_server, "proxy_outbound"),
			dns_outbound(),
			direct_outbound(),
			block_outbound()
		}		
    end 
    return result
end


local function logging()
    return {
        loglevel = proxy.log_level or "warning",
    }
end

local function policy()
    return {
        system = {
            statsOutboundUplink = true,
            statsOutboundDownlink = true
        }
    }
end

local xclient = {
    log = logging(),
    dns = dns(),
    routing = routing_rules(),
	dns = dns(),
	api = api(),
	policy = policy(),
	routing = routing_rules(),
    inbounds = inbounds(),
    outbounds = outbounds()    
}


local shadowsocks_plugin = {
    server = node.server,
    server_port = tonumber(node.server_port),
    local_address = "0.0.0.0",
    local_port = tonumber(local_port),
    mode = (proto == "tcp,udp") and "tcp_and_udp" or proto .. "_only",
    password = node.password,
    method = node.encrypt_method_v2ray_ss,
    reuse_port = true,
    protocol = _protocol,
    plugin = node.plugin,
    plugin_opts = node.plugin_opts or nil
}

if node.protocol == "shadowsocks-plugin" then
    print(json.stringify(shadowsocks_plugin, true))
else
    print(json.stringify(xclient, true))
end
