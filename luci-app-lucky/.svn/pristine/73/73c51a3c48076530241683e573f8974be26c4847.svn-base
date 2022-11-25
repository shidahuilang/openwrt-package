-- Copyright (C) 2021-2022  sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/luci-app-lucky 
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.lucky", package.seeall)

function index()

	entry({"admin",  "services", "lucky"}, alias("admin", "services", "lucky", "setting"),_("Lucky"), 57).dependent = true
	entry({"admin", "services", "lucky", "setting"}, cbi("lucky"), _("Base Setting"), 20).leaf=true
	entry({"admin",  "services", "lucky", "lucky"}, template("lucky"), _("Lucky"), 30).leaf = true
	entry({"admin", "services", "lucky_status"}, call("act_status"))
end

function act_status()
	local uci = require 'luci.model.uci'.cursor()
	local e = { }
	e.running = luci.sys.call("pidof lucky >/dev/null") == 0
	e.port = uci:get_first("lucky", "lucky", "port")
	e.safeurl = luci.sys.exec("cat /etc/lucky/lucky.conf | grep SafeURL |  sed 's/\"//g' | sed 's/: /\\n/g'|sed '1d' ")
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
