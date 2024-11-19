module("luci.controller.gpioled", package.seeall)
function index()
    entry({"admin", "system", "gpioled"},alias("admin", "system", "gpioled", "settings"),_("GPIO LED Configuration"), 60).dependent = true
    entry({"admin", "system", "gpioled", "settings"}, cbi("gpioled/settings"), _("Settings"), 1).leaf = true
    entry({"admin", "system", "gpioled", "logs"}, cbi("gpioled/logs"), _("Logs"), 2).leaf = true
    entry({"admin", "system", "gpioled", "id_status"}, call("id_status"))
    entry({"admin", "system", "gpioled", "ad_status"}, call("ad_status"))
    entry({"admin", "system", "gpioled", "ad_mon"}, call("ad_mon"))
    entry({"admin", "system", "gpioled", "pwr_status"}, call("pwr_status"))
    entry({"admin", "system", "gpioled", "get_log"}, call("get_log"))
end

function id_status()
    local e = {}
    e.running = luci.sys.call("pgrep -f /usr/share/gpioled/id >/dev/null") == 0
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function ad_status()
    local e = {}
    e.running = luci.sys.call("pgrep -f /usr/share/gpioled/ad >/dev/null") == 0
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function ad_mon()
    local e = {}
    local f = luci.sys.exec("uci get gpioled.service.ad_app")
    f = f:trim()
    local running = luci.sys.exec("uci get " .. f)
    e.running = running:trim()
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function pwr_status()
    local e = {}
    local running = luci.sys.exec("uci get gpioled.service.pwr_mode")
    e.running = running:trim()
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function get_log()
    local fs = require("nixio.fs")
    local lf = "/tmp/gpioled.log"
    local l = fs.readfile(lf) or "Log file not found."
    luci.http.prepare_content("text/plain")
    luci.http.write(l)
end
