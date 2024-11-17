module("luci.controller.cns_server", package.seeall)
local http = require("luci.http")
local sys = require("luci.sys")
local cns = require("luci.model.cbi.cns_server/api/cns")

function index()
	entry({ "admin", "services", "cns_server", }, cbi("cns_server/index"), _("CNS Server"), 3).index = 1
	entry({ "admin", "services", "cns_server", "config" }, cbi("cns_server/user")).leaf = true
	entry({ "admin", "services", "cns_server", "users_status" }, call("users_status")).leaf = true
	entry({ "admin", "services", "cns_server", "get_log" }, call("get_log")).leaf = true
	entry({ "admin", "services", "cns_server", "clear_log" }, call("clear_log")).leaf = true
	entry({ "admin", "services", "cns_server", "check"}, call("cns_check")).leaf = true
	entry({ "admin", "services", "cns_server", "update"}, call("cns_update")).leaf = true
end

local function http_write_json(content)
	http.prepare_content("application/json")
	http.write_json(content or { code = 1 })
end

function get_log()
	http.write(sys.exec("[ -f '/var/log/cns_server/app.log' ] && cat /var/log/cns_server/app.log"))
end

function clear_log()
	sys.call("echo '' > /var/log/cns_server/app.log")
end

function users_status()
	local e = {}
	e.index = http.formvalue("index")
	e.status = sys.call("ps -w| grep -v grep | grep '/var/etc/cns_server/" .. http.formvalue("id") .. "' >/dev/null") ==
	0
	http_write_json(e)
end

function cns_check()
	local json = cns.to_check("")
	http_write_json(json)
end

function cns_update()
	local json = nil
	local task = http.formvalue("task")
	if task == "move" then
		json = cns.to_move(http.formvalue("file"))
	else
		json = cns.to_download(http.formvalue("url"))
	end

	http_write_json(json)
end

