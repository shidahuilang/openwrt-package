m = Map("wiwiz", translate("Wiwiz"),
    translate("Portal")) 

portal = m:section(TypedSection, "wiwiz", "")

enabled = portal:option(Flag, "enabled", translate("Enable"));
enabled.optional = false 
enabled.rmempty = false

hotspotid = portal:option(Value, "hotspotid", "Hotspot ID", translate("case sensitivity, no spaces"));
hotspotid.optional = false 
hotspotid.rmempty = false

--username = portal:option(Value, "username", "User Name", "Wiwiz平台用户请填写Wiwiz平台用户名；拼拼WiFi平台用户填写pinpinwifi"); 
--username.optional = false 
--username.rmempty = false

server = portal:option(Value, "server", translate("Server Address and Port")); 
server.optional = false 
server.rmempty = false
server.default = "cp.wiwiz.com:80"

lan = portal:option(Value, "lan", translate("Network interface")); 
lan.optional = false 
lan.rmempty = false
lan.addremove = false
lan.default = "br-lan"

ver = portal:option(DummyValue, "ver", translate("Plugin Version"), translate("<a href='http://www.wiwiz.com/pinpinwifi/wiwiz-ipk.htm' target='_blank'>Readme</a>"));

return m
