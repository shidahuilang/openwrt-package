-- Copyright 2019 X-WRT <dev@x-wrt.com>
-- Copyright 2022-2024 sirpdboy

module("luci.controller.netwizard", package.seeall)
local http = require "luci.http"
local uci = require "luci.model.uci".cursor()

function index()
	if not nixio.fs.access("/etc/config/netwizard") then return end
    if not nixio.fs.access("/etc/config/netwizard_hide") then
        e = entry({"admin", "netwizard"}, cbi("netwizard/netwizard"), _("Netwizard"), 21)
	e.dependent = true
        e.acl_depends = { "luci-app-netwizard" }
        -- entry({"admin", "netwizard"}, call("action_netwizard"), _("Netwizard"), 21)
    end
end
function action_netwizard()
    -- 检查是否是表单提交
    if http.formvalue("cbi.apply") then
        local new_ip = http.formvalue("cbid.netwizard.lan.ipaddr") or uci:get("network", "lan", "ipaddr")
        if new_ip then
            uci:commit("network")
            uci:commit("netwizard")
            http.redirect("http://" .. new_ip .. "/cgi-bin/luci/admin/netwizard")
            return
        end
    end

    -- 使用显式加载的 cbi 模块
    local cbi_map = cbi.load("netwizard/netwizard")  -- 注意：这里用 cbi.load，不是 luci.cbi.load
    luci.template.render("cbi/simpleform", {map = cbi_map})
end