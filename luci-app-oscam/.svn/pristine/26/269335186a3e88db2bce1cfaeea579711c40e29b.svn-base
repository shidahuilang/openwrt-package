-- Copyright (C) 2018-2022 dz <dingzhong110@gmail.com>

local sys = require("luci.sys")
local util = require("luci.util")
local fs = require("nixio.fs")
local uci = require "luci.model.uci".cursor()

local cport = uci:get_first("oscam", "oscam", "port") or 8888
local button = ""

local running=(luci.sys.call("pidof oscam > /dev/null") == 0)

if running then
        state_msg = "<b><font color=\"green\">" .. translate("Running") .. "</font></b>"
else
        state_msg = "<b><font color=\"red\">" .. translate("Not Running") .. "</font></b>"
end

if running  then
	button = "<br/><br/>---<input class=\"cbi-button cbi-button-apply\" type=\"submit\" value=\" "..translate("打开管理界面").." \" onclick=\"window.open('http://'+window.location.hostname+':"..cport.."')\"/>---"
end

m = Map("oscam", translate("oscam"))
m.description = translate("<font color=\"green\">oscam</font><br/><br/>" .. translate("运行状态").. " : "  .. state_msg .. "".. button  .. "<br />")

-- Basic
s = m:section(TypedSection, "oscam", translate("Settings"), translate("General Settings"))
s.anonymous = true

---- Eanble
enable = s:option(Flag, "enabled", translate("Enable"), translate("Enable or disable oscam server"))
enable.default = 0
enable.rmempty = false

---- port
port = s:option(Value, "port", translate("port"), translate("http server port"))
port.datatype = "port"
port.placeholder = "8888"
port.rmempty = true

---- user
user = s:option(Value, "user", translate("user"), translate("http server user"))
user.default = "oscam"
user.rmempty = true

---- password
pwd = s:option(Value, "pwd", translate("password"), translate("http server password"))
pwd.default = "oscam"
pwd.rmempty = true

---- pcscd
if nixio.fs.access("/usr/sbin/pcscd") then
pcscd = s:option(Flag, "pcscd", translate("pcscd"), translate("Enable or disable pcscd"))
pcscd.default = 0
pcscd.rmempty = false
end

return m
