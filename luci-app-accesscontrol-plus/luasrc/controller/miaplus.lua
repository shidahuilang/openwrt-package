module("luci.controller.miaplus",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/miaplus") then
		return
	end

	entry({"admin", "services", "miaplus"}, cbi("base"), _("Internet Access Schedule Control Plus"), 30).dependent = true
	entry({"admin", "services", "miaplus", "status"}, call("act_status")).leaf = true

	entry({"admin", "services", "miaplus", "base"}, cbi("base"), _("Base Setting"), 40).leaf = true
	entry({"admin", "services", "miaplus", "advanced"}, cbi("advanced"), _("Advance Setting"), 50).leaf = true
	entry({"admin", "services", "miaplus", "template"}, cbi("template"), nil).leaf = true
end

function act_status()
	local e = {}
	e.running = luci.sys.call("iptables -L INPUT |grep MIAPLUS >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
