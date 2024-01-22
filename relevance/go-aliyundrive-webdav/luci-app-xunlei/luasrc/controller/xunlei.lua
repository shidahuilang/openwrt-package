
module("luci.controller.xunlei", package.seeall)

function index()
	entry({"admin", "nas"}, firstchild(), _("NAS") , 45).dependent = false
	if not nixio.fs.access("/etc/config/xunlei") then
		return
	end

	local page
	page = entry({"admin", "nas", "xunlei"}, cbi("xunlei"), _("迅雷远程下载"), 199)
	page.i18n = "xunlei"
	page.dependent = true
	page.acl_depends = { "luci-app-xunlei" }
end
