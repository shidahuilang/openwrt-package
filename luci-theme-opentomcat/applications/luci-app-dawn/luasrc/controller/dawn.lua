module("luci.controller.dawn", package.seeall)

function index()
    entry({ "admin", "network", "dawn" }, firstchild(), "DAWN", 60).dependent = false
    entry({ "admin", "network", "dawn", "configure_daemon" }, cbi("dawn/dawn_config"), "Configure DAWN", 1)
    entry({ "admin", "network", "dawn", "view_network" }, cbi("dawn/dawn_network"), "View Network Overview", 2)
    entry({ "admin", "network", "dawn", "view_hearing_map" }, cbi("dawn/dawn_hearing_map"), "View Hearing Map", 3)
end
