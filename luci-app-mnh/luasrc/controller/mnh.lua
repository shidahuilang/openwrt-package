module("luci.controller.mnh", package.seeall)

local util = require "luci.util"
local uci = require "luci.model.uci"

function index()
	entry({"admin", "services", "mnh"}, cbi("mnh/status"), _("mnh"))

	entry({"admin", "services", "mnh", "status"}, call("mnh_status"))
	entry({"admin", "services", "mnh", "instance"}, cbi("mnh/instance")).leaf = true
end

function mnh_status()
	local service = util.ubus("service", "list", {name = "mnh"})["mnh"] or {_=0}
	
	local ret = {}
	uci.cursor():foreach('mnh', 'instance', function(s)
		local name = s[".name"]

		ret[name] = {
			id = s["id"],
		}

		if not service["instances"] then
			ret[name]["status"] = "not running"
		elseif not service["instances"][name] then
			ret[name]["status"] = "not running"
		else
			local rundata = io.open("/var/run/mnh/" .. name)
			if not rundata then 
				ret[name]["status"] = "unknown error"
			else
				ret[name]["status"] = rundata:read("*line")
				ret[name]["error"] = rundata:read("*line")
				ret[name]["port"] = rundata:read("*line")
				ret[name]["addr"] = rundata:read("*line")
			end
		end
	end)

	luci.http.prepare_content("application/json")
	luci.http.write_json(ret)
end
