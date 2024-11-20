local dsp = require "luci.dispatcher"
local http = require "luci.http"

local m, s, o

local function get_ip_string(ip)
	if ip and ip:find(":") then
		return "[%s]" % ip
	else
		return ip or ""
	end
end


m = Map("tinyfecvpn", "%s - %s" %{translate("tinyFecVPN"), translate("Servers Manage")})


s = m:section(TypedSection, "servers")
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = dsp.build_url("admin/services/tinyfecvpn/servers/%s")
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		m.uci:save("tinyfecvpn")
		http.redirect(s.extedit % sid)
		return
	end
end

o = s:option(DummyValue, "alias", translate("Alias"))
function o.cfgvalue(self, section)
	return Value.cfgvalue(self, section) or translate("None")
end


o = s:option(DummyValue, "_server_address", translate("Server Address"))
function o.cfgvalue(self, section)
	local server = m.uci:get("tinyfecvpn", section, "server_addr") or "?"
	local server_port = m.uci:get("tinyfecvpn", section, "server_port") or "29900"
	return "%s:%s" % { get_ip_string(server), server_port }
end

o = s:option(DummyValue, "fec", translate("Fec"))
function o.cfgvalue(self, section)
	return m.uci:get("tinyfecvpn", section, "fec") or "5:10"
end


o = s:option(DummyValue, "sub_net", translate("Sub Net"))
function o.cfgvalue(self, section)
	return m.uci:get("tinyfecvpn", section, "sub_net") or "10.22.22.0"
end

o = s:option(DummyValue, "tun_dev", translate("Tun Device"))
function o.cfgvalue(self, section)
	return m.uci:get("tinyfecvpn", section, "tun_dev") or "random"
end

return m
