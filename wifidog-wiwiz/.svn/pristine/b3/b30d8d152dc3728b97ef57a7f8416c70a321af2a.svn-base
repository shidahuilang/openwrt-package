m = Map("wiwiz", translate("Wiwiz")) 

portal = m:section(TypedSection, "wiwiz", "")

enabled = portal:option(Flag, "enabled", "Enabled");
enabled.optional = false 
enabled.rmempty = false

hotspotid = portal:option(Value, "hotspotid", "Hotspot ID"); 
hotspotid.optional = false 
hotspotid.rmempty = false

username = portal:option(Value, "username", "User Name"); 
username.optional = false 
username.rmempty = false

server = portal:option(Value, "server", "Server"); 
server.optional = false 
server.rmempty = false
server.default = "cp.wiwiz.com:80"


return m