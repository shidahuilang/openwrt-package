-- This is a free software, use it under GNU General Public License v3.0.
-- Created By ImmortalWrt
-- https://github.com/immortalwrt

module("luci.controller.gost", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/gost") then
		return
	end

	local page
	page = entry({"admin", "services", "gost"}, cbi("gost"), _("Gost"), 100)
	page.dependent = true
	entry({"admin", "services", "gost", "status"},call("act_status")).leaf=true
end

function act_status()
	local e={}
	e.running=luci.sys.call("pgrep gost >/dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
