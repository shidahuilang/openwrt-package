local sys  = require "luci.sys"
local http = require "luci.http"
local api = require "luci.coredns.api"

module("luci.controller.coredns", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/coredns") then
        return
    end

    local page = entry({"admin", "services", "coredns"}, alias("admin", "services", "coredns", "basic"), _("CoreDNS"), 30)
    page.dependent = true
    page.acl_depends = { "luci-app-coredns" }

    entry({"admin", "services", "coredns", "basic"}, cbi("coredns/basic"), _("Basic Setting"), 1).leaf = true
    entry({"admin", "services", "coredns", "status"}, call("coredns_status")).leaf = true
    entry({"admin", "services", "coredns", "rule_list"}, cbi("coredns/rule_list"), _("Redir Rule"), 2).leaf = true
    entry({"admin", "services", "coredns", "rule_url_config"}, cbi("coredns/rule_url_config")).leaf = true
    entry({"admin", "services", "coredns", "rule_file_config"}, cbi("coredns/rule_file_config")).leaf = true
    entry({"admin", "services", "coredns", "rule_file_content"}, cbi("coredns/rule_file_content",{hideapplybtn=true, hidesavebtn=true, hideresetbtn=true})).leaf = true
    entry({"admin", "services", "coredns", "auto_update"}, cbi("coredns/auto_update"), _("Auto Update"), 3).leaf = true
    entry({"admin", "services", "coredns", "rule_refresh"}, call("rule_refresh")).leaf = true
    entry({"admin", "services", "coredns", "coredns_upload"}, form("coredns/coredns_upload"), _("Core Update"), 4).leaf = true
    entry({"admin", "services", "coredns", "log"}, cbi("coredns/log"), _("Logs"), 5).leaf = true
    entry({"admin", "services", "coredns", "get_log"}, call("get_log")).leaf = true
    entry({"admin", "services", "coredns", "clear_log"}, call("clear_log")).leaf = true
end

function coredns_status()
    local e = {}
    e.running = sys.call("pgrep -f coredns >/dev/null") == 0
    http.prepare_content("application/json")
    http.write_json(e)
end

function get_log()
    -- http.write(sys.exec("cat $(/usr/share/coredns/coredns.sh logfile)"))
    -- http.write(sys.exec("cat /tmp/coredns.log"))
    http.write(sys.exec("cat $(uci -q get coredns.global.logfile)"))
end

function clear_log()
    -- sys.call("cat /dev/null > /tmp/coredns.log")
    sys.call("/usr/share/coredns/clear_log.sh")
end

function rule_refresh()
    local e = {}
    e.updating = sys.call("lua /usr/share/coredns/update_rule.lua > /dev/null") == 0
	-- luci.http.redirect(api.url("log"))
    http.prepare_content("application/json")
    http.write_json(e)
	luci.http.redirect(api.url("log"))
end

-- function flush_cache()
--     local e = {}
--     e.flushing = sys.call("/usr/share/coredns/clear_cache.sh >/dev/null") == 0
--     http.prepare_content("application/json")
--     http.write_json(e)
-- end
