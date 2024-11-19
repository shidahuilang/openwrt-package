local api = require "luci.model.cbi.sakurafrp.api"
local natfrpapi = require "luci.model.cbi.sakurafrp.natfrpapi"
local prog = api.prog

m = Map(prog, "")
s = m:section(NamedSection, "advanced", "", translate("Advanced Config"))
s.addremove = false
s.anonymous = true

manual_enable = api.uci_get_type_id("manual", "enable", 0)

if (tonumber(manual_enable) == 1) then
    disabled = s:option(DummyValue, "", translate("Disabled due to Manual Edit Enabled"))
    return m
end

enable = s:option(Flag, "enable", translate("Enable"))

api.read_frpc_config()

sakura_section = m:section(NamedSection, "advanced_sakura", "", translate("SakuraFrp Features"), translate("Refer to <a href='https://doc.natfrp.com/frpc/manual.html#advanced-switches'>Frpc Manual</a>"))
sakura_mode = sakura_section:option(Flag, "sakura_mode", translate("Enable"), "[sakura_mode] " .. translate("Enable SakuraFrp Features"))
use_recover = sakura_section:option(Flag, "use_recover", translate("Use Recover"), "[use_recover] " .. translate("Auto reconnect without shutdown"))
persist_runid = sakura_section:option(Flag, "persist_runid", translate("Generate RunID"), "[persist_runid] " .. translate("Generate unique RunID for fast reconnect"))
remote_control = sakura_section:option(Value, "remote_control", translate("Remote Control"), "[remote_control] " .. translate("Enable remote control. Left empty means disable. <br>(Note: Enabling this function can take up to 300M of RAM.)"))
dynamic_key = sakura_section:option(Flag, "dynamic_key", translate("Enable DKC"), "[dynamic_key] " .. translate("Enable DKC for encrypt data connections"))

sakura_mode:depends(enable)
sakura_enabled = {
    ["sakura_mode"] = 1,
    ["sakurafrp.advanced.enable"] = 1
}
use_recover:depends(sakura_enabled)
persist_runid:depends(sakura_enabled)
remote_control:depends(sakura_enabled)
dynamic_key:depends(sakura_enabled)


frpc_section = m:section(NamedSection, "advanced_frpc", "", translate("Frpc Features"))
frpc_section.addremove = false
frpc_section.anonymous = true

login_fail_exit = frpc_section:option(Flag, "login_fail_exit", translate("Exit once login fails"), "[login_fail_exit] " .. translate("Exit frpc once login fails"))
protocol = frpc_section:option(Value, "protocol", translate("Protocol used to communicate with server"), "[protocol] " .. translate("Protocol used to communicate with server<br>Note. Changing this could cause Sakura frpc failure"))
tcp_mux = frpc_section:option(Flag, "tcp_mux", translate("TCP multiplexing"), "[tcp_mux] " .. translate("TCP multiplexing"))
pool_count = frpc_section:option(Value, "pool_count", translate("Connection Pool"), "[pool_count] " .. translate("Connection Pool Count"))

login_fail_exit:depends(enable)
protocol:depends(enable)
tcp_mux:depends(enable)
pool_count:depends(enable)


custom_list = m:section(TypedSection, "advanced_config_custom", "", translate("Custom Configurations"))
custom_list.addremove = true
custom_list.anonymous = true

custom_list.template = "cbi/tblsection"
custom_key = custom_list:option(Value, "key", "Key")
custom_val = custom_list:option(Value, "value", "Value")


return m