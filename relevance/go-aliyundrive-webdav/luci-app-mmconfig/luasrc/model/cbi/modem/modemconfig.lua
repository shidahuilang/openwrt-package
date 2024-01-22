-- Copyright 2021 Konstantine Shevlakov <shevlakov@132lan.ru>
-- Licensed to the public under the General Public License 3.0.

require("nixio.fs")
local uci = require "luci.model.uci"

local m
local s
local mode2g = os.execute("/usr/share/modeminfo/scripts/getmode.sh 2g")
local mode3g = os.execute("/usr/share/modeminfo/scripts/getmode.sh 3g")
local mode4g = os.execute("/usr/share/modeminfo/scripts/getmode.sh 4g")
local slot = uci.cursor():get_first("modemconfig", "modem", "device")

if slot == nil then
        slot = 0
end


local b2g = {}

local t = io.popen("mmcli -J -m "..slot.." | jsonfilter -e '@[\"modem\"][\"generic\"][\"supported-bands\"][*]' | grep -v utran", "r")

for bands in t:lines() do
        table.insert(b2g, b2)
        b2g[#b2g + 1] = bands
end


local b3g = {}

local f = io.popen("mmcli -J -m "..slot.." | jsonfilter -e '@[\"modem\"][\"generic\"][\"supported-bands\"][*]'|awk '/^utran/{print $1}'", "r")

for bands in f:lines() do
        table.insert(b3g, b3)
        b3g[#b3g + 1] = bands
end


local b4g = {}

local p = io.popen("mmcli -J -m "..slot.." | jsonfilter -e '@[\"modem\"][\"generic\"][\"supported-bands\"][*]'|awk '/^eutran/{print $1}'", "r")

for bands in p:lines() do
        table.insert(b4g, b4)
        b4g[#b4g + 1] = bands
end


local mm = {}
local t = io.popen("mmcli -J -L | jsonfilter -e '@[\"modem-list\"][*]'", "r")


m = Map("modemconfig", translate("Configure modem bands"),
	translate("Configuration 2G/3G/4G modem frequency bands."))

s = m:section(TypedSection, "modem", "<p>&nbsp;</p>" .. translate("Choose bands cellular modem"))
s.anonymous = true

dev = s:option(ListValue, "device", translate("Modem"), translate("Select modem"))
if mm ~= nil then
	for dev in t:lines() do
		table.insert(mm, m)
		mm[#mm + 1] = dev
	end
	for b,g in ipairs(mm) do
		mm[b] = g
		if type(g) ~= "table" then
			n = io.popen("mmcli -J -m "..g.." | jsonfilter -e '@[\"modem\"].*[\"model\"]'", "r")
			local model = n:read("*l")
			n:close()
			x = io.popen("mmcli -J -m "..g.." | jsonfilter -e '@[\"modem\"].*[\"device\"]'", "r")
			local bus = x:read("*l")
			x:close()
			dev:value(bus,model)
		end
	end
end

--s = m:section(TypedSection, "modem", "<p>&nbsp;</p>" .. translate("Choose bands cellular modem"))
--s.anonymous = true

-- disable if broken

netmode = s:option(ListValue, "mode", translate("Net Mode"),
translate("Preffered Network mode select."))
if mode4g == 0 then
	netmode:value("4g", "4G only")
end
if mode4g == 0 and mode3g == 0 then
	netmode:value("p4g3g", "4G/3G: preffer 4G")
	netmode:value("4gp3g", "4G/3G: preffer 3G")
end
if mode2g == 0 and mode3g == 0 and mode4g == 0 then
	netmode:value("p4g3g2g", "4G/3G/2G: preffer 4G")
	netmode:value("4gp3g2g", "4G/3G/2G: preffer 3G")
	netmode:value("4g3gp2g", "4G/3G/2G: preffer 2G")
end
if mode3g == 0 then
	netmode:value("3g", "3G only")
end
if mode3g == 0 and mode2g == 0 then
	netmode:value("p3g2g", "3G/2G: preffer 3G")
	netmode:value("3gp2g", "3G/2G: preffer 2G")
end
if mode2g == 0 then
	netmode:value("2g", "2G only")
end
netmode.default = "p4g3g"


if mode2g == 0 then
	gsm = s:option(DynamicList, "gsm_band", translate("2G"))
	if b2g ~= nil then
		for b,g in ipairs(b2g) do
			b2g[b] = g
			gsm:value(g,g)
		end
	end
	gsm.rmempty = true
end

if mode3g == 0 then
	wcdma = s:option(DynamicList, "3g_band", translate("3G"))
	if b3g ~= nil then
		for b,g in ipairs(b3g) do
			b3g[b] = g
			wcdma:value(g,g)
		end
	end
	s.rmempty = true
end

if mode4g == 0 then
	lte = s:option(DynamicList, "lte_band", translate("4G"), translate("Maybe must reconnect cellular interface. <br /> If deselect all bands, then used default band modem config."))
	if b4g ~= nil then
		for b,g in ipairs(b4g) do
			b4g[b] = g
			lte:value(g,g)
		end
	end
	s.rmempty = true
end

function m.on_after_commit(Map)
	luci.sys.call("/usr/bin/modemconfig")
end
s.addremove = true
s.anonymous = true
s.rmempty = true
return m
