m = Map("autokick", translate("Wiwiz")) 

autokick = m:section(TypedSection, "autokick", "")

enabled = autokick:option(Flag, "enabled", "启用");
enabled.optional = false 
enabled.rmempty = false

gw_ip = autokick:option(Value, "gw_ip", "Portal认证设备地址");
gw_ip.optional = false
gw_ip.rmempty = false
gw_ip.default = "127.0.0.1"

desc = autokick:option(DummyValue, "desc", "说明", "本功能可实现Portal认证到期后自动断开无线用户");

return m
