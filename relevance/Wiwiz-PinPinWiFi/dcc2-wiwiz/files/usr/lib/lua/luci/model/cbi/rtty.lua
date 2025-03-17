m = Map("rtty", translate("Wiwiz"),
translate("DCC2 Ver 1.2.4 <a href='http://www.wiwiz.com/pinpinwifi/wiwiz-ipk.htm' target='_blank'>Readme</a>")) 

rtty = m:section(TypedSection, "rtty", "")

enabled = rtty:option(Flag, "enabled", translate("Enable"));
enabled.optional = false 
enabled.rmempty = false

id = rtty:option(Value, "id", "设备ID", translate("mac address will be Device ID if empty"));
id.optional = true 
id.rmempty = false
id.addremove = false

token = rtty:option(Value, "token", translate("Token"));
token.optional = false 
token.rmempty = false

description = rtty:option(Value, "description", translate("Description")); 
description.optional = true 
description.rmempty = false
description.addremove = false

host = rtty:option(Value, "host", translate("Server Address")); 
host.optional = false 
host.rmempty = false

port = rtty:option(Value, "port", translate("Server Port")); 
port.optional = false 
port.rmempty = false
port.default = "5912"

return m
