module("luci.controller.campusnet", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/campusnet") then
        return
    end
    
    entry({"admin", "services", "campusnet"}, cbi("campusnet"), _("CampusNet"), 100).dependent = true
    entry({"admin", "services", "campusnet", "status"}, call("act_status"), nil).leaf = true
    entry({"admin", "services", "campusnet", "fetch_log"}, call("fetch_log"), nil).leaf = true
end

function act_status()
	local e = {}
	e.running = luci.sys.call("pidof campusnet > /dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function fetch_log()
    local fs = require "nixio.fs"
    local content = fs.readfile("/var/campusnet/campusnet.log") or ""
    luci.http.write(content)
end
