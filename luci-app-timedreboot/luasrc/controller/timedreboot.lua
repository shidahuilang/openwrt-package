module("luci.controller.timedreboot",package.seeall)
function index()
entry({"admin","system","timedreboot"},cbi("timedreboot"),_("Timed Reboot"),88)
end
