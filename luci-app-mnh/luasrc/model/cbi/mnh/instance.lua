local dsp = require "luci.dispatcher"

local m = Map("mnh", translate("mnh - Instance"))
m.redirect = dsp.build_url("admin", "services", "mnh")

local name = arg[1]
if name == nil or m.uci:get("mnh", name) ~= "instance" then
	luci.http.redirect(m.redirect)
end

local s = m:section(NamedSection, name, translate("Instance"))
s.addremove = false

local id = s:option(Value, "id", translate("ID"))
id.rmempty = false
id.datatype = "string"
id.placeholder = "name"

local disabled = s:option(Button, "_disabled", translate("Enable/Disable"))
function disabled.cfgvalue(self, section, scope)
	local v = self.map:get(section, "disabled")
	if v == nil or v == 0 then
		self.inputtitle = translate("Enabled")
		self.inputstyle = "save"
		self._value = 0
	else
		self.inputtitle = translate("Disabled")
		self.inputstyle = "reset"
		self._value = 1
	end
	return true
end
function disabled.write(self, section, value)
	if self._value == 0 then
		self.map:set(section, "disabled", 1)
	else
		self.map:del(section, "disabled")
	end
end

local type = s:option(ListValue, "type", translate("Type"))
type.rmempty = false
type:value("tcp", translate("TCP"))
type:value("udp", translate("UDP"))

local port = s:option(Value, "port", translate("Port"))
port.rmempty = false
port.datatype = "port"
port.default = 0

protocol = s:option(ListValue, "protocol", translate("Protocol"))
protocol.rmempty = false
protocol:value("mnh", "mnh")
protocol.default = "mnh"

local server = s:option(Value, "server", translate("Server"))
server.rmempty = false
server.datatype = "or(host, hostport)"
server.placeholder = "server.com"

local mode = s:option(ListValue, "mode", translate("Mode"))
mode.rmempty = false
mode:value("proxy", translate("Proxy"))
mode:value("demoWeb", translate("Demo Web"))
mode.default = "proxy"

local service = s:option(Value, "service", translate("Service"))
service:depends("mode", "proxy")
service.rmempty = false
service.datatype = 'hostport'
service.placeholder = "127.0.0.1:80"
function service.parse(self, section, novld)
	if mode:formvalue(section) ~= "proxy" then
		self:remove(section)
		return
	end

	AbstractValue.parse(self, section, novld)
end

return m
