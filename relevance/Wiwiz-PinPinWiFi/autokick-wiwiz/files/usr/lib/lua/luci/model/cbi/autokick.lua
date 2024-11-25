m = Map("autokick", translate("Wiwiz"), 
    translate("Enabling this feature will automatically disconnect the wireless client after portal authentication expires")) 

autokick = m:section(TypedSection, "autokick", "")

enabled = autokick:option(Flag, "enabled", translate("Enable"));
enabled.optional = false 
enabled.rmempty = false

gw_ip = autokick:option(Value, "gw_ip", translate("Portal Gateway Address"));
gw_ip.optional = false
gw_ip.rmempty = false
gw_ip.default = "127.0.0.1"

return m
