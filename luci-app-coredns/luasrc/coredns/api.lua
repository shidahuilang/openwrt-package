module("luci.coredns.api", package.seeall)
bin = require "nixio".bin
fs = require "nixio.fs"
sys = require "luci.sys"
uci = require"luci.model.uci".cursor()
util = require "luci.util"
datatypes = require "luci.cbi.datatypes"
jsonc = require "luci.jsonc"
i18n = require "luci.i18n"

appname = "coredns"
curl_args = {"-skfL", "--connect-timeout 3", "--retry 3", "-m 60"}
command_timeout = 300
LEDE_BOARD = nil
DISTRIB_TARGET = nil

-- LOG_FILE = "/tmp/coredns.log"
LOG_FILE = uci:get("coredns","global","logfile")
-- print(LOG_FILE)

function log(...)
	local result = os.date("%Y-%m-%d %H:%M:%S: ") .. table.concat({...}, " ")
	local f, err = io.open(LOG_FILE, "a")
	if f and err == nil then
		f:write(result .. "\n")
		f:close()
	end
end

function exec_call(cmd)
	local process = io.popen(cmd .. '; echo -e "\n$?"')
	local lines = {}
	local result = ""
	local return_code
	for line in process:lines() do
		lines[#lines + 1] = line
	end
	process:close()
	if #lines > 0 then
		return_code = lines[#lines]
		for i = 1, #lines - 1 do
			result = result .. lines[i] .. ((i == #lines - 1) and "" or "\n")
		end
	end
	return tonumber(return_code), trim(result)
end

function curl_base(url, file, args)
	if not args then args = {} end
	if file then
		args[#args + 1] = "-o " .. file
	end
	local cmd = string.format('curl %s "%s"', table_join(args), url)
	return exec_call(cmd)
end

function curl_logic(url, file, args)
	-- local return_code, result = curl_proxy(url, file, args)
	-- if not return_code or return_code ~= 0 then
		return_code, result = curl_base(url, file, args)
	-- end
	return return_code, result
end

function table_join(t, s)
	if not s then
		s = " "
	end
	local str = ""
	for index, value in ipairs(t) do
		str = str .. t[index] .. (index == #t and "" or s)
	end
	return str
end

function url(...)
	local url = string.format("admin/services/%s", appname)
	local args = { ... }
	for i, v in pairs(args) do
		if v ~= "" then
			url = url .. "/" .. v
		end
	end
	return require "luci.dispatcher".build_url(url)
end

function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function is_exist(table, value)
	for index, k in ipairs(table) do
		if k == value then
			return true
		end
	end
	return false
end

function repeat_exist(table, value)
	local count = 0
	for index, k in ipairs(table) do
		if k:find("-") and k == value then
			count = count + 1
		end
	end
	if count > 1 then
		return true
	end
	return false
end

function get_args(arg)
	local var = {}
	for i, arg_k in pairs(arg) do
		if i > 0 then
			local v = arg[i + 1]
			if v then
				if repeat_exist(arg, v) == false then
					var[arg_k] = v
				end
			end
		end
	end
	return var
end

function get_function_args(arg)
	local var = nil
	if arg and #arg > 1 then
		local param = {}
		for i = 2, #arg do
			param[#param + 1] = arg[i]
		end
		var = get_args(param)
	end
	return var
end

function strToTable(str)
	if str == nil or type(str) ~= "string" then
		return {}
	end

	return loadstring("return " .. str)()
end

function is_ip(val)
	if is_ipv6(val) then
		val = get_ipv6_only(val)
	end
	return datatypes.ipaddr(val)
end

function is_ipv6(val)
	local str = val
	local address = val:match('%[(.*)%]')
	if address then
		str = address
	end
	if datatypes.ip6addr(str) then
		return true
	end
	return false
end

function is_ipv6addrport(val)
	if is_ipv6(val) then
		local address, port = val:match('%[(.*)%]:([^:]+)$')
		if port then
			return datatypes.port(port)
		end
	end
	return false
end

function get_ipv6_only(val)
	local result = ""
	if is_ipv6(val) then
		result = val
		if val:match('%[(.*)%]') then
			result = val:match('%[(.*)%]')
		end
	end
	return result
end

function get_ipv6_full(val)
	local result = ""
	if is_ipv6(val) then
		result = val
		if not val:match('%[(.*)%]') then
			result = "[" .. result .. "]"
		end
	end
	return result
end

function get_ip_type(val)
	if is_ipv6(val) then
		return "6"
	elseif datatypes.ip4addr(val) then
		return "4"
	end
	return ""
end

function is_mac(val)
	return datatypes.macaddr(val)
end

function ip_or_mac(val)
	if val then
		if get_ip_type(val) == "4" then
			return "ip"
		end
		if is_mac(val) then
			return "mac"
		end
	end
	return ""
end

function iprange(val)
	if val then
		local ipStart, ipEnd = val:match("^([^/]+)-([^/]+)$")
		if (ipStart and datatypes.ip4addr(ipStart)) and (ipEnd and datatypes.ip4addr(ipEnd)) then
			return true
		end
	end
	return false
end

function get_domain_from_url(url)
	local domain = string.match(url, "//([^/]+)")
	if domain then
		return domain
	end
	return url
end

function gen_uuid(format)
	local uuid = sys.exec("echo -n $(cat /proc/sys/kernel/random/uuid)")
	if format == nil then
		uuid = string.gsub(uuid, "-", "")
	end
	return uuid
end

function gen_short_uuid()
	return sys.exec("echo -n $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)")
end

function uci_get_type(type, config, default)
	local value = uci:get_first(appname, type, config, default) or sys.exec("echo -n $(uci -q get " .. appname .. ".@" .. type .."[0]." .. config .. ")")
	if (value == nil or value == "") and (default and default ~= "") then
		value = default
	end
	return value
end

function uci_get_type_id(id, config, default)
	local value = uci:get(appname, id, config, default) or sys.exec("echo -n $(uci -q get " .. appname .. "." .. id .. "." .. config .. ")")
	if (value == nil or value == "") and (default and default ~= "") then
		value = default
	end
	return value
end

function chmod_755(file)
	if file and file ~= "" then
		if not fs.access(file, "rwx", "rx", "rx") then
			fs.chmod(file, 755)
		end
	end
end

function is_finded(e)
	return luci.sys.exec('type -t -p "/usr/share/coredns" "%s"' % {e}) ~= "" and true or false
end

function is_file(path)
	if path and #path > 1 then
		if sys.exec('[ -f "%s" ] && echo -n 1' % path) == "1" then
			return true
		end
	end
	return nil
end

function is_dir(path)
	if path and #path > 1 then
		if sys.exec('[ -d "%s" ] && echo -n 1' % path) == "1" then
			return true
		end
	end
	return nil
end

function get_final_dir(path)
	if is_dir(path) then
		return path
	else
		return get_final_dir(fs.dirname(path))
	end
end

function get_free_space(dir)
	if dir == nil then dir = "/" end
	if sys.call("df -k " .. dir .. " >/dev/null 2>&1") == 0 then
		return tonumber(sys.exec("echo -n $(df -k " .. dir .. " | awk 'NR>1' | awk '{print $4}')"))
	end
	return 0
end

function get_file_space(file)
	if file == nil then return 0 end
	if fs.access(file) then
		return tonumber(sys.exec("echo -n $(du -k " .. file .. " | awk '{print $1}')"))
	end
	return 0
end

function auto_get_arch()
	local arch = nixio.uname().machine or ""
	if fs.access("/usr/lib/os-release") then
		LEDE_BOARD = sys.exec("echo -n $(grep 'LEDE_BOARD' /usr/lib/os-release | awk -F '[\\042\\047]' '{print $2}')")
	end
	if fs.access("/etc/openwrt_release") then
		DISTRIB_TARGET = sys.exec("echo -n $(grep 'DISTRIB_TARGET' /etc/openwrt_release | awk -F '[\\042\\047]' '{print $2}')")
	end

	if arch == "mips" then
		if LEDE_BOARD and LEDE_BOARD ~= "" then
			if string.match(LEDE_BOARD, "ramips") == "ramips" then
				arch = "ramips"
			else
				arch = sys.exec("echo '" .. LEDE_BOARD .. "' | grep -oE 'ramips|ar71xx'")
			end
		elseif DISTRIB_TARGET and DISTRIB_TARGET ~= "" then
			if string.match(DISTRIB_TARGET, "ramips") == "ramips" then
				arch = "ramips"
			else
				arch = sys.exec("echo '" .. DISTRIB_TARGET .. "' | grep -oE 'ramips|ar71xx'")
			end
		end
	end

	return util.trim(arch)
end
