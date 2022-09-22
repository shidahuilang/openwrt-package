module("luci.controller.aliddns", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/aliddns") then
		return
	end

	entry({"admin", "services", "aliddns"}, cbi("aliddns"), _("AliDDNS"), 58).dependent = true
end
