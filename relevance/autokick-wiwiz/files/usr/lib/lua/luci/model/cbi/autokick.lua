m = Map("autokick", translate("Wiwiz"), 
    translate("开启本功能后可使终端设备在Portal认证到期后自动断开无线连接")) 

autokick = m:section(TypedSection, "autokick", "")

enabled = autokick:option(Flag, "enabled", "启用");
enabled.optional = false 
enabled.rmempty = false

gw_ip = autokick:option(Value, "gw_ip", "Portal认证设备地址");
gw_ip.optional = false
gw_ip.rmempty = false
gw_ip.default = "127.0.0.1"

return m
