module("luci.controller.linkease", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/linkease") then
		return
	end

	entry({"admin", "services", "linkease"}, cbi("linkease"), _("LinkEase"), 20).dependent = true

	entry({"admin", "services", "linkease_status"}, call("linkease_status"))

	entry({"admin", "services", "linkease", "file"}, call("linkease_file_template")).leaf = true

end

function linkease_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("linkease", "linkease", "port"))

	local status = {
		running = (sys.call("pidof linkease >/dev/null") == 0),
		port = (port or 8897)
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

function get_params(name)
    local data = {
        prefix=luci.dispatcher.build_url(unpack({"admin", "services", "linkease", name})),
    }
    return data
end

function linkease_file_template()
    luci.template.render("linkease/file", get_params("file"))
end
