module("luci.controller.webrestriction", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/luci-app-control-webrestriction") then
		return
	end

	entry({"admin", "control"}, firstchild(), "Control", 44).dependent = false
	entry({"admin", "control", "webrestriction"}, cbi("webrestriction"), _("Access Control"), 11).dependent = true
	entry({"admin", "control", "webrestriction", "status"}, call("status")).leaf = true
end

function status()
	local e = {}
	e.status = luci.sys.call("iptables -w -L FORWARD | grep WEB_RESTRICTION >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
