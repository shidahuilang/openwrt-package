require "luci.util"

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

dhcp_portal = portal:option(Flag, "dhcp_portal", translate("Enable DHCP Captive Portal Identification"));
dhcp_portal.optional = false 
dhcp_portal.rmempty = false

ver = portal:option(DummyValue, "ver", translate("Plugin Version"), translate("<a href='http://www.wiwiz.com/pinpinwifi/wiwiz-ipk.htm' target='_blank'>Readme</a>"));

m.on_after_commit = function(self)
    luci.util.exec("(sleep 3; /usr/local/hsbuilder/dhcp_portal.sh) &")
end

return m
