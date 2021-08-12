local fs = require "luci.fs"
local http = require "luci.http"
local DISP = require "luci.dispatcher"
local b

--SimpleForm for Info
b = SimpleForm("amlogic", translate("Amlogic Service"), nil)
b.description = translate("Supports related operations on Amlogic series boxes through the panel.")
b.reset = false
b.submit = false
b:section(SimpleSection).template  = "amlogic/other_info"


return b

