m = Map("school")
m.title = translate("Campus network detection bypass")
m.description = translate("Bypass campus network device detection")

m:section(SimpleSection).template  = "school/school"

s = m:section(TypedSection, "school")
s.addremove = false
s.anonymous = true

IPID = s:option(Flag, "IPID", translate("iptables IPID 防检测"))
IPID.default = 0
IPID.description = translate("iptables IPID 防检测")
IPID.rmempty=false

IUA = s:option(Flag, "IUA", translate("修改 HTTP-Headr 防检测"))
IPID.default = 0
IUA.description = translate("修改 HTTP-Headr 防检测")
IUA.rmempty=false

INTP = s:option(Flag, "INTP", translate("修正 NTP 防检测"))
INTP.default = 0
IUA.description = translate("修正 NTP 防检测")
IUA.rmempty=false

ITTL = s:option(Flag, "ITTL", translate("iptables 修改 TTL 防检测"))
ITTL.default = 0
IUA.description = translate("iptables 修改 TTL 防检测")
IUA.rmempty=false

IACFlash = s:option(Flag, "IACFlash", translate("iptables 拒绝 AC 进行 Flash 检测"))
IACFlash.default = 0
IACFlash.description = translate("iptables 拒绝 AC 进行 Flash 检测")
IACFlash.rmempty=false

return m