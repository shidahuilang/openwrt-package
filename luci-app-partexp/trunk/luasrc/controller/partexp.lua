--[[
LuCI - Lua Configuration Partition Expansion
 Copyright (C) 2022  sirpdboy <herboy2008@gmail.com> https://github.com/sirpdboy/luci-app-partexp
]]--
require "luci.util"
local name = 'partexp'

module("luci.controller.partexp", package.seeall)
function index()
	entry({"admin","system","partexp"},alias("admin", "system", "partexp", "global"),_("Partition Expansion"), 54)
--	entry({"admin", "system", "partexp", "global"}, form("partexp/global"), nil).leaf = true
	entry({"admin", "system", "partexp", "global"}, cbi('partexp/global', {hideapplybtn = true, hidesavebtn = true, hideresetbtn = true}), _('Partition Expansion'), 10).leaf = true 
	entry({"admin", "system", "partexp","partexprun"}, call("partexprun")).leaf = true
	entry({"admin", "system", "partexp", "realtime_log"}, call("get_log")) 
end

function get_log()
    local e = {}
    e.running = luci.sys.call("busybox ps -w | grep partexp | grep -v grep >/dev/null") == 0
    e.log = fs.readfile("/var/log/partexp.log") or ""
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function partexprun()
	local e
	local uci = luci.model.uci.cursor()
	local keep_config = luci.http.formvalue('keep_config')
	local auto_format = luci.http.formvalue('auto_format')
	local target_function = luci.http.formvalue('target_function')
	local target_disk = luci.http.formvalue('target_disk')
	--uci:delete(name, '@global[0]', global)
	uci:set(name, '@global[0]', 'target_disk', target_disk)
	uci:set(name, '@global[0]', 'target_function', target_function)
	uci:set(name, '@global[0]', 'auto_format', auto_format)
	uci:set(name, '@global[0]', 'keep_config', keep_config)
	uci:commit(name)
	e = luci.sys.exec('/etc/init.d/partexp autopart')
	if (e==2)then 
	  luci.sys.exec('reboot')
	end
	luci.http.prepare_content('application/json')
	luci.http.write_json(e)
end
