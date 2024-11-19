module("luci.controller.nfs", package.seeall)

function index()
	entry({"admin", "nas"}, firstchild(), _("NAS") , 45).dependent = false
	if not nixio.fs.access("/etc/config/nfs") then
		return
	end
	local page = entry({"admin", "nas", "nfs"}, cbi("nfs"), _("NFS Manage"), 5)
	page.dependent = true
	page.acl_depends = { "luci-app-nfs" }
end
