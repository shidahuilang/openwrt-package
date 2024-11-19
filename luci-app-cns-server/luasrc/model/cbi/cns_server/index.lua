local ds = require "luci.dispatcher"
local http = require("luci.http")
local sys = require("luci.sys")

local m = Map('cns_server')
m.title = translate("CNS Server")

t = m:section(TypedSection, "global", translate("Global Settings"))
t.anonymous = true
t.addremove = false

e = t:option(Flag, "enable", translate("Enable"))
e.rmempty = false
t:append(Template("cns_server/cns"))

t = m:section(TypedSection, "user", translate("Users Manager"))
t.anonymous = true
t.addremove = true
t.template = "cbi/tblsection"
t.extedit = ds.build_url("admin", "services", "cns_server", "config", "%s")

function t.create(t, e)
    local uuid = luci.sys.exec("echo -n $(cat /proc/sys/kernel/random/uuid)") or ""
    uuid = string.gsub(uuid, "-", "")
    local e = TypedSection.create(t, uuid)
    http.redirect(ds.build_url("admin", "services", "cns_server", "config", uuid))
end
function t.remove(t, a)
    t.map.proceed = true
    t.map:del(a)
    http.redirect(ds.build_url("admin", "services", "cns_server"))
end

e = t:option(Flag, "enable", translate("Enable"))
e.width = "5%"
e.rmempty = false

e = t:option(DummyValue, "status", translate("Status"))
e.rawhtml = true
e.width = "10%"
e.cfgvalue = function(t, n)
    return string.format('<font class="users_status" hint="%s">%s</font>', n, translate("Collecting data..."))
end
-- 每秒检查状态
m:append(Template("cns_server/users_list_status"))


e = t:option(DummyValue, "remarks", translate("Remarks"))

e = t:option(DummyValue, "port", translate('Port'))
e.width = "10%"
e.value = function(self, section)
    local str = ""
    local ports = m:get(section,"port")
    if not ports or ports == "" then return str end;
    return table.concat(ports, "|")
end
-- ProxyHost
e = t:option(DummyValue, 'proxy_key',translate('Proxy Key'))
e.width = "10%"

-- password
e = t:option(DummyValue, 'encrypt_password', translate("Password"))
e.width = "10%"

-- Tls
e = t:option(DummyValue, "tls", "Tls")
e.width = "10%"
e.rawhtml = true
e.cfgvalue = function(self, section)
    local str = string.format("X")
    local tls = m:get(section, "tls")
    if tls == "1" then str = string.format("✓") end
    return str;
end

m:append(Template("cns_server/log"))

-- 保存动作
m.on_after_commit = function (self)
    if self.changed then
        -- 执行配置文件的生成
        sys.exec("/etc/init.d/cns_server restart")
    end
end


return m