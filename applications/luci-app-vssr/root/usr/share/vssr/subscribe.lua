#!/usr/bin/lua
------------------------------------------------
-- This file is part of the luci-app-ssr-plus subscribe.lua
-- @author William Chan <root@williamchan.me>
------------------------------------------------


require 'nixio'
require 'luci.util'
require 'luci.jsonc'
require 'luci.sys'

-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
local luci = luci
local tinsert = table.insert
local ssub, slen, schar, sbyte, sformat, sgsub =
    string.sub,
    string.len,
    string.char,
    string.byte,
    string.format,
    string.gsub
local jsonParse, jsonStringify = luci.jsonc.parse, luci.jsonc.stringify
local b64decode = nixio.bin.b64decode
local cache = {}
local nodeResult = setmetatable({}, {__index = cache}) -- update result
local name = 'vssr'
local uciType = 'servers'
local ucic = luci.model.uci.cursor()
local proxy = ucic:get_first(name, 'server_subscribe', 'proxy', '0')
local switch = '0'
local subscribe_url = ucic:get_first(name, 'server_subscribe', 'subscribe_url', {})
local filter_words = ucic:get_first(name, 'server_subscribe', 'filter_words', '过期时间/剩余流量')

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

local log = function(...)
    print(os.date('%Y-%m-%d %H:%M:%S ') .. table.concat({...}, ' '))
end
-- 分割字符串
local function split(full, sep)
    full = full:gsub('%z', '') -- 这里不是很清楚 有时候结尾带个\0
    local off, result = 1, {}
    while true do
        local nStart, nEnd = full:find(sep, off)
        if not nEnd then
            local res = ssub(full, off, slen(full))
            if #res > 0 then -- 过滤掉 \0
                tinsert(result, res)
            end
            break
        else
            tinsert(result, ssub(full, off, nStart - 1))
            off = nEnd + 1
        end
    end
    return result
end

--table去重

local function clone( object )
    local lookup_table = {}
    local function copyObj( object )
        if type( object ) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
       
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs( object ) do
            new_table[copyObj( key )] = copyObj( value )
        end
        return setmetatable( new_table, getmetatable( object ) )
    end
    return copyObj( object )
end

local function table_unique(list)
    local temp1 = clone(list)
    local temp2 = clone(list)
    for k1, v1 in ipairs(temp1) do
        for k2, v2 in ipairs(temp2) do
            if v1.alias ~= v2.alias and v1.hashkey == v2.hashkey then
                table.remove(temp1, k1)
                table.remove(temp2, k1)
                
            end
        end
    end
    return temp1
end

-- urlencode
local function get_urlencode(c)
    return sformat('%%%02X', sbyte(c))
end

local function urlEncode(szText)
    local str = szText:gsub('([^0-9a-zA-Z ])', get_urlencode)
    str = str:gsub(' ', '+')
    return str
end

local function get_urldecode(h)
    return schar(tonumber(h, 16))
end
local function UrlDecode(szText)
    return szText:gsub('+', ' '):gsub('%%(%x%x)', get_urldecode)
end

-- trim
local function trim(text)
    if not text or text == '' then
        return ''
    end
    return (sgsub(text, '^%s*(.-)%s*$', '%1'))
end
-- md5
local function md5(content)
    local stdout = luci.sys.exec('echo "' .. urlEncode(content) .. '" | md5sum | cut -d " "  -f1')
    -- assert(nixio.errno() == 0)
    return trim(stdout)
end
-- base64
local function base64Decode(text)
    local raw = text
    if not text then
        return ''
    end
    text = text:gsub('%z', '')
    text = text:gsub('_', '/')
    text = text:gsub('-', '+')
    local mod4 = #text % 4
    text = text .. string.sub('====', mod4 + 1)
    local result = b64decode(text)
    if result then
        return result:gsub('%z', '')
    else
        return raw
    end
end
-- 处理数据
local function processData(szType, content, groupName)
    local result = {
        -- 		auth_enable = '0',
        -- 		switch_enable = '1',
        type = szType,
        local_port = 1234,
        -- 		timeout = 60, -- 不太确定 好像是死的
        -- 		fast_open = 0,
        -- 		kcp_enable = 0,
        -- 		kcp_port = 0,
        kcp_param = '--nocomp'
    }
    if szType == 'ssr' then
        local dat = split(content, '/%?')
        local hostInfo = split(dat[1], ':')
        result.server = hostInfo[1]
        result.server_port = hostInfo[2]
        result.protocol = hostInfo[3]
        result.encrypt_method = hostInfo[4]
        result.obfs = hostInfo[5]
        result.password = base64Decode(hostInfo[6])
        local params = {}
        for _, v in pairs(split(dat[2], '&')) do
            local t = split(v, '=')
            params[t[1]] = t[2]
        end
        result.obfs_param = base64Decode(params.obfsparam)
        result.protocol_param = base64Decode(params.protoparam)
        local group = base64Decode(params.group)
        if group then
            result.alias = '[' .. group .. '] '
        end
        result.alias = result.alias .. base64Decode(params.remarks)
    elseif szType == 'vmess' then
        local info = jsonParse(content)
        result.type = 'v2ray'
        result.server = info.add
        result.server_port = info.port
        result.transport = info.net
        result.alter_id = info.aid
        result.vmess_id = info.id
        result.alias = groupName .. info.ps
        -- 		result.mux = 1
        -- 		result.concurrency = 8
        if info.net == 'ws' then
            result.ws_host = info.host
            result.ws_path = info.path
        end
        if info.net == 'h2' then
            result.h2_host = info.host
            result.h2_path = info.path
        end
        if info.net == 'tcp' then
            result.tcp_guise = info.type
            result.http_host = info.host
            result.http_path = info.path
        end
        if info.net == 'kcp' then
            result.kcp_guise = info.type
            result.mtu = 1350
            result.tti = 50
            result.uplink_capacity = 5
            result.downlink_capacity = 20
            result.read_buffer_size = 2
            result.write_buffer_size = 2
        end
        if info.net == 'quic' then
            result.quic_guise = info.type
            result.quic_key = info.key
            result.quic_security = info.securty
        end
        if info.security then
            result.security = info.security
        end
        if info.tls == 'tls' or info.tls == '1' then
            result.tls = '1'
            result.tls_host = info.host
        else
            result.tls = '0'
        end
    elseif szType == 'ss' then
        local idx_sp = 0
        local alias = ''
        if content:find('#') then
            idx_sp = content:find('#')
            alias = content:sub(idx_sp + 1, -1)
        end
        local info = content:sub(1, idx_sp - 1)
        local hostInfo = split(base64Decode(info), '@')
        local host = split(hostInfo[2], ':')
        local userinfo = base64Decode(hostInfo[1])
        local method = userinfo:sub(1, userinfo:find(':') - 1)
        local password = userinfo:sub(userinfo:find(':') + 1, #userinfo)
        result.alias = groupName .. UrlDecode(alias)
        result.type = 'ss'
        result.server = host[1]
        if host[2]:find('/%?') then
            local query = split(host[2], '/%?')
            result.server_port = query[1]
            local params = {}
            for _, v in pairs(split(query[2], '&')) do
                local t = split(v, '=')
                params[t[1]] = t[2]
            end
            if params.plugin then
                local plugin_info = UrlDecode(params.plugin)
                local idx_pn = plugin_info:find(';')
                if idx_pn then
                    result.plugin = plugin_info:sub(1, idx_pn - 1)
                    result.plugin_opts = plugin_info:sub(idx_pn + 1, #plugin_info)
                else
                    result.plugin = plugin_info
                end
            end
        else
            result.server_port = host[2]
        end
        result.encrypt_method_ss = method
        result.password = password
    elseif szType == 'trojan' then
        local idx_sp = 0
        local alias = ''
        if content:find('#') then
            idx_sp = content:find('#')
            alias = content:sub(idx_sp + 1, -1)
        end
        local info = content:sub(1, idx_sp - 1)
        local hostInfo = split(info, '@')
        local host = split(hostInfo[2], ':')
        local password = hostInfo[1]
        result.alias = groupName .. UrlDecode(alias)
        result.type = 'trojan'
        result.server = host[1]
        result.insecure = '0'
        if host[2]:find('?') then
            local query = split(host[2], '?')
            result.server_port = query[1]
            local params = {}
            for _, v in pairs(split(query[2], '&')) do
                local t = split(v, '=')
                if t[1] == 'peer' then
                    result.peer = t[2]
                    result.tls = '1'
                end
            end
        else
            result.server_port = host[2]
        end
        result.password = password
    elseif szType == 'ssd' then
        result.type = 'ss'
        result.server = content.server
        result.server_port = content.port
        result.password = content.password
        result.encrypt_method_ss = content.encryption
        result.plugin = content.plugin
        result.plugin_opts = content.plugin_options
        result.alias = '[' .. content.airport .. '] ' .. content.remarks
    end
    if not result.alias then
        if result.server and result.server_port then
            result.alias = result.server .. ':' .. result.server_port
        else
            result.alias = "NULL"
        end
    end
    -- alias 不参与 hashkey 计算
    local alias = result.alias
    result.alias = nil
    local switch_enable = result.switch_enable
    result.switch_enable = nil
    result.hashkey = md5(jsonStringify(result))
    result.alias = alias
    result.switch_enable = switch_enable
    local vssrutil = require 'vssrutil'
    result.flag = vssrutil.get_flag(result.alias, result.server)

    return result
end
-- wget
local function wget(url)
    local stdout =
        luci.sys.exec(
        'wget-ssl -q --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36" --no-check-certificate -t 3 -T 10 -O- "' ..
            url .. '"'
    )
    return trim(stdout)
end

local function check_filer(result)
	do
		local filter_word = split(filter_words, "/")
		for i, v in pairs(filter_word) do
			if result.alias:find(v) then
				log('订阅节点关键字过滤:“' .. v ..'” ，该节点被丢弃')
				return true
			end
		end
	end
end

local execute = function()
    -- exec
    do
        if proxy == '0' then -- 不使用代理更新的话先暂停
            log('服务正在暂停')
            luci.sys.init.stop(name)
        end
        for k, url in ipairs(subscribe_url) do
            local groupName = ""
            urlTable = split(url, ",")
            groupName = table.getn(urlTable) > 1 and '[' .. urlTable[1] .. '] ' or ""
            url = table.getn(urlTable) > 1 and urlTable[2] or url
            local raw = wget(url)
            if #raw > 0 then
                local nodes, szType
                local groupHash = md5(url)
                cache[groupHash] = {}
                tinsert(nodeResult, {})
                local index = #nodeResult
                -- SSD 似乎是这种格式 ssd:// 开头的
                if raw:find('ssd://') then
                    szType = 'ssd'
                    local nEnd = select(2, raw:find('ssd://'))
                    nodes = base64Decode(raw:sub(nEnd + 1, #raw))
                    nodes = jsonParse(nodes)
                    local extra = {
                        airport = nodes.airport,
                        port = nodes.port,
                        encryption = nodes.encryption,
                        password = nodes.password
                    }
                    local servers = {}
                    -- SS里面包着 干脆直接这样
                    for _, server in ipairs(nodes.servers) do
                        tinsert(servers, setmetatable(server, {__index = extra}))
                    end
                    nodes = servers
                else
                    -- ssd 外的格式
                    nodes = split(base64Decode(raw):gsub(' ', '\n'), '\n')
                end
                for _, v in ipairs(nodes) do
                    if v then
                        local result
                        if szType == 'ssd' then
                            result = processData(szType, v, groupName)
                        elseif not szType then
                            local node = trim(v)
                            local dat = split(node, '://')
                            if dat and dat[1] and dat[2] then
                                if dat[1] == 'ss' then
                                    result = processData(dat[1], dat[2], groupName)
                                else
                                    result = processData(dat[1], base64Decode(dat[2]), groupName)
                                end
                            end
                        else
                            log('跳过未知类型: ' .. szType)
                        end
                        -- log(result)
                        if result then
                            if
                                not result.server or
                                not result.server_port or
                                result.alias == "NULL" or
                                check_filer(result) or
                                result.server:match("[^0-9a-zA-Z%-%.%s]") -- 中文做地址的 也没有人拿中文域名搞，就算中文域也有Puny Code SB 机场
                             then
                                log('丢弃无效节点: ' .. result.type .. ' 节点, ' .. result.alias)
                            else
                                log('成功解析: ' .. result.type .. ' 节点, ' .. result.alias)
                                result.grouphashkey = groupHash
                                tinsert(nodeResult[index], result)
                                cache[groupHash][result.hashkey] = nodeResult[index][#nodeResult[index]]
                            end
                        end
                    end
                end
                log('成功解析节点数量: ' .. #nodes)
            else
				log(url .. ': 获取内容为空')
			end
        end
    end
    -- diff
    do
        if next(nodeResult) == nil then
			log("更新失败，没有可用的节点信息")
			if proxy == '0' then
				luci.sys.init.start(name)
				log('订阅失败, 恢复服务')
			end
			return
		end
        local add, del = 0, 0
        ucic:foreach(
            name,
            uciType,
            function(old)
                if old.grouphashkey or old.hashkey then -- 没有 hash 的不参与删除
                    if not nodeResult[old.grouphashkey] or not nodeResult[old.grouphashkey][old.hashkey] then
                        ucic:delete(name, old['.name'])
                        del = del + 1
                    else
                        local dat = nodeResult[old.grouphashkey][old.hashkey]
                        ucic:tset(name, old['.name'], dat)
                        -- 标记一下
                        setmetatable(nodeResult[old.grouphashkey][old.hashkey], {__index = {_ignore = true}})
                    end
                else
                    if not old.alias then
                        if not old.server or old.server_port then
                            ucic:delete(name, old['.name'])
                        else
                            old.alias = old.server .. ':' .. old.server_port
                            log('忽略手动添加的节点: ' .. old.alias)
                        end
                    else
                        log('忽略手动添加的节点: ' .. old.alias)
                    end
                end
            end
        )
        
        for k, v in ipairs(nodeResult) do
            -- 如果订阅节点中有相同的节点信息 需要先去重。
            new_nodes = table_unique(v)
            for kk, vv in ipairs(new_nodes) do
                if not vv._ignore then
                    local section = ucic:add(name, uciType)
                    ucic:tset(name, section, vv)
                    ucic:set(name, section, 'switch_enable', switch)
                    add = add + 1
                end
            end
        end
        ucic:commit(name)
        -- 如果服务器已经不见了把帮换一个
        local globalServer = ucic:get_first(name, 'global', 'global_server', '')
        local firstServer = ucic:get_first(name, uciType)
        if not ucic:get(name, globalServer) then
            if firstServer then
                ucic:set(name, ucic:get_first(name, 'global'), 'global_server', firstServer)
                ucic:commit(name)
                log('当前主服务器已更新，正在自动更换。')
            end
        end
        if firstServer then
            luci.sys.call('/etc/init.d/' .. name .. ' restart > /dev/null 2>&1 &') -- 不加&的话日志会出现的更早
        else
            luci.sys.call('/etc/init.d/' .. name .. ' stop > /dev/null 2>&1 &') -- 不加&的话日志会出现的更早
        end
        log('新增节点数量: ' .. add, '删除节点数量: ' .. del)
        log('更新成功服务正在启动')
        log('END SUBSCRIBE')
    end
end

if subscribe_url and #subscribe_url > 0 then
    xpcall(
        execute,
        function(e)
            log(e)
            -- log(debug.traceback())
            log('发生错误, 正在恢复服务')
            log('END SUBSCRIBE')
            local firstServer = ucic:get_first(name, uciType)
            if firstServer then
                luci.sys.call('/etc/init.d/' .. name .. ' restart > /dev/null 2>&1 &') -- 不加&的话日志会出现的更早
            else
                luci.sys.call('/etc/init.d/' .. name .. ' stop > /dev/null 2>&1 &') -- 不加&的话日志会出现的更早
            end
        end
    )
end
