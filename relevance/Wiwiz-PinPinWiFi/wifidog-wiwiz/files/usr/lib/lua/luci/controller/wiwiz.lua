module("luci.controller.wiwiz", package.seeall)

function index()
	entry({"admin", "wiwiz_menu"}, firstchild(), "Wiwiz", 60).dependent=true
	entry({"admin", "wiwiz_menu", "wiwiz"}, cbi("wiwiz"), translate("Portal"), 51).dependent = true
end
