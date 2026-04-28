module("luci.controller.weburl", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/luci-app-control-weburl") then
		return
	end

	entry({"admin", "control"}, firstchild(), "Control", 44).dependent = false
	entry({"admin", "control", "weburl"}, cbi("weburl"), _("URL Filter"), 12).dependent = true
	entry({"admin", "control", "weburl", "status"}, call("status")).leaf = true
end

function status()
	local e = {}
	e.status = luci.sys.call("iptables -w -L FORWARD | grep WEBURL >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
