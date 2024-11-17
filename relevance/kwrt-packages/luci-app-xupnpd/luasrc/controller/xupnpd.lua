module("luci.controller.xupnpd",package.seeall)
function index()
if not nixio.fs.access("/etc/config/xupnpd")then
return
end
entry({"admin","services","xupnpd"},cbi("xupnpd"),_("XUPNP IPTV"),100).dependent=true
entry({"admin","services","xupnpd","status"},call("act_status")).leaf=true
end
function act_status()
local e={}
e.running=luci.sys.call("pgrep xupnpd >/dev/null")==0
luci.http.prepare_content("application/json")
luci.http.write_json(e)
end
