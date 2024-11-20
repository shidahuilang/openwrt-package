module("luci.controller.xclient", package.seeall)
require "nixio.fs"
require "luci.http"
require "luci.sys"
require "luci.model.uci"
local json = require "luci.jsonc" 


function index()
	if not nixio.fs.access("/etc/config/xclient") then
		return
	end
	local page = entry({"admin", "services", "xclient"},alias("admin", "services", "xclient", "overview"), "XClient", 1)
	page.dependent = true
	page.acl_depends = {"luci-app-xclient"}

    entry({"admin", "services", "xclient", "overview"},cbi("xclient/status"), "Overview", 5).leaf = true
	entry({"admin", "services", "xclient", "servers" },cbi("xclient/servers"), "Servers", 10).leaf = true
	entry({"admin", "services", "xclient", "server"},cbi("xclient/server"), nil).leaf = true	
	entry({"admin", "services", "xclient", "dns"},cbi("xclient/dns"),"DNS", 20).leaf = true
    entry({"admin", "services", "xclient", "add-dns"},cbi("xclient/add-dns"), nil).leaf = true
	entry({"admin", "services", "xclient", "routing"},cbi("xclient/rules"),"Routing", 30).leaf = true
	entry({"admin", "services", "xclient", "rule"},cbi("xclient/rule"), nil).leaf = true
	entry({"admin", "services", "xclient", "update"},cbi("xclient/update"),"Update", 40).leaf = true
	entry({"admin", "services", "xclient", "log"},form("xclient/log"),"Log", 50).leaf = true

	entry({"admin", "services", "xclient", "ping"}, call("act_ping")).leaf=true
	entry({"admin", "services", "xclient", "run"},call("action_run")).leaf=true
	entry({"admin", "services", "xclient", "subscribe"}, call("subscribe"))
	entry({"admin", "services", "xclient", "update_geosite"}, call("update_geosite")).leaf = true
	entry({"admin", "services", "xclient", "update_geoip"}, call("update_geoip")).leaf = true
	entry({"admin", "services", "xclient", "logstatus"},call("logstatus_check")).leaf=true
	entry({"admin", "services", "xclient", "readlog"},call("action_read")).leaf=true
	entry({'admin', 'services', "xclient", 'web'}, call('web_check')).leaf=true
	entry({"admin", "services", "xclient", "delete"}, call("act_delete"))
	
	entry({"admin", "services", "xclient", "info"}, call("act_info"))
	entry({"admin", "services", "xclient", "logout"}, call("act_logout"))
	entry({"admin", "services", "xclient", "login"}, call("act_login"))
    entry({"admin", "services", "xclient", "login_check"}, call("act_login_check"))
	entry({"admin", "services", "xclient", "login_info"}, call("act_login_info"))
	
	--entry({"admin", "services", "xclient", "xray_check"}, call("xray_check")).leaf = true
	--entry({"admin", "services", "xclient", "xray_update"}, call("xrayx_update")).leaf = true
	entry({"admin", "services", "xclient", "geolocation"}, call("geoloc")).leaf = true
	
	entry({"admin", "services", "xclient", "geoip"}, call("geoip_check")).leaf=true
	entry({"admin", "services", "xclient", "geoipupdate"}, call("geoip_update")).leaf=true
	entry({"admin", "services", "xclient", "check_geoip"}, call("check_geoip_log")).leaf=true
	
	entry({"admin", "services", "xclient", "geosite"}, call("geosite_check")).leaf=true
	entry({"admin", "services", "xclient", "geositeupdate"}, call("geosite_update")).leaf=true
	entry({"admin", "services", "xclient", "check_geosite"}, call("check_geosite_log")).leaf=true
	
	entry({"admin", "services", "xclient", "version"}, call("check_version")).leaf=true
	entry({"admin", "services", "xclient", "check_latest"}, call("check_latest")).leaf=true
	
	entry({"admin", "services", "xclient", "traffic"}, call("statistics")).leaf=true
end

local uci = luci.model.uci.cursor()
local Process_list = luci.sys.exec("busybox ps -w")

local function dns_status()
	if Process_list:find("xclient/bin/pdnsd") or (Process_list:find("xclient.dns") and Process_list:find("dns2socks.127.0.0.1.*127.0.0.1.5335")) then
		return 1
	else
		return 0
	end
end	

local function tcp_status()
	if Process_list:find("local.udp.xclient.retcp") or Process_list:find("tcp.udp.xclient.retcp") or Process_list:find("local.xclient.retcp") or Process_list:find("tcp.only.xclient.retcp") then
		return 1
	else
		return 0
	end
end	

local function udp_status()
	if Process_list:find("local.udp.xclient.retcp") or Process_list:find("tcp.udp.xclient.retcp") or Process_list:find("local.xclient.retcp") or Process_list:find("udp.only.xclient.reudp") then
		return 1
	else
		return 0
	end
end	

local function socks_status()
	if Process_list:find("local.udp.xclient.retcp")  or Process_list:find("tcp.udp.xclient.local") or Process_list:find("local.xclient.retcp") then
		return 1
	else
		return 0
	end
end	


local function running_status()
	return luci.sys.call("busybox ps -w | grep xclient-retcp | grep -v grep >/dev/null") == 0
end

local function http_write_json(content)
	luci.http.prepare_content("application/json")
	luci.http.write_json(content or {code = 1})
end

function subscribe()
    luci.http.prepare_content("application/json")
	local token, details, data, suburl
	token = uci:get("xclient", "config", "token")	
    local site = uci:get("xclient", "config", "site")	
	details = luci.sys.exec(string.format("curl -sL -H 'Content-Type: application/json' -d '{\"token\":\"%s\"}' -X POST %s/api/v1/details", token, site))
	if details then
		data = json.parse(details)
		if data and data.ret == 1 then
			suburl = data.url.xclient 
			if suburl then
			   uci:set("xclient", "config", "subscribe_url", suburl)
			   uci:commit("xclient")
			   luci.sys.call("/usr/bin/lua /usr/share/xclient/subscribe.lua >>/var/log/xclient.log")
			   luci.http.write_json({ret = 1})
			end
		else 
			luci.http.write_json({ret = 0})
		end
    else
		luci.http.write_json({ret = 0})
	end
end 



function act_login_check() 
    luci.http.prepare_content("application/json")
	local token = uci:get("xclient", "config", "token")
    if token then
	   luci.http.write_json({login = 1})
    else
	   luci.http.write_json({login = 0})
    end
end 

function act_login() 
    luci.http.prepare_content("application/json")
	local info, token
	local email = uci:get("xclient", "config", "email")
	local passwd = uci:get("xclient", "config", "passwd")
	local site = uci:get("xclient", "config", "site")
	if email and passwd then
	    info = luci.sys.exec(string.format("curl -sL -H 'Content-Type: application/json' -d '{\"email\":\"%s\", \"passwd\":\"%s\"}' -X POST  %s/api/v1/login", email, passwd, site))
	    if info then
		    info = json.parse(info)
        else
	        luci.http.write_json({login = 0})
	    end	
        if info and info.ret == 1 then 
	        token = info.token
	        uci:set("xclient", "config", "token", token)
			uci:set("xclient", "config", "auto_update_servers", "6")
	        uci:commit("xclient") 
	        luci.http.write_json({login = 1})
        else
	        luci.http.write_json({login = 0})
	    end
	else
	    luci.http.write_json({login = 0})
	end	
end

function login_info()
	uci:set("xclient", "config", "email", luci.http.formvalue("email"))
	uci:set("xclient", "config", "passwd", luci.http.formvalue("passwd"))
	uci:set("xclient", "config", "site", luci.http.formvalue("weburl"))
	uci:commit("xclient")
	return 1
end


function act_logout() 
    luci.http.prepare_content("application/json")
    local token, details, data
	token = uci:get("xclient", "config", "token")
    local site = uci:get("xclient", "config", "site")	
	details = luci.sys.exec(string.format("curl -sL -H 'Content-Type: application/json' -d '{\"token\":\"%s\"}' -X POST %s/api/v1/logout", token, site))
	if details then
	    data = json.parse(details)
		if data.ret == 1 then
			uci:delete("xclient", "config", "token")
			uci:delete("xclient", "config", "subscribe_url")
			uci:delete("xclient", "config", "auto_update_servers")
			uci:delete_all("xclient", "servers", function(s)
				if s.hashkey or s.isSubscribe then
					return true
				else
					return false
				end
			end)
			uci:commit("xclient") 
			luci.sys.call("/etc/init.d/xclient boot &")
			luci.http.write_json({logout = 1;})
		else
			luci.http.write_json({logout = 0;})
		end	
    else
		luci.http.write_json({logout = 0})
	end
end


function act_login_info()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		login_info = login_info();
	})
end


function action_run()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		dns_status = dns_status(),
		tcp_status = tcp_status(),
		udp_status = udp_status(),
		socks_status = socks_status(),
	})
end


function act_ping()
	local e = {}
	local domain = luci.http.formvalue("domain")
	local port = luci.http.formvalue("port")
	local transport = luci.http.formvalue("transport")
	local wsPath = luci.http.formvalue("wsPath")
	local tls = luci.http.formvalue("tls")
	e.index = luci.http.formvalue("index")
	local iret = luci.sys.call("ipset add xclient_spec_wan_ac " .. domain .. " 2>/dev/null")
	if transport == "ws" then
		local prefix = tls=='1' and "https://" or "http://"
		local address = prefix..domain..':'..port..wsPath
		local result = luci.sys.exec("curl --http1.1 -m 2 -ksN -o /dev/null -w 'time_connect=%{time_connect}\nhttp_code=%{http_code}' -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==' -H 'Sec-WebSocket-Version: 13' "..address)
		e.socket = string.match(result,"http_code=(%d+)")=="101"
		e.ping = tonumber(string.match(result, "time_connect=(%d+.%d%d%d)"))*1000
	else
		local socket = nixio.socket("inet", "stream")
		socket:setopt("socket", "rcvtimeo", 3)
		socket:setopt("socket", "sndtimeo", 3)
		e.socket = socket:connect(domain, port)
		socket:close()
		-- 	e.ping = luci.sys.exec("ping -c 1 -W 1 %q 2>&1 | grep -o 'time=[0-9]*.[0-9]' | awk -F '=' '{print$2}'" % domain)
		-- 	if (e.ping == "") then
		e.ping = luci.sys.exec(string.format("echo -n $(tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null", port, domain))
	end
	if (iret == 0) then
		luci.sys.call(" ipset del xclient_spec_wan_ac " .. domain)
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end


function logstatus_check()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local fdp=tonumber(nixio.fs.readfile("/usr/share/xclient/logstatus_check")) or 0
	local f=io.open("/usr/share/xclient/xclient.txt", "r+")
	f:seek("set",fdp)
	local a=f:read(2048000) or ""
	fdp=f:seek()
	nixio.fs.writefile("/usr/share/xclient/logstatus_check",tostring(fdp))
	f:close()
	if nixio.fs.access("/usr/share/xclient/logstatus_check") then
		luci.http.write(a)
	else
		luci.http.write(a.."\0")
	end
end


local function readlog()
	return luci.sys.exec("sed -n '$p' /usr/share/xclient/readlog.txt 2>/dev/null")
end


function action_read()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		readlog = readlog();
	})
end


function check(host, port)
	local socket = nixio.socket("inet", "stream")
	socket:setopt("socket", "rcvtimeo", 3)
	socket:setopt("socket", "sndtimeo", 3)
	local ret = socket:connect(host, port)
	socket:close()
    return ret
end


function web_check()
    local e = {}
    local port = 80
    e.baidu = check('www.baidu.com', port)
    e.taobao = check('www.taobao.com', port)
    e.google = check('www.google.com', port)
    e.youtube = check('www.youtube.com', port)
    luci.http.prepare_content('application/json')
    luci.http.write_json(e)
end


function update_geoip()
	luci.sys.call("lua /usr/share/xclient/geoip.lua log > /dev/null 2>&1 &")
	http_write_json()
end

function update_geosite()
	luci.sys.call("lua /usr/share/xclient/geosite.lua log > /dev/null 2>&1 &")
	http_write_json()
end

function act_delete()
	luci.sys.call("/etc/init.d/xclient reload &")
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "xclient", "servers"))
end


function geoloc()
    local geo, data
	geo = luci.sys.exec(string.format("curl -sL -H 'User-Agent: luci-app-xclient' 'Content-Type: application/json'  -X GET https://query-geolocation.herokuapp.com/?lang=en"))
	if geo then
		data = json.parse(geo)
	end	
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		code = data.code,
		location = data.location
	})
end	

local function geoipcheck()
	if nixio.fs.access("/var/run/geo_ip_update_error") then
		return "0"
	elseif nixio.fs.access("/var/run/geo_ip_update") then
		return "1"
	elseif nixio.fs.access("/var/run/geo_ip_down_complete") then
		return "2"
	end
end

local function geositecheck()
	if nixio.fs.access("/var/run/geo_site_update_error") then
		return "0"
	elseif nixio.fs.access("/var/run/geo_site_update") then
		return "1"
	elseif nixio.fs.access("/var/run/geo_site_down_complete") then
		return "2"
	end
end


function geoip_check()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	 geoipcheck = geoipcheck();
	})
end

function geosite_check()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	 geositecheck = geositecheck();
	})
end


function geoip_update()
	nixio.fs.writefile("/var/run/geoiplog","0")
	luci.sys.exec("(rm /var/run/geo_ip_update_error ;  touch /var/run/geo_ip_update ; sh /usr/share/xclient/geoip.sh >/tmp/geo_ip_update.txt 2>&1  || touch /var/run/geo_ip_update_error ;rm /var/run/geo_ip_update) &")
end

function geosite_update()
	nixio.fs.writefile("/var/run/geositelog","0")
	luci.sys.exec("(rm /var/run/geo_site_update_error ;  touch /var/run/geo_site_update ; sh /usr/share/xclient/geosite.sh >/tmp/geo_site_update.txt 2>&1  || touch /var/run/geo_site_update_error ;rm /var/run/geo_site_update) &")
end


function check_geoip_log()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local fdp=tonumber(nixio.fs.readfile("/var/run/geoiplog")) or 0
	local f=io.open("/tmp/geo_ip_update.txt", "r+")
	f:seek("set",fdp)
	local a=f:read(2048000) or ""
	fdp=f:seek()
	nixio.fs.writefile("/var/run/geoiplog",tostring(fdp))
	f:close()
if nixio.fs.access("/var/run/geo_ip_update") then
	luci.http.write(a)
else
	luci.http.write(a.."\0")
end
end


function check_geosite_log()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local fdp=tonumber(nixio.fs.readfile("/var/run/geositelog")) or 0
	local f=io.open("/tmp/geo_site_update.txt", "r+")
	f:seek("set",fdp)
	local a=f:read(2048000) or ""
	fdp=f:seek()
	nixio.fs.writefile("/var/run/geositelog",tostring(fdp))
	f:close()
if nixio.fs.access("/var/run/geo_site_update") then
	luci.http.write(a)
else
	luci.http.write(a.."\0")
end
end


local function core_version()
	if nixio.fs.access("/usr/bin/xray") then
		if nixio.fs.access("/usr/share/xclient/core_version") then
			return luci.sys.exec("sed -n 1p /usr/share/xclient/core_version")
		else
			return luci.sys.exec("/usr/bin/xray -version | awk '{print $2}' | sed -n 1P")
		end
	else
		return "--"
	end
end

local function latest_core()
	if nixio.fs.access("/usr/share/xclient/new_core") then
		return luci.sys.exec("sed -n 1p /usr/share/xclient/new_core")
	else
		return "--"
	end

end

local function geosite_version()
	if nixio.fs.access("/usr/bin/geosite.dat") then
		if nixio.fs.access("/usr/share/xclient/geosite_version") then
			return luci.sys.exec("sed -n 1p /usr/share/xclient/geosite_version")
		else
			return "--"
		end
	else
		return "--"
	end
end

local function geoip_version()
	if nixio.fs.access("/usr/bin/geoip.dat") then
		if nixio.fs.access("/usr/share/xclient/geoip_version") then
			return luci.sys.exec("sed -n 1p /usr/share/xclient/geoip_version")
		else
			return "--"	
		end
	else
		return "--"
	end
end

function check_latest()
	return luci.sys.exec("sh /usr/share/xclient/core_version.sh")
end


function check_version()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	 core_version = core_version(),
	 geoip_version = geoip_version(),
	 geosite_version = geosite_version(),
	 latest_core = latest_core()
	})
end

function statistics()
	luci.http.prepare_content("application/json")
	
    local up, check_uplink
	check_uplink = luci.sys.exec(string.format("xray api stats --server=127.0.0.1:8888 -name \"outbound>>>proxy_outbound>>>traffic>>>uplink\"")) 
	if check_uplink then
	    up = json.parse(check_uplink)
        if up ~= nil then
			if up.stat.value ~= nil then
				local uplink = up.stat.value 
			else
				local uplink = 0
			end
        else
			local uplink = 0
	    end	
	else
		local uplink = 0
	end	

    local down, check_downlink
	check_downlink = luci.sys.exec(string.format("xray api stats --server=127.0.0.1:8888 -name \"outbound>>>proxy_outbound>>>traffic>>>downlink\""))
	if check_downlink then
	    down = json.parse(check_downlink)
        if down ~= nil then
			if down.stat.value ~= nil then
				local downlink = down.stat.value
			else
				local downlink = 0 
			end
        else
			local downlink = 0
	    end	

	else
		local downlink = 0
	end

	luci.http.write_json({
		downlink = downlink,
		uplink = uplink
	})
end