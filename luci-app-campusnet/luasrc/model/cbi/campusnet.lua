local fs = require "nixio.fs"

m = Map("campusnet")
m.title = translate("CampusNet")
m.description = translate("CampusNet is a network tool for auto-connecting the China Unicom Campus Network.")

m:section(SimpleSection).template = "campusnet/campusnet_status"

s = m:section(TypedSection, "campusnet")
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

o = s:option(Value, "user_phone", translate("Phone"))
o.datatype = "phonedigit"
o.optional = false
o.rmempty = false

o = s:option(Value, "passwd", translate("Password"))
o.password = true
o.optional = false
o.rmempty = false

o = s:option(ListValue, "school_id", translate("SchoolID"))
o.default = "510592"
o:value("510592", translate("University of Jinan"))
o:value("510281", translate("Shandong University of Finance and Economics (MingShui Campus)"))
o:value("740086", translate("Linyi University (Main Campus)"))
o:value("822837", translate("Linyi University (LinShui Campus)"))
o:value("1342980", translate("Qufu Normal University"))
o:value("817982", translate("Qingdao University (Fushan Campus)"))
o:value("712748", translate("Qingdao University (Jinjialing Campus)"))
o:value("1065671", translate("Rizhao University City"))
o.optional = false
o.rmempty = false

o = s:option(Value, "base_ip", translate("BaseIP"))
o.description = translate("basip in the authentication url.")
o.default = "124.128.40.39"
o.datatype = "ipaddr"
o.optional = false
o.rmempty = false

m:section(SimpleSection).template = "campusnet/campusnet_logs"

return m