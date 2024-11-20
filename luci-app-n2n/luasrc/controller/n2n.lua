-- N2N Luci configuration page. Made by 981213

module("luci.controller.n2n", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/n2n") then
		return
	end

	entry({"admin", "vpn"}, firstchild(), "VPN", 45).dependent = false

	local page = entry({"admin", "vpn", "n2n"}, cbi("n2n"), _("N2N VPN"), 45)
	page.dependent = true
	page.acl_depends = { "luci-app-n2n" }

	entry({"admin", "vpn", "n2n", "status"}, call("n2n_status")).leaf = true
end

function n2n_status()
	local status = {}
	status.running = luci.sys.call("pgrep n2n-edge >/dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
