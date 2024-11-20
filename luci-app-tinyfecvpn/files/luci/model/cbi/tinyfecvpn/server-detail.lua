local dsp = require "luci.dispatcher"
local m, s, o

local sid = arg[1]


local log_level = {
   "never",
   "fatal",
   "error",
   "warn",
   "info",
   "debug",
   "trace",
}
m = Map("tinyfecvpn", "%s - %s" % { translate("tinyFecVPN"), translate("Edit Server") })
m.redirect = dsp.build_url("admin/services/tinyfecvpn/servers")

if m.uci:get("tinyfecvpn", sid) ~= "servers" then
	luci.http.redirect(m.redirect)
	return
end

s = m:section(NamedSection, sid, "servers")
s.anonymous = true
s.addremove = false
s:tab("general", translate("General"), translate("General Options"))
s:tab("advanced",translate("Advanced"), translate("Advanced Options"))
s:tab("developer",translate("Developer"), translate("Developer Options"))

o = s:taboption("general", Value, "alias", translate("Alias(optional)"))

o = s:taboption("general", Value, "server_addr", translate("Server"))
o.datatype = "host"
o.rmempty = false

o = s:taboption("general", Value, "server_port", translate("Server Port"))
o.datatype = "port"
o.placeholder = "8080"
o.rmempty = false

o = s:taboption("general", Value, "sub_net", translate("Sub Net"))
o.datatype = "host"
o.placeholder = "10.22.22.0"


o = s:taboption("general", Value, "key", translate("Password"))
o.password = true

o = s:taboption("general", Value, "tun_dev", translate("Tun Device"), translate("Sepcify tun device name, for example: tun10, default: a random name such as tun987"))
o.datatype = "host"
o.placeholder = "random"



o = s:taboption("general", Value, "fec", translate("Fec"), translate("Forward error correction, send y redundant packets for every x packets.advance use:5:3,10:5"))
o.default = "10:5"


o = s:taboption("general", Value, "report", translate("Report"),translate("Turn on send/recv report, and set a period for reporting, unit: s"))
o.datatype = "uinteger"

o = s:taboption("general", Value, "timeout", translate("Timeout"),translate("How long could a packet be held in queue before doing fec, unit: ms"))
o.datatype = "uinteger"
o.placeholder = "8"

o = s:taboption("advanced", Value, "mode", translate("Mode"),translate("Fec-mode,available values: 0,1; mode 0(default) costs less bandwidth,no mtu problem.mode 1 usually introduces less latency, but you have to care about mtu."))
o.datatype = "range(0,1)"
o.placeholder = 0

o = s:taboption("advanced", Value, "mtu", translate("MTU"), translate("MTU for fec. for mode 0, the program will split packet to segment smaller than mtu.for mode 1, no packet will be split, the program just check if the mtu is exceed."))
o:depends("mode", "1")
o.datatype = "uinteger"
o.placeholder = 1250

o = s:taboption("developer", Value, "sock_buf", translate("Sock Buf"), translate("Buf size for socket, >=10 and <=10240, unit: kbyte, default: 1024"))
o.datatype = "range(10,10240)"
o.placeholder = "1024"

o = s:taboption("developer", Flag, "disable_fec", translate("Disable Fec"), translate("Completely disable fec, turn the program into a normal udp tunnel"))


o = s:taboption("general", ListValue, "log_level", translate("Log Level"))
for k, v in ipairs(log_level) do o:value(k-1, "%s:%s" %{k-1, v:lower()}) end
o.default = "4"


return m
