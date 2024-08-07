module("luci.controller.uugamebooster", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/uugamebooster") then
		return
	end

	local page
	page = entry({"admin", "services", "uugamebooster"}, cbi("uugamebooster/uugamebooster"), ("UU GameAcc"), 99)
	page.dependent = false
	page.acl_depends = {"luci-app-uugamebooster"}

	entry({"admin","services","uugamebooster","status"}, call("act_status")).leaf = true
end

function act_status()
	local e = {}
	e.running = luci.sys.call("pgrep -f uugamebooster >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
