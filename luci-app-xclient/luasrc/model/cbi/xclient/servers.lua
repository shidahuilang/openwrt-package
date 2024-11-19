require "luci.http"
require "luci.dispatcher"
require "luci.model.uci"
local m, s, o,c
local uci = luci.model.uci.cursor()

local server_count = 0
uci:foreach("xclient", "servers", function(s)
	server_count = server_count + 1
end)

font_blue = [[<b color="blue">]]
font_green = [[<b style=color:green>]]
font_red = [[<b style=color:red>]]
font_off = [[</b>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]


c = Map("xclient")

-- Server Subscribe
s = c:section(TypedSection, "xclient", "Account Settings")
s.anonymous = true


o = s:option(Value, "site")
o.title = "Website Url"
o.rmempty = false

o = s:option(Value, "email")
o.title = "Email"
o.rmempty = true

o = s:option(Value, "passwd")
o.title = "Password"
o.password = true
o.rmempty = true


if c.uci:get("xclient", "config", "token") then
	o = s:option(Value, "auto_update_servers")
	o.title = "Auto Update (h)"
	o.default=6
	o.rmempty = true
end

o = s:option(DummyValue, "login", "Status")
if not c.uci:get("xclient", "config", "token") then
o.template = "xclient/login"
else
o.template = "xclient/logout"
end


local t = {
    {Delete_Servers}
}

b = c:section(Table, t)


o = b:option(Button,"Delete_Servers")
o.inputtitle = "Delete All Servers"
o.inputstyle = "delete"
o.write = function()
	uci:delete_all("xclient", "servers", function(s)
		if s.hashkey or s.isSubscribe then
			return true
		else
			return false
		end
	end)
	uci:save("xclient")
	uci:commit("xclient")
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "xclient", "delete"))
	return
end


m = Map("xclient")
s = m:section(TypedSection, "servers", "Server List")
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"
s.sortable = false
s.extedit = luci.dispatcher.build_url("admin", "services", "xclient", "server", "%s")
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end

o = s:option(DummyValue, "type", "Type")
function o.cfgvalue(self, section)
	return m:get(section, "protocol") or Value.cfgvalue(self, section) or "N/A"
end

o = s:option(DummyValue, "alias", "Alias")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "N/A"
end

o = s:option(DummyValue, "server", "Server Address")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "N/A"
end

o = s:option(DummyValue, "server_port", "Server Port")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "N/A"
end


o = s:option(DummyValue, "transport", "Transport")
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "N/A"
end


o = s:option(DummyValue, "server" ,"Latency")
o.template="xclient/ping"
o.width="10%"

o = s:option(DummyValue, "server_port", "Socket Connected")
o.template = "xclient/socket"
o.width = "10%"
o.render = function(self, section, scope)
	self.transport = s:cfgvalue(section).transport
	if self.transport == 'ws' then
		self.ws_path = s:cfgvalue(section).ws_path
		self.tls = s:cfgvalue(section).tls
	end
	DummyValue.render(self, section, scope)
end

m:append(Template("xclient/server_list"))

local apply = luci.http.formvalue("cbi.apply")
if apply then
  c.uci:commit("xclient")
  m.uci:commit("xclient")
  luci.sys.call("/etc/init.d/xclient boot >/dev/null 2>&1 &")
end

return c, m
