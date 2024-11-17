module("luci.controller.rclone", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/rclone") then return end
	entry({"admin", "nas"}, firstchild(), _("NAS") , 45).dependent = false
	local page = entry({"admin", "nas", "rclone"}, cbi("rclone"), _("Rclone"))
	page.order = 100
	page.dependent = false
	page.acl_depends = { "luci-app-rclone" }
end
