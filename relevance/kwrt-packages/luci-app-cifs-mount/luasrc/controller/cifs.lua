module("luci.controller.cifs", package.seeall)

function index()
	entry({"admin", "nas"}, firstchild(), _("NAS") , 45).dependent = false
	if not nixio.fs.access("/etc/config/cifs") then
		return
	end

	local page = entry({"admin", "nas", "cifs"}, cbi("cifs"), _("Mount SMB NetShare"))
	page.dependent = true
	page.acl_depends = { "luci-app-cifs-mount" }
end
