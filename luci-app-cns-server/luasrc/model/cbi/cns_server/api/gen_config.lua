module("luci.model.cbi.cns_server.api.gen_config", package.seeall)

-- 传入uci配置文件，转化为配置文件
function gen_config(user)
    local config = {
        Tcp_timeout = tonumber(user.Tcp_timeout),
        Udp_timeout = tonumber(user.Udp_timeout),
        listen_addr = (function ()
            local list = {}
            for key, value in ipairs(user.port) do
                list[key] = ":"..value
            end
            return list
        end)(),
        proxy_key = user.proxy_key,
        encrypt_password = user.encrypt_password,
        Enable_dns_tcpOverUdp = (function ()
            if user.Enable_dns_tcpOverUdp == 1 then return true else return false end
        end)(),
        Enable_httpDNS = (function ()
            if user.Enable_httpDNS == 1 then return true else return false end
        end)(),
        Enable_TFO = (function ()
            if user.Enable_TFO == 1 then return true else return false end
        end)(),
        Tls = (function ()
            if user.tls == "1" then
                return {
                    listen_addr = function ()
                        local list = {}
                        for key, value in ipairs(user.port) do
                            list[key] = ":"..value
                        end
                        return list
                    end,
                    AutoCertHosts = function ()
                        local list = {}
                        for key, value in ipairs(user.tls_auto_cert_host) do
                            list[key] = ":"..value
                        end
                        return list
                    end,
                    cert_file = user.tls_cert_file,
                    key_file = user.tls_key_file,
                }
            end 
        end)()
    }
    return config
end