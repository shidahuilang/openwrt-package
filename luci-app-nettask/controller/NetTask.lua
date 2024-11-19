module("luci.controller.NetTask", package.seeall)

function index()
	entry({"admin", "system", "NetTask"}, cbi("nettask"), _("网页自动认证"), 10).leaf = true
end
