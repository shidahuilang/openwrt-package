module("luci.controller.gxu-webconnect", package.seeall)  --gxuwc要与文件名一致
function index()
	if not nixio.fs.access("/etc/config/gxu-webconnect") then
		return
	end
    entry({"admin", "services", "gxu-webconnect"},firstchild(), _("GXU网络认证"), 50).dependent = false
    entry({"admin", "services", "gxu-webconnect", "general"},cbi("gxu-webconnect"), _("设置"), 1)
    entry({"admin", "services", "gxu-webconnect", "status"},call("act_status")).leaf=true
end

function act_status()
	local e = {}
	e.running = luci.sys.call("ps | grep gxuwc | grep -v grep >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
