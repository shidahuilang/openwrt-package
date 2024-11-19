#!/usr/bin/lua

require "luci.model.uci"
require "nixio"
require "luci.util"
require "luci.sys"
require "luci.jsonc"
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort


local tinsert = table.insert
local ssub, slen, schar, sbyte, sformat, sgsub = string.sub, string.len, string.char, string.byte, string.format, string.gsub
local jsonParse, jsonStringify = luci.jsonc.parse, luci.jsonc.stringify
local b64decode = nixio.bin.b64decode
local cache = {}
local nodeResult = setmetatable({}, {__index = cache}) -- update result
local name = 'xclient'
local uciType = 'servers'
local ucic = luci.model.uci.cursor()
local proxy = '0'
local switch = '0'
local subscribe_url = ucic:get(name, 'config', 'subscribe_url')
local filter_words = '过期时间/剩余流量'
local save_words = ''
local v2_ss = "xray"
local v2_tj = "xray"
local log = function(...)
	print(os.date("%Y-%m-%d %H:%M:%S ") .. table.concat({...}, " "))
end
local encrypt_methods_ss = {
	"aes-128-gcm",
	"aes-192-gcm",
	"aes-256-gcm",
	"chacha20-ietf-poly1305",
	"xchacha20-ietf-poly1305"
}

local function split(full, sep)
	full = full:gsub("%z", "") 
	local off, result = 1, {}
	while true do
		local nStart, nEnd = full:find(sep, off)
		if not nEnd then
			local res = ssub(full, off, slen(full))
			if #res > 0 then 
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
-- urlencode
local function get_urlencode(c)
	return sformat("%%%02X", sbyte(c))
end

local function urlEncode(szText)
	local str = szText:gsub("([^0-9a-zA-Z ])", get_urlencode)
	str = str:gsub(" ", "+")
	return str
end

local function get_urldecode(h)
	return schar(tonumber(h, 16))
end
local function UrlDecode(szText)
	return szText:gsub("+", " "):gsub("%%(%x%x)", get_urldecode)
end

-- trim
local function trim(text)
	if not text or text == "" then
		return ""
	end
	return (sgsub(text, "^%s*(.-)%s*$", "%1"))
end
-- md5
local function md5(content)
	local stdout = luci.sys.exec('echo \"' .. urlEncode(content) .. '\" | md5sum | cut -d \" \" -f1')
	-- assert(nixio.errno() == 0)
	return trim(stdout)
end
-- base64
local function base64Decode(text)
	local raw = text
	if not text then
		return ''
	end
	text = text:gsub("%z", "")
	text = text:gsub("_", "/")
	text = text:gsub("-", "+")
	local mod4 = #text % 4
	text = text .. string.sub('====', mod4 + 1)
	local result = b64decode(text)
	if result then
		return result:gsub("%z", "")
	else
		return raw
	end
end

local function checkTabValue(tab)
	local revtab = {}
	for k,v in pairs(tab) do
		revtab[v] = true
	end
	return revtab
end

local function processData(szType, content)
	local result = {type = szType}
	if szType == 'vmess' then
		local info = jsonParse(content)
		result.type = 'xray'
		result.protocol = 'vmess'
		result.server = info.add
		result.server_port = info.port
		result.transport = info.net
		result.vmess_id = info.id
		result.alias = info.ps
		-- result.mux = 1
		-- result.concurrency = 8
		if info.net == 'ws' then
			result.ws_host = info.host
			result.ws_path = info.path
		end
		if info.net == 'h2' then
			result.h2_host = info.host
			result.h2_path = info.path
		end
		if info.net == 'quic' then
			result.quic_guise = "none"
			result.quic_key = ""
			result.quic_security = "none"
		end
		if info.net == 'grpc' then
			result.serviceName = info.serviceName
		end
		if info.net == 'tcp' then
			if info.type and info.type ~= "http" then
				info.type = "none"
			end
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
		
		if info.security then
			result.security = info.security
		end
		if info.tls == "tls" or info.tls == "1" then
			result.security = "tls"
			result.tls_host = info.sni
			result.insecure = 1
		else
			result.security = "none"
		end
	elseif szType == "ss" then
		local idx_sp = 0
		local alias = ""
		if content:find("#") then
			idx_sp = content:find("#")
			alias = content:sub(idx_sp + 1, -1)
		end
		local info = content:sub(1, idx_sp - 1)
		local hostInfo = split(base64Decode(info), "@")
		local host = split(hostInfo[2], ":")
		local userinfo = base64Decode(hostInfo[1])
		local method = userinfo:sub(1, userinfo:find(":") - 1)
		local password = userinfo:sub(userinfo:find(":") + 1, #userinfo)
		result.alias = UrlDecode(alias)
		result.type = v2_ss
		result.password = password
		result.server = host[1]
		result.transport = "tcp"
		result.protocol = "shadowsocks"
		if host[2]:find("/%?") then
			local query = split(host[2], "/%?")
			result.server_port = query[1]
			local params = {}
			for _, v in pairs(split(query[2], '&')) do
				local t = split(v, '=')
				params[t[1]] = t[2]
			end
			if params.plugin then
				local plugin_info = UrlDecode(params.plugin)
				local idx_pn = plugin_info:find(";")
				if idx_pn then
					result.plugin = plugin_info:sub(1, idx_pn - 1)
					result.plugin_opts = plugin_info:sub(idx_pn + 1, #plugin_info)
				else
					result.plugin = plugin_info
				end
				result.protocol = "shadowsocks-plugin"
			end
		else
			result.server_port = host[2]:gsub("/","")
		end
		result.encrypt_method_v2ray_ss = method
	elseif szType == "trojan" then
		local idx_sp = 0
		local alias = ""
		if content:find("#") then
			idx_sp = content:find("#")
			alias = content:sub(idx_sp + 1, -1)
		end
		local info = content:sub(1, idx_sp - 1)
		local hostInfo = split(info, "@")
		local host = split(hostInfo[2], ":")
		local userinfo = hostInfo[1]
		local password = userinfo
		result.alias = UrlDecode(alias)
		result.type = v2_tj
		result.protocol = "trojan"
		result.server = host[1]
		if host[2]:find("?") then
			local query = split(host[2], "?")
			result.server_port = query[1]
			local params = {}
			for _, v in pairs(split(query[2], '&')) do
				local t = split(v, '=')
				params[t[1]] = t[2]
			end
			
			if params.obfs == "grpc" and params.security == "none" then
				result.security = "none"
			else
				result.security = "tls"
			end
			
			if params.sni then
				result.tls_host = params.sni
			end
			if params.allowInsecure then
				result.insecure = params.allowInsecure
			end
			if params.obfs then
				if params.obfs == "grpc" then
					result.transport = params.obfs
					result.serviceName = params.serviceName
				end
				if params.obfs == "websocket" then
					result.transport = "ws"
					result.ws_host = params.obfsParam
					result.ws_path = params.path
				end
			else
                result.transport = "tcp"			
			end
		else
			result.server_port = host[2]
		end
		result.password = password
	elseif szType == "vless" then
		local idx_sp = 0
		local alias = ""
		if content:find("#") then
			idx_sp = content:find("#")
			alias = content:sub(idx_sp + 1, -1)
		end
		local info = content:sub(1, idx_sp - 1)
		local hostInfo = split(info, "@")
		local host = split(hostInfo[2], ":")
		local uuid = hostInfo[1]
		if host[2]:find("?") then
			local query = split(host[2], "?")
			local params = {}
			for _, v in pairs(split(UrlDecode(query[2]), '&')) do
				local t = split(v, '=')
				params[t[1]] = t[2]
			end
			result.alias = UrlDecode(alias)
			result.type = 'v2ray'
			result.protocol = 'vless'
			result.server = host[1]
			result.server_port = query[1]
			result.vmess_id = uuid
			result.vless_encryption = params.encryption or "none"
			result.transport = params.type and (params.type == 'http' and 'h2' or params.type) or "tcp"
			if not params.type or params.type == "tcp" then
				result.vless_flow = params.flow
			end
			if params.type == 'ws' then
				result.ws_host = params.host
				result.ws_path = params.path or "/"
			end
			if params.type == 'http' then
				result.h2_host = params.host
				result.h2_path = params.path or "/"
			end
			if params.type == 'kcp' then
				result.kcp_guise = params.headerType or "none"
				result.mtu = 1350
				result.tti = 50
				result.uplink_capacity = 5
				result.downlink_capacity = 20
				result.read_buffer_size = 2
				result.write_buffer_size = 2
				result.seed = params.seed or ""
			end
			if info.net == 'quic' then
				result.quic_guise = "none"
				result.quic_key = ""
				result.quic_security = "none"
			end
			if params.type == 'grpc' then
				result.serviceName = params.serviceName
			end
			if params.security == "tls" then
				result.security = "tls"
				result.tls_host = params.sni
			elseif params.security == "reality" then
				result.security = "reality"	
				result.tls_host = params.sni
				result.publicKey = params.publicKey
				result.shortId = params.shortId
				result.fingerprint = params.fingerprint
				result.spiderX = params.spiderX
			else
				result.security = "none"
			end
		else
			result.server_port = host[2]
		end
	end
	if not result.alias then
		if result.server and result.server_port then
			result.alias = result.server .. ':' .. result.server_port
		else
			result.alias = "NULL"
		end
	end
	
	local alias = result.alias
	result.alias = nil
	result.hashkey = md5(jsonStringify(result))
	result.alias = alias
	return result
end
-- wget
local function wget(url)
	local stdout = luci.sys.exec('uclient-fetch -q --user-agent="Luci-app-xclient/OpenWRT" --no-check-certificate -O- "' .. url .. '"')
	return trim(stdout)
end

local function check_filer(result)
	do
	
		local filter_word = split(filter_words, "/")

		local check_save = false
		if save_words ~= nil and save_words ~= "" and save_words ~= "NULL" then
			check_save = true
		end
		local save_word = split(save_words, "/")


		local filter_result = false
		local save_result = true


		for i, v in pairs(filter_word) do
			if tostring(result.alias):find(v) then
				filter_result = true
			end
		end


		if check_save == true then
			for i, v in pairs(save_word) do
				if tostring(result.alias):find(v) then
					save_result = false
				end
			end
		else
			save_result = false
		end

	
		if filter_result == true or save_result == true then
			return true
		else
			return false
		end
	end
end

local execute = function()
	-- exec
	do
		if proxy == '0' then 
			log('service is pausing..')
			luci.sys.init.stop(name)
		end
		if subscribe_url then
			local raw = wget(subscribe_url)
			if #raw > 0 then
				local nodes, szType
				local groupHash = md5(subscribe_url)
				cache[groupHash] = {}
				tinsert(nodeResult, {})
				local index = #nodeResult
				if jsonParse(raw) then
					nodes = jsonParse(raw).servers or jsonParse(raw)
					if nodes[1].server and nodes[1].method then
						szType = 'sip008'
					end
				else
					nodes = split(base64Decode(raw):gsub(" ", "_"), "\n")
				end
				for _, v in ipairs(nodes) do
					if v then
						local result
						if szType then
							result = processData(szType, v)
						elseif not szType then
							local node = trim(v)
							local dat = split(node, "://")
							if dat and dat[1] and dat[2] then
								local dat3 = ""
								if dat[3] then
									dat3 = "://" .. dat[3]
								end
								if dat[1] == 'ss' or dat[1] == 'trojan' then
									result = processData(dat[1], dat[2] .. dat3)
								else
									result = processData(dat[1], base64Decode(dat[2]))
								end
							end
						else
							log('skip unknown types: ' .. szType)
						end
						-- log(result)
						if result then
							if not result.server or not result.server_port or result.alias == "NULL" or check_filer(result) or result.server:match("[^0-9a-zA-Z%-%.%s]") or cache[groupHash][result.hashkey] then
								log('Discard invalid nodes: 【' .. result.type .. ' 】, ' .. result.alias)
							else
								result.grouphashkey = groupHash
								tinsert(nodeResult[index], result)
								cache[groupHash][result.hashkey] = nodeResult[index][#nodeResult[index]]
							end
						end
					end
				end
				log('Number of nodes successfully resolved: ' .. #nodes)
			else
				log(subscribe_url .. ': get content is empty')
			end
		end
	end
	-- diff
	do
		if next(nodeResult) == nil then
			log("Update failed, no node info available")
			return
		end
		local add, del = 0, 0
		ucic:foreach(name, uciType, function(old)
			if old.grouphashkey or old.hashkey then 
				if not nodeResult[old.grouphashkey] or not nodeResult[old.grouphashkey][old.hashkey] then
					ucic:delete(name, old['.name'])
					del = del + 1
				else
					local dat = nodeResult[old.grouphashkey][old.hashkey]
					ucic:tset(name, old['.name'], dat)
					setmetatable(nodeResult[old.grouphashkey][old.hashkey], {__index = {_ignore = true}})
				end
			else
				if not old.alias then
					if old.server or old.server_port then
						old.alias = old.server .. ':' .. old.server_port
						log('Ignore manually added nodes: ' .. old.alias)
					else
						ucic:delete(name, old['.name'])
					end
				else
					log('Ignore manually added nodes: ' .. old.alias)
				end
			end
		end)
		for k, v in ipairs(nodeResult) do
			for kk, vv in ipairs(v) do
				if not vv._ignore then
					local section = ucic:add(name, uciType)
					ucic:tset(name, section, vv)
					add = add + 1
				end
			end
		end
		ucic:commit(name)
		local globalServer = ucic:get_first(name, 'global', 'global_server', '')
		if globalServer ~= "nil" then
			local firstServer = ucic:get_first(name, uciType)
			if firstServer then
				if not ucic:get(name, globalServer) then
					luci.sys.call("/etc/init.d/" .. name .. " stop > /dev/null 2>&1 &")
					ucic:commit(name)
					ucic:set(name, ucic:get_first(name, 'global'), 'global_server', ucic:get_first(name, uciType))
					ucic:commit(name)
					log('The current active server has been deleted and is being automatically replaced with the first node。')
					luci.sys.call("/etc/init.d/" .. name .. " start > /dev/null 2>&1 &")
				else
					log('Maintain the current servers。')
					luci.sys.call("/etc/init.d/" .. name .. " boot > /dev/null 2>&1 &")
				end
			else
				log('There is no server node, stop the service')
				luci.sys.call("/etc/init.d/" .. name .. " stop > /dev/null 2>&1 &")
			end
		end
		log('New Nodes: ' .. add, 'Deleted Nodes: ' .. del)
		log('Subscription updated successfully')
	end
end

if subscribe_url and #subscribe_url > 0 then
	xpcall(execute, function(e)
		log(e)
		log(debug.traceback())
		log('An error occurred, restoring service')
		local firstServer = ucic:get_first(name, uciType)
		if firstServer then
			luci.sys.call("/etc/init.d/" .. name .. " boot > /dev/null 2>&1 &")
			log('Service Restart Successful')
		else
			luci.sys.call("/etc/init.d/" .. name .. " stop > /dev/null 2>&1 &") 
			log('Service Stop Successful')
		end
	end)
end
