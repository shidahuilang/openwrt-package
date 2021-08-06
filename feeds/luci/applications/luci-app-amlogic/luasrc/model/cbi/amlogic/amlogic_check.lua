local fs = require "luci.fs"
local http = require "luci.http"
local DISP = require "luci.dispatcher"
local b

--SimpleForm for Check
b = SimpleForm("amlogic", translate("Check Update"), nil)
b.description = translate("Provide OpenWrt Firmware, Kernel and Plugin online check, download and update service.")
b.reset = false
b.submit = false
b:section(SimpleSection).template  = "amlogic/other_check"


return b

