module("luci.controller.autokick", package.seeall)

function index()
	entry({"admin", "wiwiz_menu"}, firstchild(), "Wiwiz", 60).dependent=true
	entry({"admin", "wiwiz_menu", "autokick"}, cbi("autokick"), "自动断开无线终端", 52).dependent = true
end
