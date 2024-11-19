module("luci.controller.openai", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/openai") then
		return
	end

	local page = entry({"admin", "services", "openai"}, alias("admin", "services", "openai", "basic"), _("ChatGPT"), 31)
	page.dependent = true
	page.acl_depends = { "luci-app-openai" }

	entry({"admin", "services", "openai", "basic"}, cbi("openai/basic"), _("Basic Setting"), 1).leaf = true
	entry({"admin", "services", "openai", "log"}, cbi("openai/log"), _("Logs"), 2).leaf = true
	entry({"admin", "services", "openai", "openai_status"}, call("openai_status")).leaf = true
	entry({"admin", "services", "openai", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "services", "openai", "clear_log"}, call("clear_log")).leaf = true
end

function openai_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("openai", "openai", "port"))

	local status = {
		running = (sys.call("pidof openai >/dev/null") == 0),
		port = (port or 5052)
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

function get_log()
	luci.http.write(luci.sys.exec("cat /var/openai.log"))
end

function clear_log()
	luci.sys.call("cat /dev/null > /var/openai.log")
end
